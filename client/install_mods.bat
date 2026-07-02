@echo off
title IlhaDoCongo - Instalador de Mods
setlocal enabledelayedexpansion
chcp 65001 >nul

set LOGFILE=%TEMP%\ilhadocongo_install.log
echo. > "%LOGFILE%"
echo LOG: Inicio em %DATE% %TIME% >> "%LOGFILE%"

echo ===============================================
echo            ILHA DO CONGO - MODPACK
echo      Instalador automatico de mods para Valheim
echo ===============================================
echo.

:: ===== DETECTAR VALHEIM =====
set VALHEIM_PATH=
for /f "skip=2 tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970" /v "InstallLocation" 2^>nul') do set VALHEIM_PATH=%%b
if not defined VALHEIM_PATH for /f "skip=2 tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970" /v "InstallLocation" 2^>nul') do set VALHEIM_PATH=%%b
if not defined VALHEIM_PATH if exist "C:\Program Files (x86)\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=C:\Program Files (x86)\Steam\steamapps\common\Valheim
if not defined VALHEIM_PATH if exist "C:\Program Files\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=C:\Program Files\Steam\steamapps\common\Valheim
if not defined VALHEIM_PATH if exist "D:\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=D:\Steam\steamapps\common\Valheim
if not defined VALHEIM_PATH if exist "E:\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=E:\Steam\steamapps\common\Valheim

if not defined VALHEIM_PATH (
    echo [AVISO] Nao foi possivel encontrar automaticamente a pasta do Valheim.
    echo.
    set /p VALHEIM_PATH="Digite manualmente o caminho do Valheim: "
    if "!VALHEIM_PATH!"=="" goto ERRO_CAMINHO_VAZIO
)
if not exist "!VALHEIM_PATH!\valheim.exe" goto ERRO_VALHEIM_NAO_ENCONTRADO
echo [OK] Valheim: !VALHEIM_PATH!
echo LOG: Valheim em: !VALHEIM_PATH! >> "%LOGFILE%"
echo.

:: ===== VERIFICAR MODS =====
set MODS_DIR=%~dp0mods
if not exist "!MODS_DIR!" goto ERRO_SEM_MODS

:: Contar DLLs com dir no lugar de for /r (mais compativel)
set DLL_COUNT=0
dir /b "!MODS_DIR!\*.dll" > "%TEMP%\ilhadllist.txt" 2>nul
if exist "%TEMP%\ilhadllist.txt" (
    for /f "usebackq delims=" %%f in ("%TEMP%\ilhadllist.txt") do set /a DLL_COUNT+=1
    del "%TEMP%\ilhadllist.txt" 2>nul
)
if !DLL_COUNT! equ 0 goto ERRO_SEM_DLLS
echo [INFO] !DLL_COUNT! mod(s) no pacote.
echo.

:: ===== VERIFICAR / INSTALAR BEPINEX =====
set BEPINEX_INSTALLED=0
if exist "!VALHEIM_PATH!\winhttp.dll" set BEPINEX_INSTALLED=1
if exist "!VALHEIM_PATH!\BepInEx\BepInEx.cfg" set BEPINEX_INSTALLED=1

if !BEPINEX_INSTALLED! equ 1 (
    echo [OK] BepInEx ja instalado.
) else (
    echo [INFO] BepInEx nao encontrado. Instalando automaticamente...
    echo LOG: Iniciando download BepInEx >> "%LOGFILE%"

    echo    Download do Thunderstore...
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2333/' -OutFile '%TEMP%\bepinex.zip' }" >nul 2>&1
    if not exist "%TEMP%\bepinex.zip" (
        where curl >nul 2>nul
        if !ERRORLEVEL! equ 0 curl -sL "https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2333/" -o "%TEMP%\bepinex.zip"
    )
    if not exist "%TEMP%\bepinex.zip" goto ERRO_BEPINEX_DOWNLOAD

    echo    Extraindo...
    set BEPINEX_TMP=%TEMP%\bepinex_install
    if exist "!BEPINEX_TMP!" rmdir /s /q "!BEPINEX_TMP!"
    mkdir "!BEPINEX_TMP!"

    powershell -Command "& { Add-Type -Assembly 'System.IO.Compression.FileSystem'; [System.IO.Compression.ZipFile]::ExtractToDirectory('%TEMP%\bepinex.zip', '!BEPINEX_TMP!', $true) }" >nul 2>&1

    :: O ZIP tem os arquivos dentro de BepInExPack_Valheim/
    if exist "!BEPINEX_TMP!\BepInExPack_Valheim\winhttp.dll" (
        echo    Movendo arquivos...
        xcopy /E /Y "!BEPINEX_TMP!\BepInExPack_Valheim\*" "!VALHEIM_PATH!\" >nul 2>&1
    ) else (
        xcopy /E /Y "!BEPINEX_TMP!\*" "!VALHEIM_PATH!\" >nul 2>&1
    )

    if exist "!VALHEIM_PATH!\winhttp.dll" (
        echo    [OK] BepInEx instalado com sucesso!
        echo LOG: BepInEx instalado >> "%LOGFILE%"
    ) else (
        goto ERRO_BEPINEX_EXTRACAO
    )

    rmdir /s /q "!BEPINEX_TMP!" 2>nul
    del "%TEMP%\bepinex.zip" 2>nul
    echo.
)

