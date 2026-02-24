#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Функция удаления
uninstall() {
    echo ""
    print_warning "=== РЕЖИМ УДАЛЕНИЯ ==="
    echo ""
    
    # Подтверждение удаления
    read -p "Вы точно хотите удалить скрипт уведомлений Gotify? (yes/no): " CONFIRM
    if [[ ! "$CONFIRM" == "yes" ]]; then
        print_info "Удаление отменено"
        exit 0
    fi
    
    print_info "Останавливаем и отключаем сервис..."
    
    # Останавливаем и отключаем сервис
    systemctl stop gotify-notify.service 2>/dev/null
    systemctl disable gotify-notify.service 2>/dev/null
    
    # Удаляем файлы сервисов (таймер больше не создаем)
    print_info "Удаляем файлы сервисов..."
    rm -f /etc/systemd/system/gotify-notify.service
    
    # Перезагружаем systemd
    systemctl daemon-reload
    
    # Удаляем скрипт
    print_info "Удаляем скрипт..."
    rm -f /usr/local/bin/proxmox-gotify-notify.sh
    
    # Удаляем лог-файл
    print_info "Удаляем лог-файл..."
    rm -f /var/log/gotify-notify.log
    
    # Удаляем конфигурацию (если есть)
    rm -f /etc/gotify-notify.conf 2>/dev/null
    
    print_success "Скрипт уведомлений Gotify успешно удален!"
    
    # Проверяем остались ли какие-то файлы
    local FILES_REMAINING=0
    [[ -f /usr/local/bin/proxmox-gotify-notify.sh ]] && FILES_REMAINING=1
    [[ -f /etc/systemd/system/gotify-notify.service ]] && FILES_REMAINING=1
    [[ -f /var/log/gotify-notify.log ]] && FILES_REMAINING=1
    
    if [[ $FILES_REMAINING -eq 1 ]]; then
        print_warning "Некоторые файлы могли остаться. Проверьте вручную:"
        ls -la /usr/local/bin/proxmox-gotify-notify.sh 2>/dev/null || echo "  • Скрипт удален"
        ls -la /etc/systemd/system/gotify-notify.service 2>/dev/null || echo "  • Сервис удален"
        ls -la /var/log/gotify-notify.log 2>/dev/null || echo "  • Лог удален"
    fi
    
    exit 0
}

# Функция установки
install() {
    # Проверка прав root
    if [[ $EUID -ne 0 ]]; then
       print_error "Этот скрипт должен запускаться с правами root (sudo)!"
       exit 1
    fi

    # Приветствие
    clear
    echo "=================================================="
    echo "  Установка скрипта уведомлений в Gotify для Proxmox"
    echo "  (ОДНОКРАТНОЕ уведомление после запуска)"
    echo "=================================================="
    echo ""

    # Запрос конфигурации
    print_info "Введите настройки Gotify:"

    read -p "Домен Gotify (например, gotify.example.com): " GOTIFY_DOMAIN
    while [[ -z "$GOTIFY_DOMAIN" ]]; do
        print_error "Домен не может быть пустым!"
        read -p "Домен Gotify: " GOTIFY_DOMAIN
    done

    read -p "Протокол (https/http) [https]: " GOTIFY_PROTOCOL
    GOTIFY_PROTOCOL=${GOTIFY_PROTOCOL:-https}

    read -p "Токен приложения Gotify: " GOTIFY_TOKEN
    while [[ -z "$GOTIFY_TOKEN" ]]; do
        print_error "Токен не может быть пустым!"
        read -p "Токен приложения Gotify: " GOTIFY_TOKEN
    done

    read -p "Максимальное количество попыток ping [30]: " MAX_RETRIES
    MAX_RETRIES=${MAX_RETRIES:-30}

    read -p "Пауза между попытками ping (секунд) [10]: " SLEEP_TIME
    SLEEP_TIME=${SLEEP_TIME:-10}
    
    read -p "Количество ping пакетов для проверки [1]: " PING_COUNT
    PING_COUNT=${PING_COUNT:-1}

    echo ""
    print_info "Проверяем доступность Gotify через ping..."
    if ping -c $PING_COUNT -W 2 $GOTIFY_DOMAIN > /dev/null 2>&1; then
        print_success "Хост $GOTIFY_DOMAIN отвечает на ping"
    else
        print_warning "Хост $GOTIFY_DOMAIN не отвечает на ping, но установка продолжится"
    fi

    # Создание основного скрипта
    print_info "Создаем скрипт уведомления..."

    cat > /usr/local/bin/proxmox-gotify-notify.sh << EOF
#!/bin/bash

# =============================================
# Скрипт уведомления Proxmox в Gotify
# ОДНОКРАТНАЯ отправка после запуска
# Установлен: $(date)
# =============================================

# Конфигурация
GOTIFY_DOMAIN="$GOTIFY_DOMAIN"
GOTIFY_TOKEN="$GOTIFY_TOKEN"
GOTIFY_PROTOCOL="$GOTIFY_PROTOCOL"
MAX_RETRIES=$MAX_RETRIES
SLEEP_TIME=$SLEEP_TIME
PING_COUNT=$PING_COUNT
LOG_FILE="/var/log/gotify-notify.log"
SENT_FLAG_FILE="/var/run/gotify-notify-sent.flag"

# Функция логирования
log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" | tee -a \$LOG_FILE
}

