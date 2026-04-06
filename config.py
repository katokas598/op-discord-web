import json
import os


def load_config():
    config_path = os.path.join(os.path.dirname(__file__), "config.json")

    if not os.path.exists(config_path):
        print(">>> config.json не найден!")
        print(">>> Запустите python setup.py для настройки бота")
        exit(1)

    with open(config_path, "r", encoding="utf-8") as f:
        return json.load(f)


CONFIG = load_config()

DISCORD_TOKEN = CONFIG.get("discord_token", "")
PREFIX = CONFIG.get("prefix", "!")
ADMIN_IDS = CONFIG.get("admin_ids", [])
GUILD_ID = CONFIG.get("guild_id", "")
TICKET_CATEGORIES = CONFIG.get(
    "ticket_categories", ["Техподдержка", "Жалобы", "Предложения", "Другое"]
)
DASHBOARD_DOMAIN = CONFIG.get("dashboard_domain", "")
DASHBOARD_LOGIN_URL = CONFIG.get("dashboard_login_url", "")
DASHBOARD_HOST = CONFIG.get("dashboard_host", "0.0.0.0")
DASHBOARD_PORT = CONFIG.get("dashboard_port", 8000)
DASHBOARD_BASE_URL = DASHBOARD_LOGIN_URL or (f"https://{DASHBOARD_DOMAIN}" if DASHBOARD_DOMAIN else "")

