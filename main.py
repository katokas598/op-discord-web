import asyncio
import json
import os
import sys


def validate_config_values():
    """Проверяет что config.json содержит реальные значения, а не плейсхолдеры"""
    config_path = os.path.join(os.path.dirname(__file__), "config.json")

    if not os.path.exists(config_path):
        return False, "config.json не найден"

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
    except json.JSONDecodeError:
        return False, "config.json поврежден или содержит неверный JSON"

    # Проверка токена
    token = config.get("discord_token", "")
    if not token or token in ["", "YOUR_DISCORD_TOKEN_HERE", "YOUR_TOKEN_HERE"]:
        return False, "Discord токен не настроен или является плейсхолдером"

    # Проверка ID сервера
    guild_id = config.get("guild_id", "")
    if not guild_id or guild_id in ["", "YOUR_GUILD_ID_HERE", "YOUR_SERVER_ID_HERE"]:
        return False, "ID сервера (guild_id) не настроен или является плейсхолдером"

    return True, "Конфигурация корректна"


def check_config():
    config_path = os.path.join(os.path.dirname(__file__), "config.json")

    if not os.path.exists(config_path):
        print("\n" + "=" * 50)
        print("   ПЕРВЫЙ ЗАПУСК - НАСТРОЙКА БОТА")
        print("=" * 50 + "\n")
        print(">>> Запустите: python setup.py")
        print("\nДля настройки конфигурации.")
        return False

    # Проверка базового содержимого
    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)

    required = ["discord_token"]
    missing = [key for key in required if not config.get(key)]

    if missing:
        print(f"\n>>> Отсутствуют настройки: {', '.join(missing)}")
        print(">>> Запустите: python setup.py")
        return False

    # Проверка на плейсхолдеры
    is_valid, message = validate_config_values()
    if not is_valid:
        print(f"\n>>> ПРОБЛЕМА С КОНФИГУРАЦИЕЙ: {message}")
        print("\n>>> РЕШЕНИЕ:")
        print("1. Откройте config.json в текстовом редакторе")
        print("2. Замените 'YOUR_DISCORD_TOKEN_HERE' на реальный токен Discord бота")
        print("3. Замените 'YOUR_GUILD_ID_HERE' на реальный ID вашего сервера")
        print("4. Или запустите: python setup.py для пересоздания конфигурации")
        print("\n>>> КАК ПОЛУЧИТЬ ТОКЕН:")
        print("- Откройте https://discord.com/developers/applications")
        print("- Создайте приложение → Bot → Reset Token → Copy")
        print("\n>>> КАК ПОЛУЧИТЬ ID СЕРВЕРА:")
        print("- В Discord: Settings → Advanced → Developer Mode (включить)")
        print("- Правый клик на сервер → Copy Server ID")
        return False

    return True


async def run_discord():
    from discord_bot.bot import run_bot
    from config import DISCORD_TOKEN

    print(">>> Запуск Discord бота...")
    await run_bot(DISCORD_TOKEN)


async def main():
    if not check_config():
        return

    import database

    database.init_db()

    print("\n" + "=" * 50)
    print("   DISCORDSER BOT ЗАПУЩЕН")
    print("=" * 50 + "\n")

    await run_discord()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n>>> Бот остановлен пользователем")
    except ImportError as e:
        print(f"\n>>> ОШИБКА ИМПОРТА: {e}")
        print("\n>>> РЕШЕНИЕ:")
        print("- Установите зависимости: pip install -r requirements.txt")
        print("- Проверьте что Python 3.8+ установлен")
        input("\n>>> Нажмите Enter для выхода...")
        sys.exit(1)
    except Exception as e:
        error_type = type(e).__name__
        error_message = str(e)

        print(f"\n>>> КРИТИЧЕСКАЯ ОШИБКА ЗАПУСКА БОТА:")
        print(f">>> {error_type}: {error_message}")

        # Специальная обработка ошибок Discord
        if "LoginFailure" in error_type or "Improper token" in error_message:
            print("\n>>> ПРОБЛЕМА: Неверный Discord токен")
            print("\n>>> РЕШЕНИЕ:")
            print("1. Проверьте config.json - токен не должен быть 'YOUR_DISCORD_TOKEN_HERE'")
            print("2. Получите новый токен на https://discord.com/developers/applications")
            print("3. Убедитесь что токен скопирован полностью без лишних символов")
            print("4. Перезапустите setup.py для повторной настройки")
        elif "Unauthorized" in error_message or "401" in error_message:
            print("\n>>> ПРОБЛЕМА: Discord API отклонил токен (401 Unauthorized)")
            print("\n>>> РЕШЕНИЕ:")
            print("1. Токен истек или неверен - получите новый")
            print("2. Проверьте что бот включен в Discord Developer Portal")
        elif "Forbidden" in error_message or "403" in error_message:
            print("\n>>> ПРОБЛЕМА: Бот не имеет прав на сервере (403 Forbidden)")
            print("\n>>> РЕШЕНИЕ:")
            print("1. Добавьте бота на сервер с нужными правами")
            print("2. Проверьте что роль бота выше модерируемых ролей")
        else:
            print("\n>>> ОБЩИЕ РЕШЕНИЯ:")
            print("1. Проверьте config.json на корректность всех настроек")
            print("2. Запустите setup.py для пересоздания конфигурации")
            print("3. Убедитесь в стабильности интернет-соединения")

        print(f"\n>>> Подробная ошибка сохранена в логи")
        input("\n>>> Нажмите Enter для выхода...")
        sys.exit(1)
