# IlhaDoCongo - Modpack de Valheim

Pacote de mods para jogar no servidor **IlhaDoCongo**.

## Instalação

1. **Baixe** o arquivo `IlhaDoCongo-Modpack.zip` da seção [Releases](https://github.com/SEU_USUARIO/valheim-ilhadocongo-mods/releases)
2. **Extraia** tudo em uma pasta qualquer (não precisa ser dentro do Valheim)
3. **Execute** `install_mods.bat` como Administrador
4. O instalador vai:
   - Encontrar automaticamente a pasta do Valheim
   - Copiar os mods para `BepInEx/plugins/`
5. Abra o **Valheim** normalmente
6. Vá em **Join Game > Join IP**
7. Digite: `187.77.49.71:2456` — Senha: `202122`

## Mods incluídos

| Mod | Versao | Obrigatorio |
|---|---|---|
| ServerSideCharacters (SSC) | 0.7.1 | Sim |

**ServerSideCharacters:** Personagens salvos no servidor. Não dá pra trazer
itens de outros mundos. O servidor cria um boneco novo pra cada jogador.

## Atualizando

Basta baixar a nova versão do pacote e executar o instalador de novo.
Ele sobrescreve os mods antigos.

## Desinstalar

Delete a pasta `BepInEx/` dentro da pasta do Valheim.

## Servidor

- IP: `187.77.49.71:2456`
- Senha: `202122`
- Seed: `KitchenSnk`

---

### Para desenvolvedores

Para gerar o pacote manualmente:

```bash
python build.py            # usa mods locais
python build.py --download # baixa do Thunderstore
```

O arquivo `mods.json` contem a lista de mods (versao, URL, dependencias).
Para adicionar um mod novo, edite o `mods.json` e execute `build.py`.