@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Samsung DeX Pro — Galaxy A55

:: Автоопределение рабочей директории scrcpy и adb
if exist "%~dp0scrcpy.exe" (
    set "SCRCPY_DIR=%~dp0"
) else if exist "D:\programs\scrcpy-win64-v3.3.4\scrcpy.exe" (
    set "SCRCPY_DIR=D:\programs\scrcpy-win64-v3.3.4"
) else (
    echo [ОШИБКА] Каталог scrcpy не найден!
    pause
    exit /b 1
)
if "%SCRCPY_DIR:~-1%"=="\" set "SCRCPY_DIR=%SCRCPY_DIR:~0,-1%"
set "PATH=%SCRCPY_DIR%;%PATH%"
cd /d "%SCRCPY_DIR%"

:: Значения по умолчанию
set "RES=1920x1080/160"
set "BITRATE=16M"
set "FPS=60"
set "CODEC=h265"
set "ENCODER=c2.exynos.hevc.encoder"
set "AUDIO_MODE=pc"
set "MOUSE_MODE=sdk"
set "WINDOW_MODE=window"
set "SHORTCUT_MODE=safe"
set "WIFI_IP=192.168.0.111"

:: Проверка аргументов командной строки для прямого запуска без меню
if not "%~1"=="" (
    if "%~1"=="1" goto start_usb
    if /i "%~1"=="usb" goto start_usb
    if "%~1"=="2" (
        call :detect_ip
        goto start_wifi
    )
    if /i "%~1"=="wifi" (
        call :detect_ip
        goto start_wifi
    )
    if "%~1"=="3" goto set_ip_manual
    if "%~1"=="4" goto setup_tcpip
    if "%~1"=="5" goto settings_menu
    if "%~1"=="6" goto setup_keyboard
    if "%~1"=="7" goto make_shortcut
    if "%~1"=="8" exit /b 0
)

:: Определение IP перед отображением интерактивного меню
call :detect_ip

:menu
cls
echo ================================================================
echo       Samsung DeX Pro — Galaxy A55 (Android 16 / One UI 8.5)
echo ================================================================
echo.
echo   [Текущий IP Wi-Fi: %WIFI_IP%]
echo   [Профиль: %RES% @ %FPS%fps, %CODEC% %BITRATE%]
echo   [Режим: Окно (%WINDOW_MODE%), Звук: %AUDIO_MODE%, Мышь: %MOUSE_MODE%, Шорткаты: %SHORTCUT_MODE%]
echo.
echo  1 - Запуск по USB (Кабель, минимальная задержка, 60 FPS)
echo  2 - Запуск по Wi-Fi (Беспроводной DeX: %WIFI_IP%:5555)
echo  3 - Быстрое переключение / ручной ввод Wi-Fi IP
echo  4 - Первичная активация Wi-Fi режима (USB -^> TCP/IP 5555)
echo  5 - Параметры (Разрешение, FPS, Звук, Мышь, Полный экран)
echo  6 - Настройка раскладки физической клавиатуры (RU / EN)
echo  7 - Создать / обновить ярлыки на Рабочем столе
echo  8 - Выход
echo.
echo ================================================================
set "choice="
set /p "choice=Ваш выбор (1-8): "

if "%choice%"=="1" goto start_usb
if "%choice%"=="2" goto start_wifi
if "%choice%"=="3" goto set_ip_manual
if "%choice%"=="4" goto setup_tcpip
if "%choice%"=="5" goto settings_menu
if "%choice%"=="6" goto setup_keyboard
if "%choice%"=="7" goto make_shortcut
if "%choice%"=="8" exit /b 0
goto menu

:detect_ip
set "DETECTED_IP="
:: 1. Попытка через USB
adb -d shell ip -4 addr show dev wlan0 <nul > "%TEMP%\a55_ip.tmp" 2>nul
if exist "%TEMP%\a55_ip.tmp" (
    for /f "tokens=2" %%A in ('findstr /c:"inet " "%TEMP%\a55_ip.tmp"') do (
        for /f "delims=/" %%B in ("%%A") do set "DETECTED_IP=%%B"
    )
    del "%TEMP%\a55_ip.tmp" 2>nul
)
if not "%DETECTED_IP%"=="" (
    set "WIFI_IP=%DETECTED_IP%"
    exit /b 0
)
:: 2. Попытка через активные adb tcp устройства
adb devices <nul > "%TEMP%\a55_dev.tmp" 2>nul
if exist "%TEMP%\a55_dev.tmp" (
    for /f "tokens=1" %%A in ('findstr /c:":5555" "%TEMP%\a55_dev.tmp"') do (
        for /f "delims=:" %%B in ("%%A") do set "DETECTED_IP=%%B"
    )
    del "%TEMP%\a55_dev.tmp" 2>nul
)
if not "%DETECTED_IP%"=="" set "WIFI_IP=%DETECTED_IP%"
exit /b 0

:set_ip_manual
echo.
echo Текущий IP: %WIFI_IP%
set "new_ip="
set /p "new_ip=Введите новый IP адрес телефона: "
if not "%new_ip%"=="" set "WIFI_IP=%new_ip%"
goto menu

