# 🐧 Установка DiscordSer Bot на Ubuntu Server

## 📋 Предварительные требования

- Ubuntu 20.04 LTS или новее
- Права sudo
- Интернет соединение

## 🚀 Быстрая установка (одна команда)

```bash
curl -sSL https://raw.githubusercontent.com/your-repo/bot-2.0-main/main/install_ubuntu.sh | sudo bash
```

## 📖 Ручная установка (пошагово)

### 1. Обновление системы

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Установка Python и зависимостей

```bash
# Установка Python 3.8+
sudo apt install python3 python3-pip python3-venv git curl -y

# Проверка версии Python
python3 --version  # должно быть 3.8+
```

### 3. Создание пользователя для бота (рекомендуется)

```bash
# Создание пользователя discordbot
sudo useradd -m -s /bin/bash discordbot

# Переключение на пользователя бота
sudo su - discordbot
```

### 4. Скачивание исходного кода

```bash
# Клонирование репозитория (если есть git репозиторий)
git clone https://github.com/your-repo/bot-2.0-main.git
cd bot-2.0-main

# ИЛИ загрузка архива
wget https://github.com/your-repo/bot-2.0-main/archive/main.zip
unzip main.zip
cd bot-2.0-main-main
```

**Альтернативно**: Скопируйте файлы с Windows машины через SCP:
```bash
# На Windows (в PowerShell)
scp -r "F:\bot-2.0-main" username@your-server-ip:/home/discordbot/

# На Ubuntu
sudo chown -R discordbot:discordbot /home/discordbot/bot-2.0-main
```

### 5. Создание виртуального окружения

```bash
cd /home/discordbot/bot-2.0-main

# Создание venv
python3 -m venv venv

# Активация
source venv/bin/activate

# Обновление pip
pip install --upgrade pip
```

### 6. Установка Python зависимостей

```bash
# Установка из requirements.txt
pip install -r requirements.txt

# Если нужны дополнительные пакеты для production
pip install gunicorn supervisor
```

### 7. Настройка конфигурации

```bash
# Запуск мастера настройки
python setup.py

# ИЛИ ручное создание config.json
cat > config.json << 'EOF'
{
  "discord_token": "ВАШ_DISCORD_TOKEN",
  "prefix": "!",
  "guild_id": "ID_ВАШЕГО_СЕРВЕРА",
  "admin_ids": [123456789],
  "max_warns": 3,
  "ticket_categories": ["Техподдержка", "Жалобы", "Предложения", "Другое"],
  "dashboard_domain": "your-domain.com",
  "dashboard_host": "0.0.0.0",
  "dashboard_port": 8000
}
EOF
```

### 8. Проверка работоспособности

```bash
# Проверка конфигурации
python validate_config.py

# Тестовый запуск бота
python main.py

# В другом терминале: тест панели
python dashboard_server.py --no-prompt
```

## 🔧 Настройка как systemd сервисов

### 1. Создание systemd unit для бота

```bash
sudo nano /etc/systemd/system/discordbot.service
```

Содержимое файла:
```ini
[Unit]
Description=DiscordSer Bot
After=network.target

[Service]
Type=simple
User=discordbot
Group=discordbot
WorkingDirectory=/home/discordbot/bot-2.0-main
Environment=PATH=/home/discordbot/bot-2.0-main/venv/bin
ExecStart=/home/discordbot/bot-2.0-main/venv/bin/python main.py
Restart=always
RestartSec=10

# Логирование
StandardOutput=journal
StandardError=journal
SyslogIdentifier=discordbot

[Install]
WantedBy=multi-user.target
```

### 2. Создание systemd unit для dashboard

```bash
sudo nano /etc/systemd/system/discordbot-dashboard.service
```

Содержимое файла:
```ini
[Unit]
Description=DiscordSer Bot Dashboard
After=network.target discordbot.service
Requires=discordbot.service

[Service]
Type=simple
User=discordbot
Group=discordbot
WorkingDirectory=/home/discordbot/bot-2.0-main
Environment=PATH=/home/discordbot/bot-2.0-main/venv/bin
ExecStart=/home/discordbot/bot-2.0-main/venv/bin/python dashboard_server.py --no-prompt
Restart=always
RestartSec=10

# Логирование
StandardOutput=journal
StandardError=journal
SyslogIdentifier=discordbot-dashboard

[Install]
WantedBy=multi-user.target
```

### 3. Включение и запуск сервисов

```bash
# Перезагрузка systemd
sudo systemctl daemon-reload

# Включение автозапуска
sudo systemctl enable discordbot.service
sudo systemctl enable discordbot-dashboard.service

# Запуск сервисов
sudo systemctl start discordbot.service
sudo systemctl start discordbot-dashboard.service

# Проверка статуса
sudo systemctl status discordbot.service
sudo systemctl status discordbot-dashboard.service
```