# Функция проверки через PING
check_with_ping() {
    ping -c \$PING_COUNT -W 2 \$GOTIFY_DOMAIN > /dev/null 2>&1
    return \$?
}

# Функция отправки сообщения
send_message() {
    local title="\$1"
    local message="\$2"
    local priority="\${3:-5}"
    
    FULL_URL="\$GOTIFY_PROTOCOL://\$GOTIFY_DOMAIN/message?token=\$GOTIFY_TOKEN"
    log "Отправка на: \$FULL_URL"
    
    HTTP_CODE=\$(curl -X POST "\$FULL_URL" \\
        -F "title=\$title" \\
        -F "message=\$message" \\
        -F "priority=\$priority" \\
        -w "%{http_code}" \\
        --silent --show-error \\
        --connect-timeout 10 \\
        --max-time 30 \\
        -o /tmp/gotify_response.txt 2>&1)
    
    if [ "\$HTTP_CODE" = "200" ]; then
        log "✅ Успешно отправлено (код \$HTTP_CODE)"
        # Создаем флаг, что уведомление уже отправлено
        touch \$SENT_FLAG_FILE
        return 0
    else
        log "❌ Ошибка отправки: код \$HTTP_CODE"
        return 1
    fi
}

# Основная функция
main() {
    log "🚀 Запуск проверки (однократное уведомление)"
    
    # Проверяем, не отправляли ли уже уведомление после этой загрузки
    if [ -f \$SENT_FLAG_FILE ]; then
        log "ℹ️ Уведомление уже было отправлено после этой загрузки. Выход."
        exit 0
    fi
    
    # Ждем пока хост начнет отвечать на ping
    retry=0
    while [ \$retry -lt \$MAX_RETRIES ]; do
        if check_with_ping; then
            log "✅ Хост \$GOTIFY_DOMAIN доступен (ping)"
            
            # Небольшая задержка для инициализации
            log "⏳ Ждем 5 секунд..."
            sleep 5
            
            log "📤 Отправляю уведомление..."
            
            # Собираем информацию о системе
            HOSTNAME=\$(hostname -f 2>/dev/null || hostname)
            IP_ADDR=\$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
            KERNEL=\$(uname -r)
            LOAD=\$(uptime | awk -F'load average:' '{print \$2}' | xargs)
            UPTIME=\$(uptime -p | sed 's/up //')
            
            # Проверяем Proxmox службы
            if systemctl is-active --quiet pveproxy; then
                PROXMOX_STATUS="✅ PVE Proxy активен"
            else
                PROXMOX_STATUS="❌ PVE Proxy не активен"
            fi
            
            # Формируем сообщение
            MESSAGE="**🏢 Хост:** \$HOSTNAME
**🌐 IP:** \$IP_ADDR
**🧠 Kernel:** \$KERNEL
**⏱️ Uptime:** \$UPTIME
**📊 Load:**\$LOAD
**🖥️ Proxmox:** \$PROXMOX_STATUS
**🕐 Время:** \$(date '+%Y-%m-%d %H:%M:%S')"
            
            if send_message "✅ Proxmox запущен" "\$MESSAGE" 8; then
                log "✅ Уведомление успешно отправлено (однократно)"
                return 0
            else
                log "❌ Ошибка при отправке"
                # Пробуем с игнорированием SSL
                log "🔄 Пробуем с игнорированием SSL..."
                
                curl -k -X POST "\$FULL_URL" \\
                    -F "title=✅ Proxmox запущен" \\
                    -F "message=\$MESSAGE" \\
                    -F "priority=8" \\
                    --silent --output /dev/null
                
                if [ \$? -eq 0 ]; then
                    log "✅ Уведомление отправлено (SSL ignored)"
                    touch \$SENT_FLAG_FILE
                    return 0
                fi
            fi
        fi
        
        retry=\$((retry + 1))
        log "⏳ Хост не отвечает на ping, попытка \$retry из \$MAX_RETRIES"
        sleep \$SLEEP_TIME
    done
    
    log "❌ Превышено количество попыток. Уведомление НЕ отправлено."
    return 1
}

