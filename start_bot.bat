@echo off
chcp 65001 > nul
echo ===================================================
echo            DISCORDSER BOT v2.0
echo ===================================================
echo.

if not exist "config.json" (
    echo [ERROR] config.json не найден!
    echo [INFO] Запускаем setup.py для первоначальной настройки...
    echo.
    python setup.py
    pause
    goto :eof
)

echo [INFO] Конфигурация найдена
echo [INFO] Проверяем зависимости...

python -c "import discord; print('[OK] discord.py установлен')" 2>nul || (
    echo [ERROR] discord.py не установлен!
    echo [INFO] Устанавливаем зависимости...
    pip install -r requirements.txt
)

echo.
echo [INFO] Запуск бота...
echo [INFO] Для остановки нажмите Ctrl+C
echo.

REM ===== ЗАПУСК БОТА С ОБРАБОТКОЙ ОШИБОК =====
python main.py
set ERRORLEVEL_RESULT=%ERRORLEVEL%

if %ERRORLEVEL_RESULT% NEQ 0 (
    echo.
    echo ============================================
    echo [ERROR] Бот завершился с ошибкой ^(код %ERRORLEVEL_RESULT%^)!
    echo.
    echo Возможные причины:
    echo 1. Неверный Discord токен в config.json
    echo 2. Токен является плейсхолдером "YOUR_DISCORD_TOKEN_HERE"
    echo 3. Неверный ID сервера ^(guild_id^)
    echo 4. Отсутствует интернет-соединение
    echo 5. Бот не добавлен на Discord сервер
    echo.
    echo Что делать:
    echo - Откройте config.json и проверьте настройки
    echo - Запустите setup.py для пересоздания конфигурации
    echo - Убедитесь что бот добавлен на сервер с нужными правами
    echo ============================================
    echo.
) else (
    echo.
    echo [INFO] Бот завершил работу корректно
)

echo [INFO] Нажмите любую клавишу для выхода...
pause > nul