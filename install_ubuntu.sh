#!/bin/bash

# DiscordSer Bot - Ubuntu Auto-Install Script
# Этот скрипт автоматически устанавливает и настраивает Discord бота на Ubuntu

set -e  # Выход при любой ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Конфигурация
BOT_USER="discordbot"
BOT_HOME="/home/$BOT_USER"
BOT_DIR="$BOT_HOME/bot-2.0-main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Функции вывода
print_header() {
    echo -e "${PURPLE}"
    echo "================================================================"
    echo "              DISCORDSER BOT - AUTO INSTALLER"
    echo "                    Ubuntu/Debian Edition"
    echo "================================================================"
    echo -e "${NC}"
}

print_step() {
    echo -e "${CYAN}[STEP] $1${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Проверка прав root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Этот скрипт должен запускаться с правами sudo"
        echo "Использование: sudo bash install_ubuntu.sh"
        exit 1
    fi
}

# Определение дистрибутива
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Не удалось определить операционную систему"
        exit 1
    fi

    print_info "Обнаружена система: $OS $VER"

    # Проверка поддерживаемых систем
    if [[ ! "$OS" =~ (Ubuntu|Debian) ]]; then
        print_warning "Скрипт тестировался только на Ubuntu и Debian"
        echo "Продолжить? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# Обновление системы
update_system() {
    print_step "Обновление системы..."

    apt update
    apt upgrade -y

    print_info "Система обновлена ✓"
}

# Установка зависимостей
install_dependencies() {
    print_step "Установка системных зависимостей..."

    # Основные пакеты
    apt install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        git \
        curl \
        wget \
        unzip \
        nginx \
        ufw \
        htop \
        nano \
        supervisor \
        sqlite3 \
        certbot \
        python3-certbot-nginx

    print_info "Зависимости установлены ✓"
}

# Создание пользователя бота
create_bot_user() {
    print_step "Создание пользователя для бота..."

    if id "$BOT_USER" &>/dev/null; then
        print_warning "Пользователь $BOT_USER уже существует"
    else
        useradd -m -s /bin/bash "$BOT_USER"
        print_info "Пользователь $BOT_USER создан ✓"
    fi

    # Создание директории для бота
    mkdir -p "$BOT_DIR"

    print_info "Директория $BOT_DIR готова ✓"
}