:: ===== PREPARAR PASTAS =====
if not exist "!VALHEIM_PATH!\BepInEx\plugins" mkdir "!VALHEIM_PATH!\BepInEx\plugins" 2>nul
if not exist "!VALHEIM_PATH!\BepInEx\config" mkdir "!VALHEIM_PATH!\BepInEx\config" 2>nul

echo. > "!VALHEIM_PATH!\BepInEx\plugins\.test_write" 2>nul
if not exist "!VALHEIM_PATH!\BepInEx\plugins\.test_write" goto ERRO_PERMISSAO
del "!VALHEIM_PATH!\BepInEx\plugins\.test_write" 2>nul

:: ===== COPIAR MODS =====
echo [INFO] Copiando mods...
set COPY_OK=0
set COPY_FAIL=0
set FAILED_FILES=

dir /b "!MODS_DIR!\*.dll" > "%TEMP%\ilhadllist.txt" 2>nul
for /f "usebackq delims=" %%f in ("%TEMP%\ilhadllist.txt") do (
    copy /Y "!MODS_DIR!\%%f" "!VALHEIM_PATH!\BepInEx\plugins\" >nul 2>>"%LOGFILE%"
    if !ERRORLEVEL! equ 0 (
        set /a COPY_OK+=1
        echo    [OK] %%f
    ) else (
        set /a COPY_FAIL+=1
        set FAILED_FILES=!FAILED_FILES! %%f
        echo    [FALHA] %%f
    )
)
del "%TEMP%\ilhadllist.txt" 2>nul

if exist "!MODS_DIR!\config" (
    xcopy /E /Y "!MODS_DIR!\config\*" "!VALHEIM_PATH!\BepInEx\config\" >nul 2>>"%LOGFILE%"
)

echo LOG: OK:!COPY_OK! FALHA:!COPY_FAIL! >> "%LOGFILE%"
echo.

:: ===== TELA FINAL =====
cls
echo ===============================================
if !COPY_FAIL! gtr 0 (echo         INSTALACAO PARCIAL - ATENCAO
) else if !COPY_OK! gtr 0 (echo           INSTALACAO CONCLUIDA!
) else (echo            INSTALACAO FALHOU)
echo ===============================================
echo.

if !COPY_OK! gtr 0 (
    echo [SUCESSO] !COPY_OK! mod(s) instalado(s)!
    echo.
    dir /b "!MODS_DIR!\*.dll" 2>nul
    echo.
    echo Proximo passo:
    echo   1. Abra o Valheim pela Steam
    echo   2. Join Game ^> Join IP: 187.77.49.71:2456
    echo   3. Senha: 202122
    echo.
)
if !COPY_FAIL! gtr 0 (
    echo [ATENCAO] !COPY_FAIL! falha(s):!FAILED_FILES!
    echo Execute como Administrador e tente novamente.
    echo.
)
if !COPY_OK! equ 0 (
    echo [ERRO] Nenhum mod instalado.
    echo Baixe o pacote novamente e execute como Administrador.
    echo.
)
echo [LOG] %LOGFILE%
echo.
pause
exit /b 0

:ERRO_CAMINHO_VAZIO
cls & echo Caminho nao informado. & pause & exit /b 1

:ERRO_VALHEIM_NAO_ENCONTRADO
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Valheim nao encontrado em: !VALHEIM_PATH!
echo.
echo Para resolver, copie o caminho correto da Steam:
echo   1. Steam ^> Biblioteca ^> Valheim (botao direito)
echo   2. Propriedades ^> Arquivos Instalados ^> Navegar
echo   3. Copie o caminho e execute o instalador novamente
echo.
pause & exit /b 1

:ERRO_SEM_MODS
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Pasta de mods nao encontrada.
echo Caminho esperado: %~dp0mods
echo.
echo Extraia o ZIP completo e execute o instalador dentro da pasta.
echo.
pause & exit /b 1

:ERRO_SEM_DLLS
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Nenhum arquivo .dll encontrado.
echo Pasta: !MODS_DIR!
echo.
echo Causa: antivirus removeu os arquivos ou pacote corrompido.
echo Baixe novamente, desative o antivirus e tente de novo.
echo.
pause & exit /b 1

:ERRO_PERMISSAO
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Sem permissao de escrita.
echo Caminho: !VALHEIM_PATH!\BepInEx\plugins
echo.
echo Execute o instalador como Administrador:
echo   1. Clique com botao direito no install_mods.bat
echo   2. "Executar como Administrador"
echo.
pause & exit /b 1

:ERRO_BEPINEX_DOWNLOAD
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Nao foi possivel baixar o BepInEx.
echo.
echo Verifique sua conexao com a internet.
echo Para instalar manualmente:
echo   1. Baixe de: https://valheim.thunderstore.io/package/denikson/BepInExPack_Valheim/
echo   2. Extraia BepInExPack_Valheim/winhttp.dll para: !VALHEIM_PATH!
echo   3. Extraia a pasta BepInEx/ para: !VALHEIM_PATH!
echo   4. Execute o instalador novamente
echo.
pause & exit /b 1

:ERRO_BEPINEX_EXTRACAO
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Nao foi possivel extrair o BepInEx corretamente.
echo.
echo Baixe e instale manualmente:
echo   1. https://valheim.thunderstore.io/package/denikson/BepInExPack_Valheim/
echo   2. Extraia o conteudo de BepInExPack_Valheim/ para: !VALHEIM_PATH!
echo   3. Execute o instalador novamente
echo.
pause & exit /b 1
