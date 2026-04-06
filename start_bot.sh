#!/bin/bash

# DiscordSer Bot - Linux Startup Script
# Этот скрипт запускает Discord бота на Linux/Ubuntu

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
    echo -e "${BLUE}            DISCORDSER BOT v2.0 (Linux)${NC}"
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

# Проверка существования файлов
check_requirements() {
    print_info "Проверяем требования..."

    # Проверка Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 не установлен!"
        echo "Установите Python 3: sudo apt install python3 python3-pip -y"
        exit 1
    fi

    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    print_info "Python версия: $PYTHON_VERSION"

    # Проверка основных файлов
    if [ ! -f "main.py" ]; then
        print_error "main.py не найден!"
        exit 1
    fi

    if [ ! -f "requirements.txt" ]; then
        print_error "requirements.txt не найден!"
        exit 1
    fi

    print_info "Все файлы на месте ✓"
}

# Проверка и создание виртуального окружения
setup_venv() {
    if [ ! -d "venv" ]; then
        print_info "Создаем виртуальное окружение..."
        python3 -m venv venv
        print_info "Виртуальное окружение создано ✓"
    else
        print_info "Виртуальное окружение найдено ✓"
    fi

    # Активация venv
    source venv/bin/activate
    print_info "Виртуальное окружение активировано ✓"
}

# Проверка конфигурации
check_config() {
    if [ ! -f "config.json" ]; then
        print_warning "config.json не найден!"
        print_info "Запускаем мастер настройки..."
        echo
        python3 setup.py
        echo
        read -p "Нажмите Enter для продолжения после настройки..."
        return
    fi

    print_info "Конфигурация найдена ✓"

    # Проверка валидности конфигурации
    if [ -f "validate_config.py" ]; then
        print_info "Проверяем валидность конфигурации..."
        if python3 validate_config.py --silent; then
            print_info "Конфигурация корректна ✓"
        else
            print_error "Проблемы с конфигурацией!"
            print_info "Запустите: python3 validate_config.py"
            exit 1
        fi
    fi
}

# Установка зависимостей
install_dependencies() {
    print_info "Проверяем зависимости Python..."

    # Проверка discord.py
    if python3 -c "import discord" 2>/dev/null; then
        DISCORD_VERSION=$(python3 -c "import discord; print(discord.__version__)" 2>/dev/null)
        print_info "discord.py $DISCORD_VERSION установлен ✓"
    else
        print_warning "discord.py не установлен!"
        print_info "Устанавливаем зависимости..."
        pip install --upgrade pip
        pip install -r requirements.txt
        print_info "Зависимости установлены ✓"
    fi
}

# Основная функция запуска
run_bot() {
    print_info "Запускаем Discord бота..."
    print_info "Для остановки нажмите Ctrl+C"
    echo

    # Запуск с обработкой ошибок
    if python3 main.py; then
        print_info "Бот завершил работу корректно"
        exit 0
    else
        EXIT_CODE=$?
        echo
        print_error "Бот завершился с ошибкой (код $EXIT_CODE)!"
        echo
        echo "Возможные причины:"
        echo "1. Неверный Discord токен в config.json"
        echo "2. Токен является плейсхолдером 'YOUR_DISCORD_TOKEN_HERE'"
        echo "3. Неверный ID сервера (guild_id)"
        echo "4. Отсутствует интернет-соединение"
        echo "5. Бот не добавлен на Discord сервер"
        echo
        echo "Что делать:"
        echo "- Откройте config.json и проверьте настройки"
        echo "- Запустите python3 setup.py для пересоздания конфигурации"
        echo "- Запустите python3 validate_config.py для проверки"
        echo "- Убедитесь что бот добавлен на сервер с нужными правами"
        echo
        echo "Подробные логи см. выше"
        exit $EXIT_CODE
    fi
}

# Обработка сигналов
cleanup() {
    echo
    print_info "Получен сигнал остановки..."
    print_info "Завершаем работу бота..."
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
    check_config
    install_dependencies

    echo
    run_bot
}

# Запуск основной функции
main "$@"