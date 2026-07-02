@echo off
title IlhaDoCongo - Instalador de Mods
setlocal enabledelayedexpansion
chcp 65001 >nul

:: ==============================================
::   ILHA DO CONGO - MODPACK VALHEIM
::   Instalador automatico de mods
:: ==============================================

set LOGFILE=%TEMP%\ilhadocongo_install.log
echo. > "%LOGFILE%"
echo LOG: Inicio da instalacao em %DATE% %TIME% >> "%LOGFILE%"

echo ===============================================
echo            ILHA DO CONGO - MODPACK
echo      Instalador automatico de mods para Valheim
echo ===============================================
echo.

:: ===== DETECTAR VALHEIM =====
set VALHEIM_PATH=
set FIND_METHOD=auto

:: Tenta registro do Steam
for /f "skip=2 tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970" /v "InstallLocation" 2^>nul') do (
    set VALHEIM_PATH=%%b
    set FIND_METHOD=registry
)
if not defined VALHEIM_PATH (
    for /f "skip=2 tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970" /v "InstallLocation" 2^>nul') do (
        set VALHEIM_PATH=%%b
        set FIND_METHOD=registry
    )
)

:: Tenta caminhos comuns
if not defined VALHEIM_PATH if exist "C:\Program Files (x86)\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=C:\Program Files (x86)\Steam\steamapps\common\Valheim
if not defined VALHEIM_PATH if exist "C:\Program Files\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=C:\Program Files\Steam\steamapps\common\Valheim
if not defined VALHEIM_PATH if exist "D:\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=D:\Steam\steamapps\common\Valheim
if not defined VALHEIM_PATH if exist "E:\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=E:\Steam\steamapps\common\Valheim

:: Pergunta manual se nao achou
if not defined VALHEIM_PATH (
    echo [AVISO] Nao foi possivel encontrar automaticamente a pasta do Valheim.
    echo          Verifique se o jogo esta instalado via Steam.
    echo.
    echo [INFO] Caminhos comuns verificados:
    echo   - C:\Program Files (x86)\Steam\steamapps\common\Valheim
    echo   - C:\Program Files\Steam\steamapps\common\Valheim
    echo   - D:\Steam\steamapps\common\Valheim
    echo   - E:\Steam\steamapps\common\Valheim
    echo.
    set /p VALHEIM_PATH="Digite manualmente o caminho do Valheim: "
    if "!VALHEIM_PATH!"=="" goto ERRO_CAMINHO_VAZIO
    set FIND_METHOD=manual
)

:: Validar caminho
if not exist "!VALHEIM_PATH!\valheim.exe" goto ERRO_VALHEIM_NAO_ENCONTRADO

echo [OK] Valheim encontrado: !VALHEIM_PATH! (metodo: !FIND_METHOD!)
echo LOG: Valheim em: !VALHEIM_PATH! >> "%LOGFILE%"
echo.

:: ===== VERIFICAR MODS =====
set MODS_DIR=%~dp0mods
if not exist "!MODS_DIR!" goto ERRO_SEM_MODS

set DLL_COUNT=0
for /r "!MODS_DIR!" %%f in (*.dll) do set /a DLL_COUNT+=1
if !DLL_COUNT! equ 0 goto ERRO_SEM_DLLS

echo [INFO] !DLL_COUNT! mod(s) encontrado(s) no pacote.
echo LOG: DLLs no pacote: !DLL_COUNT! >> "%LOGFILE%"
echo.

:: ===== VERIFICAR / INSTALAR BEPINEX =====
set BEPINEX_INSTALLED=0
if exist "!VALHEIM_PATH!\winhttp.dll" set BEPINEX_INSTALLED=1
if exist "!VALHEIM_PATH!\BepInEx\BepInEx.cfg" set BEPINEX_INSTALLED=1

