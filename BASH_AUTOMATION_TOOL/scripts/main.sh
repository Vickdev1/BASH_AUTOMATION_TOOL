#!/bin/bash

# ============================================
# Linux Bash Automation Toolkit - Main Menu
# ============================================
# Author: Your Name
# Description: Main entry point for the automation toolkit
# Version: 1.0
# ============================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="../logs/toolkit.log"
LOG_DIR="$(dirname "$LOG_FILE")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# Utility Functions
# ============================================

setup_logging() {
    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR"
    fi
    
    # Create log file if it doesn't exist
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
    fi
}

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}   Linux Bash Automation Toolkit${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

print_menu() {
    echo -e "${YELLOW}Available Operations:${NC}"
    echo "1. Backup files"
    echo "2. Clean logs / Analyze logs"
    echo "3. Manage users"
    echo "4. Check system health"
    echo "5. Install software"
    echo "6. Exit"
    echo
}

validate_option() {
    local option="$1"
    if [[ "$option" =~ ^[1-6]$ ]]; then
        return 0
    else
        return 1
    fi
}

check_script_executable() {
    local script_path="$1"
    if [[ ! -f "$script_path" ]]; then
        echo -e "${RED}Error: Script not found at $script_path${NC}"
        log_message "ERROR: Script not found - $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        echo -e "${YELLOW}Warning: Script not executable. Fixing permissions...${NC}"
        chmod +x "$script_path"
        log_message "Fixed permissions for $script_path"
    fi
    
    return 0
}

run_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    
    if check_script_executable "$script_path"; then
        bash "$script_path"
        log_message "Executed: $script_name"
        return 0
    else
        echo -e "${RED}Failed to execute $script_name${NC}"
        log_message "ERROR: Failed to execute $script_name"
        return 1
    fi
}

press_any_key() {
    echo
    read -n 1 -s -r -p "Press any key to continue..."
}

# ============================================
# Main Program
# ============================================

main() {
    # Setup logging first
    setup_logging
    
    log_message "Toolkit started"
    
    local option
    
    while true; do
        print_header
        print_menu
        echo -n "Enter your choice [1-6]: "
        read option
        
        if ! validate_option "$option"; then
            echo -e "${RED}Invalid option. Please enter a number between 1-6.${NC}"
            sleep 2
            continue
        fi
        
        case $option in
            1)
                log_message "User selected: Backup files"
                run_script "backup.sh"
                press_any_key
                ;;
            2)
                log_message "User selected: Log management"
                run_script "log_manager.sh"
                press_any_key
                ;;
            3)
                log_message "User selected: User management"
                run_script "user_manager.sh"
                press_any_key
                ;;
            4)
                log_message "User selected: System monitoring"
                run_script "system_monitor.sh"
                press_any_key
                ;;
            5)
                log_message "User selected: Software installation"
                run_script "installer.sh"
                press_any_key
                ;;
            6)
                echo -e "${GREEN}Thank you for using the Automation Toolkit!${NC}"
                log_message "Toolkit exited normally"
                exit 0
                ;;
        esac
    done
}

# Check if running with appropriate permissions for certain features
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Warning: Some features (user management, installations) require root privileges.${NC}"
        echo -e "${YELLOW}Consider running with sudo for full functionality.${NC}"
        sleep 3
    fi
}

# Trap Ctrl+C and other signals
trap 'echo -e "\n${RED}Interrupted by user${NC}"; log_message "Toolkit interrupted"; exit 1' INT TERM

# Run the main function
check_permissions
main