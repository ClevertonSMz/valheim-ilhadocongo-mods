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
    echo [AVISO] Nao foi possivel encontrar automaticamente.
    echo.
    set /p VALHEIM_PATH="Digite o caminho do Valheim: "
    if "!VALHEIM_PATH!"=="" goto ERRO_CAMINHO_VAZIO
)
if not exist "!VALHEIM_PATH!\valheim.exe" goto ERRO_VALHEIM_NAO_ENCONTRADO
echo [OK] Valheim: !VALHEIM_PATH!
echo LOG: Valheim em: !VALHEIM_PATH! >> "%LOGFILE%"
echo.

:: ===== VERIFICAR MODS =====
set MODS_DIR=%~dp0mods
if not exist "!MODS_DIR!" goto ERRO_SEM_MODS
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

if !BEPINEX_INSTALLED! equ 1 goto BEPI_EXISTE

:: ===== INSTALAR BEPINEX =====
echo [INFO] BepInEx nao encontrado. Instalando...
echo LOG: Iniciando download BepInEx >> "%LOGFILE%"

echo    Baixando BepInExPack 5.4.2333 do Thunderstore...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2333/' -OutFile '%TEMP%\bepinex.zip'" > "%TEMP%\bepi.log" 2>&1
if not exist "%TEMP%\bepinex.zip" (
    where curl >nul 2>nul
    if !ERRORLEVEL! equ 0 curl -sL "https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2333/" -o "%TEMP%\bepinex.zip"
)
if not exist "%TEMP%\bepinex.zip" goto ERRO_BEPINEX_DOWNLOAD

echo    Extraindo...
if exist "%TEMP%\bepinex_install" rmdir /s /q "%TEMP%\bepinex_install"
mkdir "%TEMP%\bepinex_install"

:: --- Metodo 1: Expand-Archive (PowerShell 5+) ---
echo Metodo 1 (Expand-Archive)... >> "%TEMP%\bepi.log"
powershell -Command "Expand-Archive -Path '%TEMP%\bepinex.zip' -DestinationPath '%TEMP%\bepinex_install' -Force" >> "%TEMP%\bepi.log" 2>&1
if exist "%TEMP%\bepinex_install\winhttp.dll" goto BEPI_COPY
if exist "%TEMP%\bepinex_install\BepInExPack_Valheim\winhttp.dll" goto BEPI_COPY_SUBDIR

:: --- Metodo 2: ZipFile.ExtractToDirectory ---
echo Metodo 2 (ZipFile)... >> "%TEMP%\bepi.log"
if exist "%TEMP%\bepinex_install" rmdir /s /q "%TEMP%\bepinex_install"
mkdir "%TEMP%\bepinex_install"
powershell -Command "Add-Type -Assembly 'System.IO.Compression.FileSystem'; [System.IO.Compression.ZipFile]::ExtractToDirectory('%TEMP%\bepinex.zip', '%TEMP%\bepinex_install')" >> "%TEMP%\bepi.log" 2>&1
if exist "%TEMP%\bepinex_install\winhttp.dll" goto BEPI_COPY
if exist "%TEMP%\bepinex_install\BepInExPack_Valheim\winhttp.dll" goto BEPI_COPY_SUBDIR

:: --- Metodo 3: Shell.Application COM ---
echo Metodo 3 (Shell COM)... >> "%TEMP%\bepi.log"
if exist "%TEMP%\bepinex_install" rmdir /s /q "%TEMP%\bepinex_install"
mkdir "%TEMP%\bepinex_install"
powershell -Command "$sh = New-Object -ComObject Shell.Application; $zp = $sh.NameSpace('%TEMP%\bepinex.zip'); $dt = $sh.NameSpace('%TEMP%\bepinex_install'); $dt.CopyHere($zp.Items(), 16)" >> "%TEMP%\bepi.log" 2>&1
if exist "%TEMP%\bepinex_install\winhttp.dll" goto BEPI_COPY
if exist "%TEMP%\bepinex_install\BepInExPack_Valheim\winhttp.dll" goto BEPI_COPY_SUBDIR

