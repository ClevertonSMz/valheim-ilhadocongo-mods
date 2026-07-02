@echo off
title IlhaDoCongo - Instalador de Mods
setlocal enabledelayedexpansion
chcp 65001 >nul

echo ===============================================
echo            ILHA DO CONGO - MODPACK
echo      Instalador automatico de mods para Valheim
echo ===============================================
echo.

REM ===== DETECTAR VALHEIM =====
set VALHEIM_PATH=

REM Tenta ler registro do Steam
for /f "skip=2 tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970" /v "InstallLocation" 2^>nul') do (
    set VALHEIM_PATH=%%b
)
if not defined VALHEIM_PATH (
    for /f "skip=2 tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970" /v "InstallLocation" 2^>nul') do (
        set VALHEIM_PATH=%%b
    )
)

REM Tenta caminhos comuns
if not defined VALHEIM_PATH (
    if exist "C:\Program Files (x86)\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=C:\Program Files (x86)\Steam\steamapps\common\Valheim
    if exist "C:\Program Files\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=C:\Program Files\Steam\steamapps\common\Valheim
    if exist "D:\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=D:\Steam\steamapps\common\Valheim
    if exist "E:\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=E:\Steam\steamapps\common\Valheim
)

REM Se nao achou, pergunta
if not defined VALHEIM_PATH (
    echo [AVISO] Nao foi possivel encontrar automaticamente o Valheim.
    echo.
    set /p VALHEIM_PATH="Digite o caminho do Valheim (ex: D:\Steam\steamapps\common\Valheim): "
    if "!VALHEIM_PATH!"=="" (
        echo [ERRO] Caminho nao informado. Encerrando.
        pause
        exit /b 1
    )
)

if not exist "!VALHEIM_PATH!\valheim.exe" (
    echo [ERRO] Valheim nao encontrado em: !VALHEIM_PATH!
    pause
    exit /b 1
)

echo [OK] Valheim encontrado em: !VALHEIM_PATH!
echo.

REM ===== PASTA DE MODS =====
set MODS_DIR=%~dp0mods

if not exist "!MODS_DIR!" (
    echo [ERRO] Pasta mods/ nao encontrada junto ao instalador!
    echo Certifique-se de extrair TODO o pacote antes de executar.
    pause
    exit /b 1
)

echo [INFO] Instalando mods de: !MODS_DIR!
echo.

REM Criar pastas BepInEx se necessario
if not exist "!VALHEIM_PATH!\BepInEx" mkdir "!VALHEIM_PATH!\BepInEx"
if not exist "!VALHEIM_PATH!\BepInEx\plugins" mkdir "!VALHEIM_PATH!\BepInEx\plugins"
if not exist "!VALHEIM_PATH!\BepInEx\config" mkdir "!VALHEIM_PATH!\BepInEx\config"

REM Copiar DLLs para plugins
echo [MODS] Copiando plugins...
set COUNT=0
for /r "!MODS_DIR!" %%f in (*.dll) do (
    copy /Y "%%f" "!VALHEIM_PATH!\BepInEx\plugins\" >nul
    echo    + %%~nxf
    set /a COUNT+=1
)

REM Copiar configs se houver
if exist "!MODS_DIR!\config" (
    echo [CONFIG] Copiando arquivos de configuracao...
    xcopy /E /Y "!MODS_DIR!\config\*" "!VALHEIM_PATH!\BepInEx\config\" >nul
)

echo.
echo [OK] !COUNT! mod(s) instalado(s) com sucesso!

echo.
echo ===============================================
echo              INSTALACAO CONCLUIDA!
echo ===============================================
echo.
echo Modos instalados em:
echo   !VALHEIM_PATH!\BepInEx\plugins\
echo.
echo Para conectar no servidor IlhaDoCongo:
echo   1. Abra o Valheim  (com BepInEx carregando os mods)
echo   2. Vai em "Join Game" ^> "Join IP"
echo   3. Ip: 187.77.49.71:2456
echo   4. Senha: 202122
echo.
echo [DICA] Para remover os mods, delete a pasta BepInEx/
echo.
pause
