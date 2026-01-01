@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "ROUTER_IP=192.168.1.1"
set "USER=root"
set "REMOTE_PATH=/opt/etc/nfqws/"
set "LOCAL_FOLDER=UPLOAD_FOLDER"

cd /d "%~dp0"

if not exist "%LOCAL_FOLDER%" (
    mkdir "%LOCAL_FOLDER%"
)

:menu
cls
echo ==============================================
echo    ПЕРЕДАЧА ФАЙЛОВ NFQWS-KEENETIC
echo        script by S O K O L T V
echo ==============================================
echo Целевая папка: %REMOTE_PATH%
echo Локальная папка: %LOCAL_FOLDER%
echo.

set "count=0"
for %%F in ("%LOCAL_FOLDER%\*") do set /a count+=1

if !count! equ 0 (
    echo [INFO] Файлов для отправки не найдено.
    echo        Положите файлы в папку "%LOCAL_FOLDER%"
) else (
    echo [INFO] Найдено файлов для отправки: !count!
)

echo.
echo ФАЙЛЫ В ПАПКЕ ПОСЛЕ ПЕРЕДАЧИ УДАЛЯЮТСЯ
echo 1. ОТПРАВИТЬ файлы на роутер
echo 2. Открыть папку для файлов
echo 3. Обновить список (если подкинули файлы)
echo 0. Выход
echo ==============================================
choice /C 1230 /N /M "Выберите действие: "

if errorlevel 4 goto exit
if errorlevel 3 goto menu
if errorlevel 2 goto open_folder
if errorlevel 1 goto start_upload

:open_folder
start "" "%LOCAL_FOLDER%"
goto menu

:start_upload
if !count! equ 0 (
    echo.
    echo Нечего отправлять! Сначала положите файлы в папку.
    timeout /t 2 >nul
    goto menu
)

echo.
echo ------------------------------------------
echo Проверка связи с роутером...
echo (Если попросит пароль - введите его)
echo ------------------------------------------

ssh -o ConnectTimeout=5 %USER%@%ROUTER_IP% exit

if %errorlevel% neq 0 (
    color 4
    echo.
    echo ######################################################################
    echo [FATAL ERROR] Не удалось подключиться к роутеру!
    echo.
    echo Проверьте, что:
    echo  1. Роутер включен и доступен по адресу %ROUTER_IP%
    echo  2. Entware установлен
    echo  3. OpenSSL обновлен
	echo  4. VPN ВЫКЛЮЧЕН
    echo ######################################################################
    echo.
    pause
    color 07
    goto menu
)

echo.
echo [Connection established] 
echo Data transfer begins...
echo.

for %%F in ("%LOCAL_FOLDER%\*") do (
    set "FILENAME=%%~nxF"
    set "FULLPATH=%%F"
    
    echo SEND: !FILENAME! ...
    
    scp "!FULLPATH!" %USER%@%ROUTER_IP%:%REMOTE_PATH%
    
    if !errorlevel! equ 0 (
        echo [OK] Success. Deleting the local copy.
        del "!FULLPATH!"
    ) else (
        color 6
        echo [ERROR] Ошибка при передаче файла "!FILENAME!"
        color 07
    )
    echo ------------------------------------------
)

echo.
echo Mission complete.
pause
goto menu

:exit
exit