:setup_tcpip
cls
echo ================================================================
echo   Активация беспроводного режима Wi-Fi (Порт 5555)
echo ================================================================
echo.
echo 1. Подключите телефон кабелем USB к компьютеру.
echo 2. Разблокируйте экран телефона.
echo.
pause
echo.
echo [ADB] Перезапуск службы adbd в режиме TCP/IP...
adb -d tcpip 5555
if %errorlevel% neq 0 (
    echo [ОШИБКА] Не удалось перевести телефон в режим TCP/IP.
    echo Проверьте подключение кабеля USB и статус отладки.
    pause
    goto menu
)
call :detect_ip
echo.
echo [УСПЕХ] Режим Wi-Fi активирован на порту 5555!
echo Определен IP адрес: %WIFI_IP%
echo Теперь можно отсоединить USB-кабель и выбирать пункт 2.
echo.
pause
goto menu

:setup_keyboard
cls
echo ================================================================
echo   Настройка раскладки физической клавиатуры (RU / EN)
echo ================================================================
echo.
echo Открытие экрана настроек физической клавиатуры на телефоне...
adb -d shell am start -a android.settings.HARD_KEYBOARD_SETTINGS <nul >nul 2>&1 || adb -s %WIFI_IP%:5555 shell am start -a android.settings.HARD_KEYBOARD_SETTINGS <nul >nul 2>&1 || adb shell am start -a android.settings.HARD_KEYBOARD_SETTINGS <nul >nul 2>&1
echo.
echo В настройках на телефоне выберите физическую клавиатуру и добавьте:
echo   1. Русский (Русская)
echo   2. Английский (США)
echo Переключение раскладок выполняется по Ctrl+Пробел или Shift+Пробел.
echo.
pause
goto menu

:detect_launcher
:: Принимает все переданные аргументы (%*) для adb
set "TARGET_FLAGS=%*"
set "APP_FLAG="
del "%TEMP%\a55_pkg.tmp" 2>nul
adb %TARGET_FLAGS% shell pm list packages --user 0 ginlemon.flowerfree <nul > "%TEMP%\a55_pkg.tmp" 2>nul
findstr /c:"package:ginlemon.flowerfree" "%TEMP%\a55_pkg.tmp" >nul 2>&1
if %errorlevel% equ 0 (
    set "APP_FLAG=--start-app=+ginlemon.flowerfree"
    del "%TEMP%\a55_pkg.tmp" 2>nul
    exit /b 0
)
adb %TARGET_FLAGS% shell pm list packages --user 0 com.farmerbb.taskbar <nul > "%TEMP%\a55_pkg.tmp" 2>nul
findstr /c:"package:com.farmerbb.taskbar" "%TEMP%\a55_pkg.tmp" >nul 2>&1
if %errorlevel% equ 0 (
    set "APP_FLAG=--start-app=+com.farmerbb.taskbar"
    del "%TEMP%\a55_pkg.tmp" 2>nul
    exit /b 0
)
del "%TEMP%\a55_pkg.tmp" 2>nul
exit /b 0

:prepare_device
:: Принимает все переданные аргументы (%*) для adb
set "TARGET_FLAGS=%*"
adb %TARGET_FLAGS% shell settings put global enable_freeform_support 1 <nul >nul 2>&1
adb %TARGET_FLAGS% shell settings put global force_desktop_mode_on_external_displays 1 <nul >nul 2>&1
adb %TARGET_FLAGS% shell settings put global enable_non_resizable_multi_window 1 <nul >nul 2>&1
adb %TARGET_FLAGS% shell settings put secure desktop_mode 1 <nul >nul 2>&1
exit /b 0

:build_params
set "AUDIO_FLAG="
if "%AUDIO_MODE%"=="phone" set "AUDIO_FLAG=--no-audio"
set "MOUSE_FLAG=--mouse=sdk"
if "%MOUSE_MODE%"=="uhid" set "MOUSE_FLAG=--mouse=uhid"
set "FULLSCREEN_FLAG="
if "%WINDOW_MODE%"=="fullscreen" set "FULLSCREEN_FLAG=--fullscreen"
set "SHORTCUT_FLAG="
if "%SHORTCUT_MODE%"=="ctrl" set "SHORTCUT_FLAG=--shortcut-mod=lctrl,lalt"
exit /b 0

:start_usb
cls
echo ================================================================
echo   Запуск Samsung DeX Pro по USB...
echo ================================================================
echo.
adb -d get-state >nul 2>&1
if %errorlevel% neq 0 (
    echo [ОШИБКА] Телефон не обнаружен по USB!
    echo Проверьте подключение кабеля и разрешение на отладку.
    pause
    goto menu
)
call :prepare_device -d
call :detect_launcher -d
call :build_params

echo Запуск рабочего стола DeX...
scrcpy -d --new-display=%RES% --video-codec=%CODEC% --video-encoder=%ENCODER% --video-bit-rate=%BITRATE% --max-fps=%FPS% --keyboard=uhid %MOUSE_FLAG% %AUDIO_FLAG% %FULLSCREEN_FLAG% %SHORTCUT_FLAG% --turn-screen-off --stay-awake --window-title="Samsung DeX (Galaxy A55)" %APP_FLAG%
goto post_run

