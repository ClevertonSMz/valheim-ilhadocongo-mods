#!/usr/bin/env python3
"""
build.py - Gera o pacote de mods IlhaDoCongo para Windows.
Execute na maquina que tem os mods baixados, ou use --download.

Uso:
  python build.py                    # Gera o zip com mods locais
  python build.py --download         # Baixa mods do Thunderstore antes
  python build.py --output ./meupac  # Define nome do zip
"""

import os, sys, json, hashlib, zipfile, tempfile, urllib.request
from pathlib import Path

MODS_JSON_URL = "https://raw.githubusercontent.com/ClevertonSMz/valheim-ilhadocongo-mods/main/mods.json"
DEFAULT_OUTPUT = "IlhaDoCongo-Modpack"

def download_mod(url, dest):
    """Download de um arquivo zip e extrai DLL."""
    print(f"  Baixando: {url}")
    try:
        with urllib.request.urlopen(url) as r:
            data = r.read()
    except Exception as e:
        print(f"  [ERRO] Falha no download: {e}")
        return None

    with tempfile.TemporaryDirectory() as tmp:
        tmppath = os.path.join(tmp, "mod.zip")
        with open(tmppath, "wb") as f:
            f.write(data)

        with zipfile.ZipFile(tmppath) as z:
            dlls = [n for n in z.namelist() if n.endswith(".dll")]
            for dll in dlls:
                z.extract(dll, tmp)
                src = os.path.join(tmp, dll)
                dst = os.path.join(dest, os.path.basename(dll))
                with open(src, "rb") as sf, open(dst, "wb") as df:
                    df.write(sf.read())
                print(f"    DLL extraida: {os.path.basename(dll)}")

def get_mods_manifest():
    """Carrega lista de mods do mods.json (local ou remoto)."""
    local = Path(__file__).parent / "mods.json"
    if local.exists():
        with open(local) as f:
            return json.load(f)
    print("Baixando mods.json...")
    try:
        with urllib.request.urlopen(MODS_JSON_URL) as r:
            return json.loads(r.read())
    except:
        print("[ERRO] Nao foi possivel carregar mods.json")
        sys.exit(1)

def main():
    download = "--download" in sys.argv

    out_arg = None
    for a in sys.argv:
        if a.startswith("--output="):
            out_arg = a.split("=", 1)[1]

    output_name = out_arg or DEFAULT_OUTPUT
    script_dir = Path(__file__).parent

    print("=== IlhaDoCongo - Gerador de Modpack ===")
    print()

    manifest = get_mods_manifest()
    print(f"Servidor: {manifest.get('server', 'N/A')}")
    print(f"Versao:   {manifest.get('version', 'N/A')}")
    print()

    # Diretorio temporario para montar o pacote
    build_dir = Path(tempfile.mkdtemp(prefix="modpack_"))
    mods_dest = build_dir / "mods"

    # Copiar o instalador
    installer_src = script_dir / "client" / "install_mods.bat"
    if installer_src.exists():
        import shutil
        shutil.copy2(installer_src, build_dir / "install_mods.bat")
        print(f"[OK] Instalador copiado")

    # Processar cada mod
    print("Processando mods...")
    for mod in manifest.get("mods", []):
        print(f"  [{mod.get('id', '?')}]")
        url = mod.get("download_url", "")
        if url:
            download_mod(url, str(mods_dest))
        else:
            print(f"    Sem URL de download, ignorando")

    print()
    print("Gerando ZIP...")
    zip_path = script_dir / f"{output_name}.zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(build_dir):
            for f in files:
                fp = os.path.join(root, f)
                arcname = os.path.relpath(fp, build_dir)
                zf.write(fp, arcname)

    # hash
    sha = hashlib.sha256()
    with open(zip_path, "rb") as f:
        sha.update(f.read())

    import shutil
    shutil.rmtree(build_dir)

    print(f"[OK] Pacote gerado: {zip_path}")
    print(f"    Tamanho: {os.path.getsize(zip_path) / 1024:.1f} KB")
    print(f"    SHA256: {sha.hexdigest()}")

if __name__ == "__main__":
    main()
