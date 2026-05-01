#!/bin/bash

# ============================================
# System Health Monitor Script
# ============================================
# Description: Monitor CPU, memory, disk, and process usage
# Usage: system_monitor.sh
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../logs/toolkit.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ============================================
# Helper Functions
# ============================================

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

get_color_for_usage() {
    local usage="$1"
    
    if (( $(echo "$usage < 50" | bc -l) )); then
        echo "$GREEN"
    elif (( $(echo "$usage < 80" | bc -l) )); then
        echo "$YELLOW"
    else
        echo "$RED"
    fi
}

print_bar() {
    local percentage="$1"
    local width=40
    local filled=$(echo "$percentage * $width / 100" | bc)
    
    for ((i=0; i<$filled; i++)); do
        echo -n "█"
    done
    for ((i=$filled; i<$width; i++)); do
        echo -n "░"
    done
}

# ============================================
# Monitoring Functions
# ============================================

get_cpu_usage() {
    # Get CPU usage using /proc/stat
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    # Fallback method if the above doesn't work
    if [[ -z "$cpu_usage" ]]; then
        cpu_usage=$(mpstat 1 1 2>/dev/null | tail -n 1 | awk '{print 100 - $12}' || echo "0")
    fi
    
    printf "%.1f" "$cpu_usage"
}

get_memory_usage() {
    local total_mem
    local used_mem
    local mem_percent
    
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    used_mem=$(free -m | awk '/^Mem:/{print $3}')
    mem_percent=$(echo "scale=1; $used_mem * 100 / $total_mem" | bc)
    
    echo "$used_mem|$total_mem|$mem_percent"
}

get_disk_usage() {
    local disk_info
    disk_info=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "$disk_info"
}

get_top_processes() {
    echo -e "${CYAN}Top 5 CPU-consuming processes:${NC}"
    ps aux --sort=-%cpu | head -6 | tail -5 | while read line; do
        local user=$(echo "$line" | awk '{print $1}')
        local cpu=$(echo "$line" | awk '{print $3}')
        local mem=$(echo "$line" | awk '{print $4}')
        local cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | cut -c1-50)
        printf "  %-8s CPU: %5s%% MEM: %5s%% %s\n" "$user" "$cpu" "$mem" "$cmd"
    done
}

get_network_status() {
    echo -e "${CYAN}Network Interfaces:${NC}"
    ip -br addr | grep -v "LOOPBACK" | while read line; do
        local interface=$(echo "$line" | awk '{print $1}')
        local status=$(echo "$line" | awk '{print $2}')
        local ip_addr=$(echo "$line" | awk '{print $3}')
        
        if [[ "$status" == "UP" ]]; then
            echo -e "  ${GREEN}✓${NC} $interface: $ip_addr"
        else
            echo -e "  ${RED}✗${NC} $interface: DOWN"
        fi
    done
}

get_system_load() {
    local load_avg
    load_avg=$(uptime | awk -F 'load average:' '{print $2}')
    echo "$load_avg"
}

get_uptime() {
    local uptime_seconds=$(cat /proc/uptime | awk '{print $1}')
    local days=$(echo "$uptime_seconds / 86400" | bc)
    local hours=$(echo "($uptime_seconds % 86400) / 3600" | bc)
    local minutes=$(echo "($uptime_seconds % 3600) / 60" | bc)
    
    echo "${days}d ${hours}h ${minutes}m"
}

check_services() {
    echo -e "${CYAN}Critical Service Status:${NC}"
    
    local services=("sshd" "cron" "rsyslog" "systemd-journald")
    
    for service in "${services[@]}"; do
        if systemctl is-active "$service" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $service: Running"
        else
            echo -e "  ${RED}✗${NC} $service: Not running"
        fi
    done
}

# ============================================
# Main Display Function
# ============================================

