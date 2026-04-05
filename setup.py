import os
import json
import subprocess
import sys


def setup():
    print("\n" + "=" * 50)
    print("   НАСТРОЙКА DISCORDSER BOT")
    print("=" * 50 + "\n")

    config = {}

    print("📝 Введите данные для настройки:\n")

    print("1. Discord бот:")
    config["discord_token"] = input("   Токен Discord бота: ").strip()

    print("\n2. Настройки бота:")
    config["prefix"] = input("   Префикс команд (по умолчанию !): ").strip() or "!"

    print("\n3. Администраторы (если нужны для ограниченного доступа к панели):")
    admins_input = input("   ID администраторов через запятую: ").strip()
    config["admin_ids"] = [
        int(x.strip()) for x in admins_input.split(",") if x.strip().isdigit()
    ]

    print("\n4. ID Discord сервера (для тикетов):")
    config["guild_id"] = input("   ID сервера: ").strip()

    print("\n5. Категории тикетов (через запятую):")
    default_categories = "Техподдержка,Жалобы,Предложения,Другое"
    categories_input = input(f"   ({default_categories}): ").strip()
    config["ticket_categories"] = (
        categories_input.split(",")
        if categories_input
        else default_categories.split(",")
    )

    config["ticket_categories"] = [c.strip() for c in config["ticket_categories"]]

    with open("config.json", "w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=2)

    print("\n" + "=" * 50)
    print("✅ Настройки сохранены в config.json")
    print("=" * 50)
    print("\n📝 Для запуска бота используйте: python main.py")
    print("\n⚠️  Не забудьте добавить бота на сервер с нужными правами!")

    start_now = input("\nЗапустить бота сейчас? (y/n): ").strip().lower()
    if start_now == "y":
        subprocess.run([sys.executable, "main.py"])


if __name__ == "__main__":
    setup()
