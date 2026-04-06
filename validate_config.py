#!/usr/bin/env python3
"""
Утилита для проверки и валидации config.json
Проверяет что конфигурация содержит реальные значения, а не плейсхолдеры
"""

import json
import os
import re
import sys


def load_config():
    """Загружает конфигурацию из config.json"""
    config_path = "config.json"

    if not os.path.exists(config_path):
        return None, "Файл config.json не найден"

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
        return config, None
    except json.JSONDecodeError as e:
        return None, f"Ошибка чтения JSON: {e}"
    except Exception as e:
        return None, f"Ошибка загрузки файла: {e}"


def validate_discord_token(token):
    """Проверяет формат Discord токена"""
    if not token or not isinstance(token, str):
        return False, "Токен пустой или не является строкой"

    # Плейсхолдеры
    placeholders = [
        "YOUR_DISCORD_TOKEN_HERE",
        "YOUR_TOKEN_HERE",
        "DISCORD_TOKEN",
        "PUT_YOUR_TOKEN_HERE",
        "REPLACE_WITH_YOUR_TOKEN"
    ]

    if token.upper() in [p.upper() for p in placeholders]:
        return False, "Токен является плейсхолдером - замените на реальный токен"

    # Базовая проверка формата Discord токена
    if len(token) < 50:
        return False, "Токен слишком короткий (должен быть 59+ символов)"

    # Discord токены обычно содержат только определенные символы
    if not re.match(r'^[A-Za-z0-9._-]+$', token):
        return False, "Токен содержит недопустимые символы"

    return True, "Формат токена выглядит корректно"


def validate_guild_id(guild_id):
    """Проверяет формат ID Discord сервера"""
    if not guild_id:
        return False, "ID сервера не указан"

    # Плейсхолдеры
    placeholders = [
        "YOUR_GUILD_ID_HERE",
        "YOUR_SERVER_ID_HERE",
        "GUILD_ID",
        "SERVER_ID",
        "PUT_YOUR_GUILD_ID_HERE"
    ]

    guild_str = str(guild_id).upper()
    if guild_str in [p.upper() for p in placeholders]:
        return False, "ID сервера является плейсхолдером - замените на реальный ID"

    # Проверка что это число
    try:
        guild_id_int = int(guild_id)
    except (ValueError, TypeError):
        return False, "ID сервера должен быть числом"

    # Discord ID обычно 17-19 цифр
    if len(str(guild_id_int)) < 15:
        return False, "ID сервера слишком короткий (должен быть 15+ цифр)"

    return True, "Формат ID сервера выглядит корректно"


def validate_config(config):
    """Проверяет всю конфигурацию"""
    errors = []
    warnings = []

    # Проверка токена
    token = config.get("discord_token", "")
    is_valid, message = validate_discord_token(token)
    if not is_valid:
        errors.append(f"Discord Token: {message}")

    # Проверка ID сервера
    guild_id = config.get("guild_id", "")
    is_valid, message = validate_guild_id(guild_id)
    if not is_valid:
        errors.append(f"Guild ID: {message}")

    # Проверка префикса
    prefix = config.get("prefix", "!")
    if not prefix:
        warnings.append("Префикс команд пустой, будет использован '!'")
    elif len(prefix) > 3:
        warnings.append("Префикс команд слишком длинный (рекомендуется 1-2 символа)")

    # Проверка категорий тикетов
    categories = config.get("ticket_categories", [])
    if not isinstance(categories, list) or not categories:
        warnings.append("Категории тикетов не настроены или неверного формата")

    # Проверка админов
    admin_ids = config.get("admin_ids", [])
    if not isinstance(admin_ids, list):
        warnings.append("Список admin_ids должен быть массивом")

    return errors, warnings


def print_validation_results(errors, warnings):
    """Выводит результаты валидации"""
    if not errors and not warnings:
        print("✅ КОНФИГУРАЦИЯ КОРРЕКТНА")
        print("   Все настройки выглядят правильно!")
        return True

    if errors:
        print("❌ КРИТИЧЕСКИЕ ОШИБКИ:")
        for error in errors:
            print(f"   • {error}")
        print()

    if warnings:
        print("⚠️  ПРЕДУПРЕЖДЕНИЯ:")
        for warning in warnings:
            print(f"   • {warning}")
        print()

    return len(errors) == 0


def print_help():
    """Выводит справку по получению токена и ID"""
    print("📖 КАК ИСПРАВИТЬ КОНФИГУРАЦИЮ:")
    print()
    print("🔑 Получение Discord токена:")
    print("   1. Откройте https://discord.com/developers/applications")
    print("   2. Создайте новое приложение (New Application)")
    print("   3. Перейдите в раздел 'Bot' слева")
    print("   4. Нажмите 'Add Bot' если бота еще нет")
    print("   5. В разделе 'Token' нажмите 'Reset Token'")
    print("   6. Скопируйте токен и вставьте в config.json")
    print()
    print("🏠 Получение ID сервера:")
    print("   1. В Discord включите режим разработчика:")
    print("      Settings → Advanced → Developer Mode")
    print("   2. Правый клик по названию сервера")
    print("   3. Выберите 'Copy Server ID'")
    print("   4. Вставьте ID в config.json в поле guild_id")
    print()
    print("🔧 Или запустите setup.py для автоматической настройки:")
    print("   python setup.py")


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Валидация конфигурации DiscordSer Bot")
    parser.add_argument("--silent", action="store_true",
                       help="Тихий режим - выводить только ошибки")

    args = parser.parse_args()

    if not args.silent:
        print("=" * 60)
        print("          ВАЛИДАЦИЯ КОНФИГУРАЦИИ DISCORDSER BOT")
        print("=" * 60)
        print()

    # Загрузка конфигурации
    config, error = load_config()
    if error:
        if not args.silent:
            print(f"❌ ОШИБКА ЗАГРУЗКИ: {error}")
            print()
            if "не найден" in error:
                print("💡 РЕШЕНИЕ: Запустите python setup.py для создания конфигурации")
        return False

    # Валидация
    if not args.silent:
        print("🔍 Проверяем конфигурацию...")
        print()

    errors, warnings = validate_config(config)
    is_valid = print_validation_results(errors, warnings) if not args.silent else len(errors) == 0

    if not is_valid and not args.silent:
        print()
        print_help()

    return is_valid


if __name__ == "__main__":
    success = main()

    if not "--silent" in sys.argv:
        print()
        if success:
            print("🚀 Конфигурация готова к использованию!")
        else:
            print("🛠️  Исправьте ошибки и запустите проверку заново")

        input("\nНажмите Enter для выхода...")

    sys.exit(0 if success else 1)