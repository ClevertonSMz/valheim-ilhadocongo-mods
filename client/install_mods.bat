@echo off
title IlhaDoCongo - Instalador de Mods
setlocal enabledelayedexpansion
chcp 65001 >nul

:: ==============================================
::   ILHA DO CONGO - MODPACK VALHEIM
::   Instalador automatico de mods
:: ==============================================

set ERR=0
set LOGFILE=%TEMP%\ilhadocongo_install.log

echo. > "%LOGFILE%"
echo ===============================================
echo            ILHA DO CONGO - MODPACK
echo      Instalador automatico de mods para Valheim
echo ===============================================
echo.
echo [LOG] Iniciando instalacao em %DATE% %TIME% >> "%LOGFILE%"

:: ===== DETECTAR VALHEIM =====
set VALHEIM_PATH=
set FIND_METHOD=auto

:: Tenta ler registro do Steam (64 bits)
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
if not defined VALHEIM_PATH (
    if exist "C:\Program Files (x86)\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=C:\Program Files (x86)\Steam\steamapps\common\Valheim
)
if not defined VALHEIM_PATH (
    if exist "C:\Program Files\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=C:\Program Files\Steam\steamapps\common\Valheim
)
if not defined VALHEIM_PATH (
    if exist "D:\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=D:\Steam\steamapps\common\Valheim
)
if not defined VALHEIM_PATH (
    if exist "E:\Steam\steamapps\common\Valheim\valheim.exe" set VALHEIM_PATH=E:\Steam\steamapps\common\Valheim
)

:: Se nao achou, pergunta manualmente
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
    if "!VALHEIM_PATH!"=="" (
        cls
        echo ===============================================
        echo               ERRO NA INSTALACAO
        echo ===============================================
        echo.
        echo Motivo: Caminho do Valheim nao informado.
        echo.
        echo Para resolver:
        echo   1. Abra a Steam, clique com botao direito no Valheim
        echo   2. Propriedades > Arquivos Instalados > Navegar
        echo   3. Copie o caminho da barra de enderecos
        echo   4. Execute o instalador novamente e cole o caminho
        echo.
        pause
        exit /b 1
    )
    set FIND_METHOD=manual
)

:: Validar caminho
if not exist "!VALHEIM_PATH!\valheim.exe" (
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
    echo Para resolver:
    echo   1. Abra a Steam, clique com botao direito no Valheim
    echo   2. Propriedades > Arquivos Instalados > Navegar
    echo   3. Copie o caminho completo e tente novamente
    echo.
    pause
    exit /b 1
)

echo [OK] Valheim encontrado: !VALHEIM_PATH! (metodo: !FIND_METHOD!)
echo [LOG] Valheim em: !VALHEIM_PATH! >> "%LOGFILE%"
echo.

:: ===== PASTA DE MODS =====
set MODS_DIR=%~dp0mods

if not exist "!MODS_DIR!" (
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
    echo   - O arquivo ZIP foi extraido em local errado
    echo.
    echo Para resolver:
    echo   1. Delete tudo que voce extraiu
    echo   2. Extraia o ZIP novamente em uma pasta nova
    echo   3. Execute o instalador DENTRO da pasta extraida
    echo.
    pause
    exit /b 1
)

:: ===== CONTAR DLLS DISPONIVEIS =====
set DLL_COUNT=0
for /r "!MODS_DIR!" %%f in (*.dll) do set /a DLL_COUNT+=1

if !DLL_COUNT! equ 0 (
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
    echo   - Os mods nao foram incluidos no ZIP
    echo   - O antivirus removeu os arquivos .dll
    echo.
    echo Para resolver:
    echo   1. Baixe o pacote novamente do GitHub
    echo   2. Desative o antivirus temporariamente
    echo   3. Extraia e execute novamente
    echo.
    pause
    exit /b 1
)

echo [INFO] !DLL_COUNT! mod(s) encontrado(s) no pacote.
echo [LOG] DLLs encontradas: !DLL_COUNT! >> "%LOGFILE%"
echo.