# Копирование файлов бота
copy_bot_files() {
    print_step "Копирование файлов бота..."

    # Копируем файлы из текущей директории
    cp -r "$SCRIPT_DIR"/* "$BOT_DIR/" 2>/dev/null || {
        print_warning "Не удалось скопировать все файлы из $SCRIPT_DIR"
        print_info "Создаем базовую структуру..."

        # Создаем базовые файлы если они не найдены
        touch "$BOT_DIR/main.py"
        touch "$BOT_DIR/dashboard_server.py"
        touch "$BOT_DIR/requirements.txt"
        mkdir -p "$BOT_DIR/discord_bot"
        touch "$BOT_DIR/discord_bot/__init__.py"
        touch "$BOT_DIR/discord_bot/bot.py"
    }

    # Устанавливаем права
    chown -R "$BOT_USER:$BOT_USER" "$BOT_HOME"
    chmod +x "$BOT_DIR"/*.sh 2>/dev/null || true

    print_info "Файлы скопированы и права установлены ✓"
}

# Настройка Python окружения
setup_python_env() {
    print_step "Настройка Python окружения..."

    # Создаем виртуальное окружение от имени пользователя бота
    sudo -u "$BOT_USER" bash -c "
        cd '$BOT_DIR'
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip

        # Устанавливаем базовые зависимости если requirements.txt существует
        if [ -f requirements.txt ] && [ -s requirements.txt ]; then
            pip install -r requirements.txt
        else
            # Устанавливаем минимальные зависимости
            pip install discord.py python-dotenv aiohttp
        fi
    "

    print_info "Python окружение настроено ✓"
}

# Создание systemd сервисов
create_systemd_services() {
    print_step "Создание systemd сервисов..."

    # Сервис для бота
    cat > /etc/systemd/system/discordbot.service << EOF
[Unit]
Description=DiscordSer Bot
After=network.target

[Service]
Type=simple
User=$BOT_USER
Group=$BOT_USER
WorkingDirectory=$BOT_DIR
Environment=PATH=$BOT_DIR/venv/bin
ExecStart=$BOT_DIR/venv/bin/python main.py
Restart=always
RestartSec=10
TimeoutSec=30

# Логирование
StandardOutput=journal
StandardError=journal
SyslogIdentifier=discordbot

# Безопасность
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$BOT_DIR

[Install]
WantedBy=multi-user.target
EOF

    # Сервис для панели
    cat > /etc/systemd/system/discordbot-dashboard.service << EOF
[Unit]
Description=DiscordSer Bot Dashboard
After=network.target

[Service]
Type=simple
User=$BOT_USER
Group=$BOT_USER
WorkingDirectory=$BOT_DIR
Environment=PATH=$BOT_DIR/venv/bin
ExecStart=$BOT_DIR/venv/bin/python dashboard_server.py --no-prompt
Restart=always
RestartSec=10
TimeoutSec=30

# Логирование
StandardOutput=journal
StandardError=journal
SyslogIdentifier=discordbot-dashboard

# Безопасность
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$BOT_DIR

[Install]
WantedBy=multi-user.target
EOF

    # Перезагрузка systemd
    systemctl daemon-reload

    print_info "Systemd сервисы созданы ✓"
}

# Настройка Nginx
setup_nginx() {
    print_step "Настройка Nginx..."

    # Создаем конфигурацию для панели
    cat > /etc/nginx/sites-available/discordbot-dashboard << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (если будет нужно)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Для статических файлов
    location /static/ {
        alias /home/discordbot/bot-2.0-main/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Безопасность
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
}
EOF

    # Включаем сайт
    ln -sf /etc/nginx/sites-available/discordbot-dashboard /etc/nginx/sites-enabled/

    # Удаляем дефолтный сайт
    rm -f /etc/nginx/sites-enabled/default

    # Проверяем конфигурацию
    nginx -t

    # Перезапускаем Nginx
    systemctl restart nginx
    systemctl enable nginx

    print_info "Nginx настроен ✓"
}

# Настройка firewall
setup_firewall() {
    print_step "Настройка firewall..."

    # Разрешаем SSH (важно!)
    ufw allow ssh

    # Разрешаем HTTP и HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp

    # Включаем firewall
    ufw --force enable

    print_info "Firewall настроен ✓"
}

# Создание скриптов управления
create_management_scripts() {
    print_step "Создание скриптов управления..."

    # Скрипт для запуска/остановки сервисов
    cat > "$BOT_DIR/manage.sh" << 'EOF'
#!/bin/bash

# Скрипт управления DiscordSer Bot

case "$1" in
    start)
        echo "Запуск сервисов..."
        sudo systemctl start discordbot.service
        sudo systemctl start discordbot-dashboard.service
        echo "Сервисы запущены ✓"
        ;;
    stop)
        echo "Остановка сервисов..."
        sudo systemctl stop discordbot.service
        sudo systemctl stop discordbot-dashboard.service
        echo "Сервисы остановлены ✓"
        ;;
    restart)
        echo "Перезапуск сервисов..."
        sudo systemctl restart discordbot.service
        sudo systemctl restart discordbot-dashboard.service
        echo "Сервисы перезапущены ✓"
        ;;
    status)
        echo "Статус сервисов:"
        sudo systemctl status discordbot.service --no-pager -l
        echo
        sudo systemctl status discordbot-dashboard.service --no-pager -l
        ;;
    logs)
        echo "Логи бота:"
        sudo journalctl -u discordbot.service --no-pager -l --since "1 hour ago"
        echo
        echo "Логи панели:"
        sudo journalctl -u discordbot-dashboard.service --no-pager -l --since "1 hour ago"
        ;;
    update)
        echo "Обновление бота..."
        cd "$(dirname "$0")"
        sudo systemctl stop discordbot.service discordbot-dashboard.service

        # Активируем venv и обновляем зависимости
        source venv/bin/activate
        pip install --upgrade -r requirements.txt

        sudo systemctl start discordbot.service discordbot-dashboard.service
        echo "Обновление завершено ✓"
        ;;
    *)
        echo "Использование: $0 {start|stop|restart|status|logs|update}"
        exit 1
        ;;
esac
EOF

    chmod +x "$BOT_DIR/manage.sh"

    # Создаем симлинк для глобального доступа
    ln -sf "$BOT_DIR/manage.sh" /usr/local/bin/discordbot

    print_info "Скрипты управления созданы ✓"
    print_info "Используйте команду 'discordbot' для управления ботом"
}

# Настройка логирования
setup_logging() {
    print_step "Настройка логирования..."

    # Создаем конфигурацию для ротации логов
    cat > /etc/logrotate.d/discordbot << EOF
/var/log/discordbot/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $BOT_USER $BOT_USER
    postrotate
        systemctl reload discordbot.service > /dev/null 2>&1 || true
        systemctl reload discordbot-dashboard.service > /dev/null 2>&1 || true
    endscript
}
EOF

    # Создаем директорию для логов
    mkdir -p /var/log/discordbot
    chown "$BOT_USER:$BOT_USER" /var/log/discordbot

    print_info "Логирование настроено ✓"
}

# Финальная настройка
final_setup() {
    print_step "Финальная настройка..."

    # Устанавливаем правильные права на все файлы
    chown -R "$BOT_USER:$BOT_USER" "$BOT_HOME"

    # Включаем автозапуск сервисов (но не запускаем пока нет конфига)
    systemctl enable discordbot.service
    systemctl enable discordbot-dashboard.service

    print_info "Финальная настройка завершена ✓"
}

# Показ информации о завершении
show_completion_info() {
    echo
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}              УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo
    echo -e "${CYAN}📁 Расположение бота:${NC} $BOT_DIR"
    echo -e "${CYAN}👤 Пользователь:${NC} $BOT_USER"
    echo -e "${CYAN}🌐 Web-панель:${NC} http://$(hostname -I | awk '{print $1}') или http://localhost"
    echo
    echo -e "${YELLOW}⚡ СЛЕДУЮЩИЕ ШАГИ:${NC}"
    echo
    echo "1. Настройте бота:"
    echo "   sudo -u $BOT_USER bash -c 'cd $BOT_DIR && python3 setup.py'"
    echo
    echo "2. Запустите сервисы:"
    echo "   discordbot start"
    echo
    echo "3. Проверьте статус:"
    echo "   discordbot status"
    echo
    echo -e "${YELLOW}🛠️  УПРАВЛЕНИЕ БОТОМ:${NC}"
    echo "   discordbot {start|stop|restart|status|logs|update}"
    echo
    echo -e "${YELLOW}📊 МОНИТОРИНГ:${NC}"
    echo "   Логи бота:   sudo journalctl -u discordbot.service -f"
    echo "   Логи панели: sudo journalctl -u discordbot-dashboard.service -f"
    echo
    echo -e "${YELLOW}🔒 БЕЗОПАСНОСТЬ:${NC}"
    echo "   Firewall настроен (порты 22, 80, 443 открыты)"
    echo "   Сервисы работают от пользователя $BOT_USER"
    echo
    echo -e "${YELLOW}📖 ДОКУМЕНТАЦИЯ:${NC}"
    echo "   Полная инструкция: $BOT_DIR/UBUNTU_INSTALL.md"
    echo
    echo -e "${GREEN}Готово! Наслаждайтесь использованием DiscordSer Bot! 🎉${NC}"
}

# Обработка ошибок
handle_error() {
    local exit_code=$?
    print_error "Произошла ошибка на шаге: $1"
    print_error "Код ошибки: $exit_code"
    echo "Проверьте логи выше для деталей"
    exit $exit_code
}

# Основная функция
main() {
    print_header

    # Установка обработчика ошибок
    trap 'handle_error "Неизвестный шаг"' ERR

    echo "Начинаем автоматическую установку DiscordSer Bot..."
    echo "Это займет несколько минут..."
    echo

    check_root
    detect_os
    update_system
    install_dependencies
    create_bot_user
    copy_bot_files
    setup_python_env
    create_systemd_services
    setup_nginx
    setup_firewall
    create_management_scripts
    setup_logging
    final_setup

    show_completion_info
}

# Запуск установки
main "$@"