:: Todos falharam
echo.
echo [FALHA] Nao foi possivel extrair o BepInEx.
type "%TEMP%\bepi.log" 2>nul
goto ERRO_BEPINEX_EXTRACAO

:BEPI_COPY_SUBDIR
echo    ZIP tem subpasta BepInExPack_Valheim/. Movendo...
xcopy /E /Y "%TEMP%\bepinex_install\BepInExPack_Valheim\*" "!VALHEIM_PATH!\" >nul 2>&1
if exist "!VALHEIM_PATH!\winhttp.dll" goto BEPI_OK
goto ERRO_BEPINEX_EXTRACAO

:BEPI_COPY
echo    ZIP tem arquivos na raiz. Copiando...
xcopy /E /Y "%TEMP%\bepinex_install\*" "!VALHEIM_PATH!\" >nul 2>&1
if exist "!VALHEIM_PATH!\winhttp.dll" goto BEPI_OK
goto ERRO_BEPINEX_EXTRACAO

:BEPI_OK
echo    [OK] BepInEx instalado!
echo LOG: BepInEx instalado >> "%LOGFILE%"
rmdir /s /q "%TEMP%\bepinex_install" 2>nul
del "%TEMP%\bepinex.zip" 2>nul
del "%TEMP%\bepi.log" 2>nul
echo.
goto FIM_INSTALACAO_BEPI

:BEPI_EXISTE
echo [OK] BepInEx ja instalado.

:FIM_INSTALACAO_BEPI

:: ===== PREPARAR PASTAS =====
if not exist "!VALHEIM_PATH!\BepInEx\plugins" mkdir "!VALHEIM_PATH!\BepInEx\plugins" 2>nul
if not exist "!VALHEIM_PATH!\BepInEx\config" mkdir "!VALHEIM_PATH!\BepInEx\config" 2>nul

echo. > "!VALHEIM_PATH!\BepInEx\plugins\.test_write" 2>nul
if not exist "!VALHEIM_PATH!\BepInEx\plugins\.test_write" goto ERRO_PERMISSAO
del "!VALHEIM_PATH!\BepInEx\plugins\.test_write" 2>nul

:: ===== COPIAR MODS =====
echo [INFO] Copiando mods para BepInEx/plugins/...
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
if !COPY_FAIL! gtr 0 (
    echo         INSTALACAO PARCIAL - ATENCAO
) else if !COPY_OK! gtr 0 (
    echo           INSTALACAO CONCLUIDA!
) else (
    echo            INSTALACAO FALHOU
)
echo ===============================================
echo.

if !COPY_OK! gtr 0 (
    echo [SUCESSO] !COPY_OK! mod(s) instalado(s)!
    echo.
    dir /b "!MODS_DIR!\*.dll" 2>nul
    echo.
    echo Proximo passo:
    echo   1. Abra o Valheim pela Steam (BepInEx carrega automaticamente)
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
    echo Baixe o pacote novamente.
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
echo Para resolver: Steam > Biblioteca > Valheim (botao direito) > Propriedades > Arquivos Instalados > Navegar
echo.
pause & exit /b 1

:ERRO_SEM_MODS
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Pasta mods/ nao encontrada em %~dp0mods
echo Extraia o ZIP completo antes de executar.
echo.
pause & exit /b 1

:ERRO_SEM_DLLS
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Nenhum arquivo .dll em: !MODS_DIR!
echo Antivirus pode ter removido. Baixe novamente.
echo.
pause & exit /b 1

:ERRO_PERMISSAO
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Sem permissao de escrita em !VALHEIM_PATH!\BepInEx\plugins
echo Execute como Administrador.
echo.
pause & exit /b 1

:ERRO_BEPINEX_DOWNLOAD
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Nao foi possivel baixar o BepInEx.
echo Verifique sua internet.
echo Instalacao manual: https://thunderstore.io/package/denikson/BepInExPack_Valheim/
echo.
pause & exit /b 1

:ERRO_BEPINEX_EXTRACAO
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Nao foi possivel extrair o BepInEx.
echo Log: %TEMP%\bepi.log
echo Instalacao manual: Baixe BepInExPack, extraia para !VALHEIM_PATH!, execute novamente.
echo.
pause & exit /b 1