:start_wifi
cls
echo ================================================================
echo   Запуск Samsung DeX Pro по Wi-Fi (%WIFI_IP%:5555)...
echo ================================================================
echo.
adb connect %WIFI_IP%:5555 >nul 2>&1
ping -n 2 127.0.0.1 >nul
adb -s %WIFI_IP%:5555 get-state >nul 2>&1
if %errorlevel% neq 0 (
    echo [ОШИБКА] Не удалось подключиться к %WIFI_IP%:5555.
    echo.
    echo Попытка автоматической переактивации через USB...
    adb -d get-state >nul 2>&1
    if !errorlevel! equ 0 (
        echo Обнаружен телефон по USB! Активация TCP/IP...
        adb -d tcpip 5555 >nul 2>&1
        ping -n 2 127.0.0.1 >nul
        call :detect_ip
        adb connect !WIFI_IP!:5555 >nul 2>&1
    )
    adb -s !WIFI_IP!:5555 get-state >nul 2>&1
    if !errorlevel! neq 0 (
        echo Не удалось подключиться. Проверьте сеть или используйте пункт 4.
        pause
        goto menu
    )
)
call :prepare_device -s %WIFI_IP%:5555
call :detect_launcher -s %WIFI_IP%:5555
call :build_params

echo Запуск беспроводного рабочего стола DeX...
scrcpy -s %WIFI_IP%:5555 --new-display=%RES% --video-codec=%CODEC% --video-encoder=%ENCODER% --video-bit-rate=%BITRATE% --max-fps=%FPS% --keyboard=uhid %MOUSE_FLAG% %AUDIO_FLAG% %FULLSCREEN_FLAG% %SHORTCUT_FLAG% --turn-screen-off --stay-awake --window-title="Samsung DeX Wireless (Galaxy A55)" %APP_FLAG%
goto post_run

:post_run
echo.
echo ================================================================
echo   Сессия Samsung DeX завершена.
echo ================================================================
echo.
echo  1 - Главное меню
echo  2 - Выход
set "post_choice="
set /p "post_choice=Выбор: "
if "%post_choice%"=="1" goto menu
exit /b 0

:settings_menu
cls
echo ================================================================
echo                       Параметры DeX
echo ================================================================
echo.
echo  [Разрешение экрана]
echo  1 - 1080p (1920x1080 / 160 DPI) [По умолчанию, четкий 1:1]
echo  2 - 2K QHD (2560x1440 / 200 DPI) [Для 2K-мониторов]
echo  3 - 900p (1600x900 / 140 DPI) [Для слабого Wi-Fi]
echo.
echo  [Аудио-поток]
echo  4 - Звук на ПК (Opus / динамики компьютера)
echo  5 - Звук на телефоне / Galaxy Buds по Bluetooth (--no-audio)
echo.
echo  [Курсор мыши]
echo  6 - Режим SDK (Бесшовный курсор Windows, свободный выход из окна)
echo  7 - Режим UHID (Аппаратный курсор Android, захват мыши, выход по Alt)
echo.
echo  [Режим окна]
echo  8 - Оконный режим (Удобно для многозадачности с Windows)
echo  9 - Полноэкранный режим (Погружение в Samsung DeX)
echo.
echo  [Шорткаты]
echo  A - Безопасный режим: Win/Alt (Не конфликтует с Ctrl+S, Ctrl+Z в программах)
echo  B - Режим Ctrl (Ctrl+B, Ctrl+H, Ctrl+S)
echo.
echo  0 - Назад в главное меню
echo ================================================================
set "s_choice="
set /p "s_choice=Выберите опцию: "

if "%s_choice%"=="1" set "RES=1920x1080/160"
if "%s_choice%"=="2" set "RES=2560x1440/200"
if "%s_choice%"=="3" set "RES=1600x900/140"
if "%s_choice%"=="4" set "AUDIO_MODE=pc"
if "%s_choice%"=="5" set "AUDIO_MODE=phone"
if "%s_choice%"=="6" set "MOUSE_MODE=sdk"
if "%s_choice%"=="7" set "MOUSE_MODE=uhid"
if "%s_choice%"=="8" set "WINDOW_MODE=window"
if "%s_choice%"=="9" set "WINDOW_MODE=fullscreen"
if /i "%s_choice%"=="A" set "SHORTCUT_MODE=safe"
if /i "%s_choice%"=="B" set "SHORTCUT_MODE=ctrl"
if "%s_choice%"=="0" goto menu
goto settings_menu

:make_shortcut
echo.
echo [ЯРЛЫК] Создание ярлыков на Рабочем столе Windows...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRCPY_DIR%\create_shortcuts.ps1"
if %errorlevel% equ 0 (
    echo [УСПЕХ] Ярлыки 'Samsung DeX' и 'Samsung DeX (USB Fast)' успешно созданы на Рабочем столе!
) else (
    echo [ОШИБКА] Не удалось создать ярлыки.
)
pause
goto menu
