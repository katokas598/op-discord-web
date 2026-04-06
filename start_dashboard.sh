#!/bin/bash

# DiscordSer Bot Dashboard - Linux Startup Script
# Этот скрипт запускает web-панель управления ботом на Linux/Ubuntu

set -e  # Выход при любой ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода заголовка
print_header() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${BLUE}         DISCORDSER BOT - WEB ПАНЕЛЬ (Linux)${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo
}

# Функция для вывода ошибок
print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Функция для вывода информации
print_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

# Функция для вывода предупреждений
print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Проверка требований
check_requirements() {
    print_info "Проверяем требования..."

    # Проверка Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 не установлен!"
        echo "Установите Python 3: sudo apt install python3 python3-pip -y"
        exit 1
    fi

    # Проверка основных файлов
    if [ ! -f "dashboard_server.py" ]; then
        print_error "dashboard_server.py не найден!"
        exit 1
    fi

    if [ ! -f "config.json" ]; then
        print_error "config.json не найден!"
        print_info "Сначала запустите ./start_bot.sh для настройки"
        exit 1
    fi

    print_info "Все файлы на месте ✓"
}

# Активация виртуального окружения
setup_venv() {
    if [ -d "venv" ]; then
        print_info "Активируем виртуальное окружение..."
        source venv/bin/activate
        print_info "Виртуальное окружение активировано ✓"
    else
        print_warning "Виртуальное окружение не найдено"
        print_info "Используем системный Python"
    fi
}

# Проверка порта
check_port() {
    # Получаем порт из конфига или используем 8000 по умолчанию
    PORT=$(python3 -c "
import json
try:
    with open('config.json', 'r') as f:
        config = json.load(f)
    print(config.get('dashboard_port', 8000))
except:
    print(8000)
" 2>/dev/null || echo 8000)

    # Проверяем не занят ли порт
    if netstat -tuln 2>/dev/null | grep -q ":$PORT "; then
        print_warning "Порт $PORT уже занят!"

        # Показываем процесс который использует порт
        PROCESS=$(lsof -ti:$PORT 2>/dev/null | head -n1)
        if [ ! -z "$PROCESS" ]; then
            PROCESS_NAME=$(ps -p $PROCESS -o comm= 2>/dev/null || echo "неизвестный")
            print_warning "Процесс использующий порт: $PROCESS_NAME (PID: $PROCESS)"

            echo "Хотите завершить процесс? (y/n)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                kill $PROCESS 2>/dev/null || print_error "Не удалось завершить процесс"
                sleep 2
            else
                print_error "Не могу запустить панель на занятом порту"
                exit 1
            fi
        fi
    fi

    print_info "Порт $PORT свободен ✓"
}

# Получение URL панели
get_dashboard_url() {
    # Читаем конфигурацию для получения домена и порта
    DOMAIN=$(python3 -c "
import json
try:
    with open('config.json', 'r') as f:
        config = json.load(f)
    domain = config.get('dashboard_domain', '')
    if domain:
        print(f'https://{domain}')
    else:
        host = config.get('dashboard_host', '0.0.0.0')
        port = config.get('dashboard_port', 8000)
        if host == '0.0.0.0':
            print(f'http://localhost:{port}')
        else:
            print(f'http://{host}:{port}')
except:
    print('http://localhost:8000')
" 2>/dev/null || echo "http://localhost:8000")

    echo "$DOMAIN"
}

# Основная функция запуска
run_dashboard() {
    DASHBOARD_URL=$(get_dashboard_url)

    print_info "Запускаем web-панель управления..."
    print_info "Панель будет доступна на: $DASHBOARD_URL"
    print_info "Для остановки нажмите Ctrl+C"
    echo

    # Показываем дополнительную информацию
    echo "🌐 Доступ к панели:"
    echo "   Локальный:  http://localhost:$(python3 -c "import json; print(json.load(open('config.json')).get('dashboard_port', 8000))" 2>/dev/null || echo 8000)"

    # Получаем внешний IP если возможно
    EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "неизвестен")
    if [ "$EXTERNAL_IP" != "неизвестен" ]; then
        PORT=$(python3 -c "import json; print(json.load(open('config.json')).get('dashboard_port', 8000))" 2>/dev/null || echo 8000)
        echo "   Внешний:    http://$EXTERNAL_IP:$PORT"
    fi

    DOMAIN=$(python3 -c "import json; print(json.load(open('config.json')).get('dashboard_domain', ''))" 2>/dev/null)
    if [ ! -z "$DOMAIN" ]; then
        echo "   Домен:      https://$DOMAIN"
    fi

    echo

    # Запуск с обработкой ошибок
    if python3 dashboard_server.py --no-prompt; then
        print_info "Панель завершила работу корректно"
        exit 0
    else
        EXIT_CODE=$?
        echo
        print_error "Панель завершилась с ошибкой (код $EXIT_CODE)!"
        echo
        echo "Возможные причины:"
        echo "1. Порт уже занят другим приложением"
        echo "2. Проблемы с правами доступа к файлам"
        echo "3. Ошибка в config.json"
        echo "4. Не хватает Python модулей"
        echo
        echo "Что делать:"
        echo "- Проверьте что порт свободен: netstat -tuln | grep :8000"
        echo "- Проверьте права доступа: ls -la config.json"
        echo "- Запустите python3 validate_config.py для проверки конфига"
        echo "- Убедитесь что все зависимости установлены"
        echo
        exit $EXIT_CODE
    fi
}

# Обработка сигналов
cleanup() {
    echo
    print_info "Получен сигнал остановки..."
    print_info "Завершаем работу панели..."
    exit 0
}

trap cleanup SIGINT SIGTERM

# Основная логика
main() {
    print_header

    # Переход в директорию скрипта
    cd "$(dirname "$0")"

    check_requirements
    setup_venv
    check_port

    echo
    run_dashboard
}

# Запуск основной функции
main "$@"