if !BEPINEX_INSTALLED! equ 1 (
    echo [OK] BepInEx ja esta instalado.
    echo LOG: BepInEx ja presente >> "%LOGFILE%"
) else (
    echo [AVISO] BepInEx nao encontrado!
    echo [INFO] Baixando e instalando BepInEx automaticamente...
    echo LOG: Iniciando download do BepInEx >> "%LOGFILE%"
    echo.

    :: Baixar BepInExPack do Thunderstore via PowerShell
    echo    Baixando BepInExPack_Valheim 5.4.2333...
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2333/' -OutFile '%TEMP%\bepinex.zip' }"

    if not exist "%TEMP%\bepinex.zip" (
        echo    [FALHA] Download falhou. Tentando com curl...
        where curl >nul 2>nul
        if !ERRORLEVEL! equ 0 (
            curl -sL "https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2333/" -o "%TEMP%\bepinex.zip"
        )
    )

    if not exist "%TEMP%\bepinex.zip" goto ERRO_BEPINEX_DOWNLOAD

    :: Extrair no diretorio do Valheim
    echo    Extraindo BepInEx...
    powershell -Command "& { Add-Type -Assembly 'System.IO.Compression.FileSystem'; [System.IO.Compression.ZipFile]::ExtractToDirectory('%TEMP%\bepinex.zip', '!VALHEIM_PATH!', $true) }" 2>nul

    :: Verificar se extraiu corretamente
    if exist "!VALHEIM_PATH!\winhttp.dll" (
        echo    [OK] BepInEx instalado com sucesso!
        echo LOG: BepInEx instalado automaticamente >> "%LOGFILE%"
    ) else (
        :: Tentar extracao manual
        echo    Tentando extracao alternativa...
        if exist "%TEMP%\bepinex.zip" (
            powershell -Command "& { Expand-Archive -Path '%TEMP%\bepinex.zip' -DestinationPath '!VALHEIM_PATH!' -Force }" 2>nul
        )
        if exist "!VALHEIM_PATH!\winhttp.dll" (
            echo    [OK] BepInEx instalado com sucesso!
        ) else (
            goto ERRO_BEPINEX_EXTRACAO
        )
    )

    :: Limpar
    del "%TEMP%\bepinex.zip" 2>nul
    echo.
)

:: ===== GARANTIR PASTAS DE PLUGINS =====
if not exist "!VALHEIM_PATH!\BepInEx\plugins" mkdir "!VALHEIM_PATH!\BepInEx\plugins" 2>nul
if not exist "!VALHEIM_PATH!\BepInEx\config" mkdir "!VALHEIM_PATH!\BepInEx\config" 2>nul

:: Verificar permissao
echo. > "!VALHEIM_PATH!\BepInEx\plugins\.test_write" 2>nul
if not exist "!VALHEIM_PATH!\BepInEx\plugins\.test_write" goto ERRO_PERMISSAO
del "!VALHEIM_PATH!\BepInEx\plugins\.test_write" 2>nul

:: ===== COPIAR MODS =====
echo [INFO] Copiando mods para BepInEx/plugins/...
echo LOG: Copiando mods >> "%LOGFILE%"

set COPY_OK=0
set COPY_FAIL=0
set FAILED_FILES=

for /r "!MODS_DIR!" %%f in (*.dll) do (
    copy /Y "%%f" "!VALHEIM_PATH!\BepInEx\plugins\" >nul 2>>"%LOGFILE%"
    if !ERRORLEVEL! equ 0 (
        set /a COPY_OK+=1
        echo    [OK] %%~nxf
        echo LOG: OK - %%~nxf >> "%LOGFILE%"
    ) else (
        set /a COPY_FAIL+=1
        set FAILED_FILES=!FAILED_FILES! %%~nxf
        echo    [FALHA] %%~nxf
        echo LOG: FALHA - %%~nxf >> "%LOGFILE%"
    )
)

:: Copiar configs se existirem
if exist "!MODS_DIR!\config" (
    echo.
    echo [INFO] Copiando configuracoes...
    xcopy /E /Y "!MODS_DIR!\config\*" "!VALHEIM_PATH!\BepInEx\config\" >nul 2>>"%LOGFILE%"
)

echo LOG: Resultado - OK:!COPY_OK! FALHA:!COPY_FAIL! >> "%LOGFILE%"
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
    echo [SUCESSO] !COPY_OK! mod(s) instalado(s) com sucesso!
    echo.
    echo Modos instalados em:
    echo   !VALHEIM_PATH!\BepInEx\plugins\
    echo.
    for /r "!MODS_DIR!" %%f in (*.dll) do (
        echo    - %%~nxf
    )
    echo.
    echo === Proximo passo ===
    echo   1. Abra o Valheim pela Steam (BepInEx carrega automaticamente)
    echo   2. Join Game ^> Join IP
    echo   3. Digite: 187.77.49.71:2456  |  Senha: 202122
    echo.
)

if !COPY_FAIL! gtr 0 (
    echo [ATENCAO] !COPY_FAIL! mod(s) nao puderam ser copiados.
    echo.
    echo Arquivos:!FAILED_FILES!
    echo.
    echo Causa provavel: antivirus bloqueando ou permissao insuficiente.
    echo Para resolver: execute como Administrador.
    echo.
)

