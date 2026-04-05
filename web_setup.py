import json
import os
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

BASE_DIR = os.path.dirname(__file__)
CONFIG_PATH = os.path.join(BASE_DIR, "config.json")


def load_config():
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return {
        "discord_token": "",
        "prefix": "!",
        "admin_ids": [],
        "guild_id": "",
        "ticket_categories": ["Техподдержка", "Жалобы", "Предложения", "Другое"],
        "ticket_roles": [],
        "max_warns": 3,
    }


def save_config(data):
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


class Handler(SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/save-config":
            self.send_error(404)
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode("utf-8")
        payload = parse_qs(body)

        config = load_config()
        config["discord_token"] = payload.get("discord_token", [""])[0].strip()
        config["prefix"] = payload.get("prefix", ["!"])[0].strip() or "!"
        config["guild_id"] = payload.get("guild_id", [""])[0].strip()
        config["max_warns"] = int(payload.get("max_warns", ["3"])[0] or 3)
        config["admin_ids"] = [
            int(x.strip()) for x in payload.get("admin_ids", [""])[0].split(",") if x.strip().isdigit()
        ]
        config["ticket_roles"] = [
            int(x.strip()) for x in payload.get("ticket_roles", [""])[0].split(",") if x.strip().isdigit()
        ]
        categories = payload.get("ticket_categories", [""])[0]
        config["ticket_categories"] = [c.strip() for c in categories.split(",") if c.strip()] or config["ticket_categories"]

        save_config(config)
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.end_headers()
        self.wfile.write(json.dumps({"ok": True}).encode("utf-8"))


if __name__ == "__main__":
    os.chdir(BASE_DIR)
    server = ThreadingHTTPServer(("0.0.0.0", 8000), Handler)
    print("Server running on http://localhost:8000")
    server.serve_forever()
