@echo off
chcp 65001 > nul
echo ===================================================
echo           DISCORDSER BOT - WEB ПАНЕЛЬ
echo ===================================================
echo.

if not exist "config.json" (
    echo [ERROR] config.json не найден!
    echo [INFO] Сначала запустите start_bot.bat для настройки
    pause
    goto :eof
)

echo [INFO] Запуск web-панели управления...
echo [INFO] Панель будет доступна на http://localhost:8000
echo [INFO] Для остановки нажмите Ctrl+C
echo.

python dashboard_server.py --no-prompt
pause