if !COPY_OK! equ 0 (
    echo [ERRO] Nenhum mod foi instalado.
    echo        Baixe o pacote novamente e execute como Administrador.
    echo.
)

echo ===============================================
echo   Servidor: IlhaDoCongo
echo   IP:       187.77.49.71:2456
echo   Senha:    202122
echo ===============================================
echo.
echo [LOG] %LOGFILE%
echo.
pause
exit /b 0

:: ======================================================================
:: BLOCOS DE ERRO
:: ======================================================================

:ERRO_CAMINHO_VAZIO
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Caminho do Valheim nao informado.
echo.
echo Para resolver:
echo   1. Steam ^> Biblioteca ^> Valheim (botao direito)
echo   2. Propriedades ^> Arquivos Instalados ^> Navegar
echo   3. Copie o caminho e execute o instalador novamente
echo.
pause
exit /b 1

:ERRO_VALHEIM_NAO_ENCONTRADO
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Valheim nao encontrado no caminho informado.
echo.
echo Caminho verificado: !VALHEIM_PATH!
echo.
echo Causas possiveis:
echo   - O caminho digitado esta incorreto
echo   - O Valheim nao esta instalado nesta maquina
echo   - O jogo esta em outra unidade ou biblioteca Steam
echo.
pause
exit /b 1

:ERRO_SEM_MODS
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Pasta de mods nao encontrada.
echo.
echo Caminho esperado: !MODS_DIR!
echo.
echo Causas possiveis:
echo   - O pacote foi extraido incompleto
echo   - O instalador foi movido para outra pasta
echo.
echo Para resolver:
echo   1. Delete tudo que voce extraiu
echo   2. Extraia o ZIP novamente em uma pasta nova
echo   3. Nao mova o install_mods.bat para fora da pasta
echo.
pause
exit /b 1

:ERRO_SEM_DLLS
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Nenhum arquivo de mod (.dll) encontrado.
echo.
echo Pasta verificada: !MODS_DIR!
echo.
echo Causas possiveis:
echo   - O pacote esta corrompido
echo   - O antivirus removeu os arquivos .dll
echo.
echo Para resolver:
echo   1. Baixe o pacote novamente do GitHub
echo   2. Desative o antivirus temporariamente
echo   3. Extraia e execute novamente
echo.
pause
exit /b 1

:ERRO_PERMISSAO
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Sem permissao de escrita na pasta do Valheim.
echo.
echo Caminho: !VALHEIM_PATH!\BepInEx\plugins
echo.
echo Causa: O instalador precisa de permissao de administrador
echo        para modificar a pasta do Valheim.
echo.
echo Para resolver:
echo   1. Feche esta janela
echo   2. Clique com botao direito no install_mods.bat
echo   3. Selecione "Executar como Administrador"
echo   4. Tente novamente
echo.
pause
exit /b 1

:ERRO_BEPINEX_DOWNLOAD
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: Nao foi possivel baixar o BepInEx.
echo.
echo O instalador tentou baixar de:
echo   https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2333/
echo.
echo Causas possiveis:
echo   - Sua internet esta desconectada
echo   - O Thunderstore esta fora do ar
echo   - Seu firewall bloqueou o download
echo   - PowerShell nao esta disponivel (Windows 7 ou versao antiga)
echo.
echo Para resolver manualmente:
echo   1. Baixe o BepInExPack em: https://valheim.thunderstore.io/package/denikson/BepInExPack_Valheim/
echo   2. Extraia o conteudo DENTRO da pasta do Valheim: !VALHEIM_PATH!
echo   3. Execute o install_mods.bat novamente
echo.
pause
exit /b 1

:ERRO_BEPINEX_EXTRACAO
cls
echo ===============================================
echo               ERRO NA INSTALACAO
echo ===============================================
echo.
echo Motivo: BepInEx baixado mas nao foi possivel extrair.
echo.
echo Causas possiveis:
echo   - O arquivo baixado esta corrompido
echo   - Disco sem espaco
echo   - Permissao insuficiente
echo.
echo Para resolver manualmente:
echo   1. Baixe o BepInExPack em: https://valheim.thunderstore.io/package/denikson/BepInExPack_Valheim/
echo   2. Extraia manualmente DENTRO da pasta: !VALHEIM_PATH!
echo   3. Execute o install_mods.bat novamente
echo.
pause
exit /b 1
