@echo off
chcp 65001 >nul
title Публикация Samsung DeX Pro на GitHub

set "PATH=D:\programs\git\cmd;%PATH%"
cd /d "%~dp0"

echo ================================================================
echo       Публикация проекта Samsung DeX Pro на GitHub
echo ================================================================
echo.

:: Проверка авторизации через GitHub CLI
gh auth status >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Требуется однократный вход в GitHub.
    echo Сейчас запустится быстрая авторизация в браузере...
    echo.
    gh auth login -h github.com -p https -w
    if %errorlevel% neq 0 (
        echo [ОШИБКА] Авторизация не завершена.
        pause
        exit /b 1
    )
)

echo.
echo [1/3] Проверка и создание репозитория на GitHub (dizofdx/dex)...
gh repo create dex --public --source=. --description "Samsung DeX Pro for Galaxy A55 (Android 16 / One UI 8.5) via Scrcpy and Freeform" >nul 2>&1
if %errorlevel% equ 0 (
    echo [УСПЕХ] Репозиторий успешно создан на GitHub!
) else (
    echo Репозиторий уже существует или настроен.
)

echo.
echo [2/3] Настройка ветки main...
git branch -M main

echo.
echo [3/3] Отправка файлов в репозиторий...
git push -u origin main
if %errorlevel% equ 0 (
    echo.
    echo ================================================================
    echo [УСПЕХ] Проект опубликован: https://github.com/dizofdx/dex
    echo ================================================================
) else (
    echo.
    echo [!] Проверьте права доступа или создайте репозиторий https://github.com/new
)

echo.
pause
