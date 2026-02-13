@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "ROUTER_IP=192.168.1.1"
set "USER=root"
set "REMOTE_BASE=/opt/etc/nfqws2/"
set "LOCAL_FOLDER=UPLOAD_FOLDER"

cd /d "%~dp0"

if not exist "%LOCAL_FOLDER%" (
    mkdir "%LOCAL_FOLDER%"
)

:menu
cls
echo ==============================================
echo    ПЕРЕДАЧА ФАЙЛОВ NFQWS2-KEENETIC
echo        script by S O K O L T V
echo ==============================================
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
echo Еси нужно передать бинарники, сначала, кладите в папку бинарники
echo Еси листы или скрипты, то кладите листы ИЛИ скрипты
echo Сквирт пока передаёт только файлы одного типа в одну выбранную папку
echo В противном случае листы у вас окажутся в блопах, или бинарники в листах или скриптах
echo Мешать работе не будет, но бардак будет
echo ==============================================
echo 1. ОТПРАВИТЬ файлы на роутер
echo 2. Открыть папку для файлов
echo 3. Обновить список файлов в папке
echo 0. Выход
echo ==============================================
choice /C 1230 /N /M "Выберите действие: "

if errorlevel 4 goto exit
if errorlevel 3 goto menu
if errorlevel 2 goto open_folder
if errorlevel 1 goto select_dest

:open_folder
start "" "%LOCAL_FOLDER%"
goto menu

:select_dest
if !count! equ 0 (
    echo.
    echo Нет файлов в папке! Положите файлы в папку.
    timeout /t 2 >nul
    goto menu
)

cls
echo ==============================================
echo    ВЫБОР ПАПКИ НАЗНАЧЕНИЯ
echo ==============================================
echo.
echo Выберите папку на роутере куда загружать?
echo.
echo 1. blobs  (%REMOTE_BASE%blobs/)
echo 2. lists  (%REMOTE_BASE%lists/)
echo 3. lua    (%REMOTE_BASE%lua/)
echo 0. Вернуться назад
echo.
echo ==============================================
choice /C 1230 /N /M "Выберите папку: "

if errorlevel 4 goto menu
if errorlevel 3 set "TARGET_DIR=lua" & goto start_upload
if errorlevel 2 set "TARGET_DIR=lists" & goto start_upload
if errorlevel 1 set "TARGET_DIR=blobs" & goto start_upload

:start_upload
set "FULL_REMOTE_PATH=%REMOTE_BASE%%TARGET_DIR%/"

echo.
echo ------------------------------------------
echo Цель: %FULL_REMOTE_PATH%
echo Start Transmission...
echo (Введите пароль от роутера)
echo ------------------------------------------

set "fail_count=0"
set "first_run=1"

for %%F in ("%LOCAL_FOLDER%\*") do (
    set "FILENAME=%%~nxF"
    set "FULLPATH=%%F"
    
    echo SENDING: !FILENAME!
    
    :: Пытаемся передать файл
    scp "!FULLPATH!" %USER%@%ROUTER_IP%:%FULL_REMOTE_PATH%
    
    if !errorlevel! equ 0 (
        echo [OK] Succesfull. Deleting local copy.
        del "!FULLPATH!"
        set "first_run=0"
    ) else (
        color 6
        echo.
        echo [ERROR] Ошибка при передаче файла "!FILENAME!"
        echo.
        
        :: Если ошибка произошла на самом первом файле - скорее всего пароль неверен или нет связи
        if !first_run! equ 1 (
            color 4
            echo [FATAL] Не удалось передать первый файл.
            echo Вероятно, неверный пароль или нет связи.
            echo.
            echo 1. Попробовать снова
            echo 0. Выйти в меню
            choice /C 10 /N /M "Выбор: "
            if errorlevel 2 (
                 color 07
                 goto menu
            ) else (
                 color 07
                 goto start_upload
            )
        )
        color 07
    )
    echo ------------------------------------------
)

echo.
echo Mission Complete.
pause
goto menu

:exit
exit