display_monitor() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${GREEN}                    SYSTEM HEALTH MONITOR                    ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # System Information
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}System Information:${NC}"
    echo -e "  Hostname: $(hostname)"
    echo -e "  Kernel: $(uname -r)"
    echo -e "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "  Uptime: $(get_uptime)"
    echo -e "  Users logged in: $(who | wc -l)"
    echo -e "  Date/Time: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Load Average
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Load Average:${NC}"
    echo -e "  $(get_system_load)"
    
    # CPU Usage
    local cpu_usage=$(get_cpu_usage)
    local cpu_color=$(get_color_for_usage "$cpu_usage")
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}CPU Usage:${NC}"
    echo -n "  "
    print_bar "$cpu_usage"
    echo -e " ${cpu_color}${cpu_usage}%${NC}"
    
    # Memory Usage
    local mem_info=$(get_memory_usage)
    local used_mem=$(echo "$mem_info" | cut -d'|' -f1)
    local total_mem=$(echo "$mem_info" | cut -d'|' -f2)
    local mem_percent=$(echo "$mem_info" | cut -d'|' -f3)
    local mem_color=$(get_color_for_usage "$mem_percent")
    
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Memory Usage:${NC}"
    echo -e "  Total: ${total_mem}MB"
    echo -e "  Used: ${used_mem}MB"
    echo -n "  "
    print_bar "$mem_percent"
    echo -e " ${mem_color}${mem_percent}%${NC}"
    
    # Disk Usage
    local disk_usage=$(get_disk_usage)
    local disk_color=$(get_color_for_usage "$disk_usage")
    
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Disk Usage (Root partition):${NC}"
    df -h / | awk 'NR==2 {printf "  Total: %s\n  Used: %s\n  Available: %s\n", $2, $3, $4}'
    echo -n "  "
    print_bar "$disk_usage"
    echo -e " ${disk_color}${disk_usage}%${NC}"
    
    # Top Processes
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    get_top_processes
    
    # Network Status
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    get_network_status
    
    # Service Status
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    check_services
    
    # Alerts for high usage
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Alerts:${NC}"
    
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        echo -e "  ${RED}⚠ High CPU usage detected: ${cpu_usage}%${NC}"
        log_message "ALERT: High CPU usage - ${cpu_usage}%"
    fi
    
    if (( $(echo "$mem_percent > 80" | bc -l) )); then
        echo -e "  ${RED}⚠ High memory usage detected: ${mem_percent}%${NC}"
        log_message "ALERT: High memory usage - ${mem_percent}%"
    fi
    
    if (( $disk_usage > 80 )); then
        echo -e "  ${RED}⚠ Low disk space: ${disk_usage}% used${NC}"
        log_message "ALERT: Low disk space - ${disk_usage}%"
    fi
    
    if [[ -z "$cpu_usage" ]] || [[ -z "$mem_percent" ]] || [[ -z "$disk_usage" ]]; then
        echo -e "  ${YELLOW}No alerts at this time.${NC}"
    else
        echo -e "  ${GREEN}✓ System appears healthy${NC}"
    fi
    
    echo
    log_message "System health check completed - CPU: ${cpu_usage}%, MEM: ${mem_percent}%, DISK: ${disk_usage}%"
}

# ============================================
# Main Function with Refresh Option
# ============================================

main() {
    while true; do
        display_monitor
        
        echo
        echo -e "${YELLOW}Options:${NC}"
        echo "  [R] Refresh  [L] Log to file  [Q] Quit"
        echo -n "Choice: "
        read -n 1 choice
        echo
        
        case $choice in
            r|R)
                continue
                ;;
            l|L)
                local report_file="system_report_$(date '+%Y%m%d_%H%M%S').txt"
                display_monitor > "$report_file" 2>&1
                echo -e "${GREEN}Report saved to $report_file${NC}"
                log_message "System report saved to $report_file"
                sleep 2
                ;;
            q|Q)
                echo -e "${GREEN}Exiting system monitor...${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Check for required commands
for cmd in top ps free df uptime ip systemctl; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${RED}Warning: $cmd command not found. Some features may not work.${NC}"
    fi
done

# Run main function
main