## 🌐 Настройка Nginx (для публичного доступа к панели)

### 1. Установка Nginx

```bash
sudo apt install nginx -y
```

### 2. Создание конфигурации

```bash
sudo nano /etc/nginx/sites-available/discordbot-dashboard
```

Содержимое:
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Для статических файлов (если есть)
    location /static/ {
        alias /home/discordbot/bot-2.0-main/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 3. Включение конфигурации

```bash
# Создание симлинка
sudo ln -s /etc/nginx/sites-available/discordbot-dashboard /etc/nginx/sites-enabled/

# Проверка конфигурации
sudo nginx -t

# Перезапуск Nginx
sudo systemctl restart nginx
```

### 4. Настройка SSL с Let's Encrypt (опционально)

```bash
# Установка certbot
sudo apt install certbot python3-certbot-nginx -y

# Получение сертификата
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Автообновление сертификатов
sudo crontab -e
# Добавить: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🔥 Настройка firewall

```bash
# Включение UFW
sudo ufw enable

# Разрешение SSH
sudo ufw allow ssh

# Разрешение HTTP и HTTPS
sudo ufw allow 80
sudo ufw allow 443

# Проверка статуса
sudo ufw status
```

## 📊 Мониторинг и логи

### Просмотр логов

```bash
# Логи бота
sudo journalctl -u discordbot.service -f

# Логи dashboard
sudo journalctl -u discordbot-dashboard.service -f

# Логи Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Полезные команды

```bash
# Перезапуск сервисов
sudo systemctl restart discordbot.service
sudo systemctl restart discordbot-dashboard.service

# Остановка сервисов
sudo systemctl stop discordbot.service
sudo systemctl stop discordbot-dashboard.service

# Проверка статуса
sudo systemctl status discordbot.service
sudo systemctl status discordbot-dashboard.service

# Просмотр процессов
ps aux | grep python
```

## 🔄 Обновление бота

```bash
# Переход к папке бота
cd /home/discordbot/bot-2.0-main

# Остановка сервисов
sudo systemctl stop discordbot.service discordbot-dashboard.service

# Обновление кода (если есть git)
git pull origin main

# Или замена файлов
# scp -r "F:\bot-2.0-main\*" username@server:/home/discordbot/bot-2.0-main/

# Активация venv
source venv/bin/activate

# Обновление зависимостей
pip install -r requirements.txt --upgrade

# Запуск сервисов
sudo systemctl start discordbot.service discordbot-dashboard.service
```

## 📁 Структура файлов на сервере

```
/home/discordbot/bot-2.0-main/
├── venv/                     # Виртуальное окружение Python
├── discord_bot/
│   ├── __init__.py
│   └── bot.py
├── main.py                   # Основной файл бота
├── dashboard_server.py       # Web панель
├── config.json              # Конфигурация (создается при установке)
├── bot.db                   # База данных SQLite (создается автоматически)
├── requirements.txt         # Python зависимости
├── setup.py                # Мастер настройки
├── validate_config.py      # Проверка конфигурации
├── start_bot.sh           # Bash скрипт запуска
├── start_dashboard.sh     # Bash скрипт панели
└── install_ubuntu.sh      # Скрипт автоустановки
```

## ❓ Устранение неполадок

### Проблема: Бот не запускается

```bash
# Проверка логов
sudo journalctl -u discordbot.service --no-pager -l

# Проверка конфигурации
cd /home/discordbot/bot-2.0-main
source venv/bin/activate
python validate_config.py

# Ручной запуск для диагностики
python main.py
```

### Проблема: Dashboard недоступен

```bash
# Проверка что сервис запущен
sudo systemctl status discordbot-dashboard.service

# Проверка портов
sudo netstat -tulpn | grep :8000

# Проверка Nginx
sudo nginx -t
sudo systemctl status nginx
```

### Проблема: Недостаточно прав

```bash
# Исправление владельца файлов
sudo chown -R discordbot:discordbot /home/discordbot/bot-2.0-main

# Установка прав на выполнение
chmod +x /home/discordbot/bot-2.0-main/*.sh
```

## 🔐 Безопасность

1. **Никогда не запускайте бота от root**
2. **Используйте отдельного пользователя (discordbot)**  
3. **Настройте firewall (ufw)**
4. **Используйте SSL для панели управления**
5. **Регулярно обновляйте систему**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

## 💡 Полезные советы

- **Резервное копирование**: Регулярно делайте backup файла `config.json` и `bot.db`
- **Мониторинг**: Настройте alerting при падении сервисов
- **Логирование**: Настройте ротацию логов для экономии места
- **Обновления**: Создайте скрипт для автоматических обновлений

---

✅ **После выполнения этих шагов ваш Discord бот будет работать 24/7 на Ubuntu сервере!**