# Запуск
main
exit \$?
EOF

    # Делаем скрипт исполняемым
    chmod +x /usr/local/bin/proxmox-gotify-notify.sh
    print_success "Скрипт создан: /usr/local/bin/proxmox-gotify-notify.sh"

    # Создаем файл лога
    touch /var/log/gotify-notify.log
    chmod 644 /var/log/gotify-notify.log
    print_info "Файл лога: /var/log/gotify-notify.log"

    # Создаем systemd сервис (БЕЗ ТАЙМЕРА!)
    print_info "Создаем systemd сервис (однократный запуск)..."

    cat > /etc/systemd/system/gotify-notify.service << EOF
[Unit]
Description=Send ONE startup notification to Gotify after Proxmox boot
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/proxmox-gotify-notify.sh
StandardOutput=journal
StandardError=journal
User=root

[Install]
WantedBy=multi-user.target
EOF

    # Перезагружаем systemd
    systemctl daemon-reload
    print_success "Systemd сервис создан"

    # Включаем ТОЛЬКО сервис (таймер больше не включаем!)
    print_info "Включаем автозагрузку сервиса..."
    systemctl enable gotify-notify.service

    # Создаем файл конфигурации
    cat > /etc/gotify-notify.conf << EOF
# Конфигурация Gotify Notify
# Установлен: $(date)
# Режим: ОДНОКРАТНОЕ уведомление после загрузки
GOTIFY_DOMAIN=$GOTIFY_DOMAIN
GOTIFY_PROTOCOL=$GOTIFY_PROTOCOL
GOTIFY_TOKEN=$GOTIFY_TOKEN
MAX_RETRIES=$MAX_RETRIES
SLEEP_TIME=$SLEEP_TIME
PING_COUNT=$PING_COUNT
EOF

    # Тестирование
    echo ""
    print_info "Хотите проверить работу скрипта сейчас? (y/n)"
    read -p "> " RUN_TEST

    if [[ "$RUN_TEST" =~ ^[YyДд]$ ]]; then
        print_info "Запускаем проверку..."
        /usr/local/bin/proxmox-gotify-notify.sh
    fi

    # Создаем скрипт для удаления
    cat > /usr/local/bin/remove-gotify-notify.sh << 'EOF'
#!/bin/bash
# Скрипт для быстрого удаления уведомлений Gotify
if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: Запустите с sudo!"
    exit 1
fi

echo "Останавливаем сервис..."
systemctl stop gotify-notify.service 2>/dev/null

echo "Отключаем автозагрузку..."
systemctl disable gotify-notify.service 2>/dev/null

echo "Удаляем файлы..."
rm -f /etc/systemd/system/gotify-notify.service
rm -f /usr/local/bin/proxmox-gotify-notify.sh
rm -f /var/log/gotify-notify.log
rm -f /etc/gotify-notify.conf
rm -f /var/run/gotify-notify-sent.flag

systemctl daemon-reload

echo "✅ Готово! Скрипт уведомлений удален."
EOF

    chmod +x /usr/local/bin/remove-gotify-notify.sh
    
    # Финальная информация
    echo ""
    echo "=================================================="
    print_success "УСТАНОВКА ЗАВЕРШЕНА!"
    echo "=================================================="
    echo ""
    echo "📋 Информация:"
    echo "  • Скрипт: /usr/local/bin/proxmox-gotify-notify.sh"
    echo "  • Лог: /var/log/gotify-notify.log"
    echo "  • Конфиг: /etc/gotify-notify.conf"
    echo ""
    echo "✅ РЕЖИМ РАБОТЫ: ОДНОКРАТНОЕ уведомление после загрузки"
    echo ""
    echo "📝 Команды:"
    echo "  systemctl status gotify-notify.service"
    echo "  journalctl -u gotify-notify.service -f"
    echo "  /usr/local/bin/proxmox-gotify-notify.sh"
    echo ""
    echo "🗑️  Удаление: sudo /usr/local/bin/remove-gotify-notify.sh"
    echo "=================================================="
}

# Обработка параметров командной строки
case "$1" in
    --uninstall|-u|remove|uninstall)
        uninstall
        ;;
    --help|-h)
        echo "Использование: $0 [OPTION]"
        echo "Установка скрипта уведомлений Gotify для Proxmox"
        echo "РЕЖИМ: Однократное уведомление после загрузки"
        echo ""
        echo "Опции:"
        echo "  --install       Установка (по умолчанию)"
        echo "  --uninstall     Полное удаление"
        echo "  --help          Показать эту справку"
        exit 0
        ;;
    --install)
        install
        ;;
    "")
        install
        ;;
    *)
        print_error "Неизвестный параметр: $1"
        echo "Используйте --help для справки"
        exit 1
        ;;
esac