:: ===== CRIAR PASTAS BEPINEX =====
echo [INFO] Verificando pastas BepInEx...
if not exist "!VALHEIM_PATH!\BepInEx" (
    echo [AVISO] Pasta BepInEx nao encontrada.
    echo [INFO] O BepInEx precisa estar instalado para os mods funcionarem.
    echo [INFO] Continuando instalacao dos mods mesmo assim...
    mkdir "!VALHEIM_PATH!\BepInEx" 2>nul
    mkdir "!VALHEIM_PATH!\BepInEx\plugins" 2>nul
    mkdir "!VALHEIM_PATH!\BepInEx\config" 2>nul
    if not exist "!VALHEIM_PATH!\BepInEx\plugins" (
        cls
        echo ===============================================
        echo               ERRO NA INSTALACAO
        echo ===============================================
        echo.
        echo Motivo: Nao foi possivel criar a pasta BepInEx.
        echo.
        echo Caminho: !VALHEIM_PATH!\BepInEx\plugins
        echo.
        echo Causas possiveis:
        echo   - O instalador precisa ser executado como Administrador
        echo   - A pasta do Valheim esta em um local protegido
        echo   - Permissao de escrita negada
        echo.
        echo Para resolver:
        echo   1. Clique com botao direito no install_mods.bat
        echo   2. Selecione "Executar como Administrador"
        echo   3. Tente novamente
        echo.
        pause
        exit /b 1
    )
) else (
    if not exist "!VALHEIM_PATH!\BepInEx\plugins" mkdir "!VALHEIM_PATH!\BepInEx\plugins" 2>nul
    if not exist "!VALHEIM_PATH!\BepInEx\config" mkdir "!VALHEIM_PATH!\BepInEx\config" 2>nul
)

:: ===== COPIAR MODS =====
echo [INFO] Copiando mods para plugins...
echo [LOG] Iniciando copia das DLLs >> "%LOGFILE%"

set COPY_OK=0
set COPY_FAIL=0
set FAILED_FILES=

for /r "!MODS_DIR!" %%f in (*.dll) do (
    copy /Y "%%f" "!VALHEIM_PATH!\BepInEx\plugins\" >nul 2>>"%LOGFILE%"
    if !ERRORLEVEL! equ 0 (
        set /a COPY_OK+=1
        echo    [OK] %%~nxf
        echo [LOG] OK: %%~nxf >> "%LOGFILE%"
    ) else (
        set /a COPY_FAIL+=1
        set FAILED_FILES=!FAILED_FILES! %%~nxf
        echo    [FALHA] %%~nxf
        echo [LOG] FALHA: %%~nxf >> "%LOGFILE%"
    )
)

:: ===== COPIAR CONFIGS =====
if exist "!MODS_DIR!\config" (
    echo [INFO] Copiando configuracoes...
    xcopy /E /Y "!MODS_DIR!\config\*" "!VALHEIM_PATH!\BepInEx\config\" >nul 2>>"%LOGFILE%"
    if !ERRORLEVEL! equ 0 (
        echo    [OK] Configuracoes copiadas
    ) else (
        echo    [AVISO] Algumas configuracoes podem nao ter sido copiadas
    )
)

echo.
echo [LOG] Copiados: !COPY_OK! | Falhas: !COPY_FAIL! >> "%LOGFILE%"

:: ===== VERIFICAR RESULTADO FINAL =====
cls
echo ===============================================
if !COPY_FAIL! gtr 0 (
    echo         INSTALACAO PARCIAL - ATENCAO
) else (
    if !COPY_OK! gtr 0 (
        echo           INSTALACAO CONCLUIDA!
    ) else (
        echo            INSTALACAO FALHOU
    )
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
)

if !COPY_FAIL! gtr 0 (
    echo [ATENCAO] !COPY_FAIL! mod(s) nao puderam ser copiados.
    echo.
    echo Arquivos com problema:!FAILED_FILES!
    echo.
    echo Causas possiveis:
    echo   - Pasta BepInEx\plugins protegida contra escrita
    echo   - Arquivo .dll bloqueado pelo antivirus
    echo   - Permissao de escrita insuficiente
    echo.
    echo Para resolver: execute o instalador como Administrador.
    echo.
)

if !COPY_OK! equ 0 (
    echo [ERRO] Nenhum mod foi instalado.
    echo.
    echo Causas possiveis:
    echo   - O pacote esta corrompido ou vazio
    echo   - A pasta de mods nao contem arquivos .dll
    echo   - O antivirus removeu os mods durante a extracao
    echo.
    echo Para resolver:
    echo   1. Baixe o pacote novamente
    echo   2. Desative o antivirus temporariamente
    echo   3. Execute o instalador como Administrador
    echo.
)

echo.
echo === Informacoes do servidor ===
echo   Servidor: IlhaDoCongo
echo   IP:       187.77.49.71:2456
echo   Senha:    202122
echo.
echo === Para conectar ===
echo   1. Abra o Valheim (com BepInEx carregando os mods)
echo   2. Join Game > Join IP
echo   3. Digite o IP e senha acima
echo.
echo === Desinstalar mods ===
echo   Delete a pasta: !VALHEIM_PATH!\BepInEx\
echo.
echo === Log de instalacao ===
echo   %LOGFILE%
echo.
pause
