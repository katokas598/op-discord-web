# 🚀 Быстрое развертывание DiscordSer Bot на Ubuntu

## ⚡ Супер-быстрый старт (одна команда)

```bash
curl -sSL https://raw.githubusercontent.com/your-repo/bot-2.0-main/main/install_ubuntu.sh | sudo bash
```

## 📖 Пошаговая установка

### 1. Скачивание файлов на сервер

**Способ А: Через SCP (рекомендуется)**
```bash
# На вашем Windows компьютере (в PowerShell)
scp -r "F:\bot-2.0-main" username@your-server-ip:/tmp/

# На Ubuntu сервере
sudo cp -r /tmp/bot-2.0-main /opt/
```

**Способ Б: Через wget/curl**
```bash
# Загружаем архив (если есть ссылка на GitHub/файлообменник)
cd /opt
sudo wget https://your-file-host.com/bot-2.0-main.zip
sudo unzip bot-2.0-main.zip
```

### 2. Запуск автоустановки

```bash
cd /opt/bot-2.0-main
sudo chmod +x install_ubuntu.sh
sudo ./install_ubuntu.sh
```

### 3. Настройка бота

```bash
# Переключиться на пользователя бота
sudo su - discordbot
cd ~/bot-2.0-main

# Запустить мастер настройки
python3 setup.py
```

**Что вводить:**
- **Discord Token**: Получите на https://discord.com/developers/applications
- **Prefix**: `!` (или любой другой)
- **Guild ID**: ID вашего Discord сервера (включите Developer Mode в Discord)
- **Admin IDs**: Ваш Discord ID (через запятую)
- **Dashboard Domain**: Ваш домен (необязательно)

### 4. Запуск сервисов

```bash
# Выйти из пользователя discordbot
exit

# Запустить сервисы
sudo systemctl start discordbot.service
sudo systemctl start discordbot-dashboard.service

# Проверить статус
sudo systemctl status discordbot.service
sudo systemctl status discordbot-dashboard.service
```

### 5. Настройка домена (опционально)

**Если у вас есть домен:**

```bash
# Отредактировать Nginx конфигурацию
sudo nano /etc/nginx/sites-available/discordbot-dashboard

# Заменить your-domain.com на ваш домен
# Перезапустить Nginx
sudo nginx -t
sudo systemctl restart nginx

# Получить SSL сертификат
sudo certbot --nginx -d yourdomain.com
```

## 🎯 Готовые команды для копирования

### Полная установка одним блоком:
```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Скачивание и установка (замените путь на ваш)
scp -r "F:\bot-2.0-main" username@server-ip:/tmp/
sudo cp -r /tmp/bot-2.0-main /opt/
cd /opt/bot-2.0-main
sudo chmod +x *.sh
sudo ./install_ubuntu.sh

# Настройка бота
sudo su - discordbot -c "cd ~/bot-2.0-main && python3 setup.py"

# Запуск
sudo systemctl start discordbot.service discordbot-dashboard.service
sudo systemctl enable discordbot.service discordbot-dashboard.service
```

## 🔧 Команды управления

После установки используйте команду `discordbot`:

```bash
discordbot start      # Запуск сервисов
discordbot stop       # Остановка сервисов  
discordbot restart    # Перезапуск сервисов
discordbot status     # Статус сервисов
discordbot logs       # Просмотр логов
discordbot update     # Обновление бота
```

## 🌐 Доступ к панели управления

- **Локально**: http://localhost или http://server-ip
- **С доменом**: https://yourdomain.com

## 📊 Мониторинг

```bash
# Логи в реальном времени
sudo journalctl -u discordbot.service -f

# Статус системы
htop

# Использование порта
sudo netstat -tulpn | grep :8000
```

## ❗ Важные моменты

1. **Firewall**: Порты 80, 443 и 22 автоматически открыты
2. **Безопасность**: Бот работает от пользователя `discordbot`, не от root
3. **Автозапуск**: Сервисы автоматически стартуют при загрузке системы
4. **Логи**: Все логи доступны через `journalctl`

## 🆘 Решение проблем

### Бот не запускается:
```bash
# Проверить логи
sudo journalctl -u discordbot.service --no-pager -l

# Проверить конфигурацию
sudo -u discordbot bash -c "cd /home/discordbot/bot-2.0-main && python3 validate_config.py"
```

### Панель недоступна:
```bash
# Проверить статус
sudo systemctl status discordbot-dashboard.service

# Проверить Nginx
sudo nginx -t
sudo systemctl status nginx
```

### Переустановка:
```bash
# Остановить сервисы
sudo systemctl stop discordbot.service discordbot-dashboard.service

# Удалить пользователя и файлы
sudo userdel -r discordbot
sudo rm -rf /home/discordbot

# Запустить установку заново
sudo ./install_ubuntu.sh
```

---

✅ **После выполнения этих шагов ваш Discord бот будет работать 24/7 на Ubuntu!**