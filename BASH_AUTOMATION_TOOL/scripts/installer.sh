#!/bin/bash

# ============================================
# Software Installer Script
# ============================================
# Description: Install and manage software packages
# Usage: installer.sh (may require sudo for installation)
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../logs/toolkit.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detect package manager
detect_package_manager() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

PACKAGE_MANAGER=$(detect_package_manager)

# ============================================
# Helper Functions
# ============================================

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

check_package_installed() {
    local package="$1"
    
    case $PACKAGE_MANAGER in
        apt)
            dpkg -l "$package" &>/dev/null && return 0 || return 1
            ;;
        dnf|yum)
            rpm -q "$package" &>/dev/null && return 0 || return 1
            ;;
        zypper)
            rpm -q "$package" &>/dev/null && return 0 || return 1
            ;;
        pacman)
            pacman -Q "$package" &>/dev/null && return 0 || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

install_package() {
    local package="$1"
    
    echo -e "${CYAN}Installing $package...${NC}"
    log_message "Attempting to install: $package"
    
    local install_cmd
    case $PACKAGE_MANAGER in
        apt)
            install_cmd="apt install -y $package"
            ;;
        dnf)
            install_cmd="dnf install -y $package"
            ;;
        yum)
            install_cmd="yum install -y $package"
            ;;
        zypper)
            install_cmd="zypper install -y $package"
            ;;
        pacman)
            install_cmd="pacman -S --noconfirm $package"
            ;;
        *)
            echo -e "${RED}Unsupported package manager!${NC}"
            log_message "ERROR: Unsupported package manager for $package"
            return 1
            ;;
    esac
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Root privileges required. Using sudo...${NC}"
        install_cmd="sudo $install_cmd"
    fi
    
    eval "$install_cmd"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Successfully installed $package${NC}"
        log_message "Successfully installed: $package"
        return 0
    else
        echo -e "${RED}✗ Failed to install $package${NC}"
        log_message "ERROR: Failed to install $package"
        return 1
    fi
}

remove_package() {
    local package="$1"
    
    echo -e "${CYAN}Removing $package...${NC}"
    log_message "Attempting to remove: $package"
    
    local remove_cmd
    case $PACKAGE_MANAGER in
        apt)
            remove_cmd="apt remove -y $package"
            ;;
        dnf|yum)
            remove_cmd="$PACKAGE_MANAGER remove -y $package"
            ;;
        zypper)
            remove_cmd="zypper remove -y $package"
            ;;
        pacman)
            remove_cmd="pacman -R --noconfirm $package"
            ;;
        *)
            echo -e "${RED}Unsupported package manager!${NC}"
            return 1
            ;;
    esac
    
    if [[ $EUID -ne 0 ]]; then
        remove_cmd="sudo $remove_cmd"
    fi
    
    eval "$remove_cmd"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Successfully removed $package${NC}"
        log_message "Successfully removed: $package"
        return 0
    else
        echo -e "${RED}✗ Failed to remove $package${NC}"
        log_message "ERROR: Failed to remove $package"
        return 1
    fi
}

update_system() {
    echo -e "${CYAN}Updating package lists...${NC}"
    log_message "Updating system packages"
    
    local update_cmd
    case $PACKAGE_MANAGER in
        apt)
            update_cmd="apt update"
            ;;
        dnf|yum)
            update_cmd="$PACKAGE_MANAGER check-update"
            ;;
        zypper)
            update_cmd="zypper refresh"
            ;;
        pacman)
            update_cmd="pacman -Sy"
            ;;
        *)
            echo -e "${RED}Unsupported package manager!${NC}"
            return 1
            ;;
    esac
    
    if [[ $EUID -ne 0 ]]; then
        update_cmd="sudo $update_cmd"
    fi
    
    eval "$update_cmd"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Package lists updated${NC}"
        log_message "System package lists updated"
        
        # Ask for upgrade
        echo
        echo -n "Upgrade all packages? (y/n): "
        read upgrade_confirm
        if [[ "$upgrade_confirm" == "y" || "$upgrade_confirm" == "Y" ]]; then
            upgrade_system
        fi
    else
        echo -e "${RED}✗ Failed to update package lists${NC}"
        log_message "ERROR: Failed to update package lists"
    fi
}

upgrade_system() {
    echo -e "${CYAN}Upgrading packages...${NC}"
    log_message "Upgrading system packages"
    
    local upgrade_cmd
    case $PACKAGE_MANAGER in
        apt)
            upgrade_cmd="apt upgrade -y"
            ;;
        dnf|yum)
            upgrade_cmd="$PACKAGE_MANAGER upgrade -y"
            ;;
        zypper)
            upgrade_cmd="zypper update -y"
            ;;
        pacman)
            upgrade_cmd="pacman -Su --noconfirm"
            ;;
        *)
            echo -e "${RED}Unsupported package manager!${NC}"
            return 1
            ;;
    esac
    
    if [[ $EUID -ne 0 ]]; then
        upgrade_cmd="sudo $upgrade_cmd"
    fi
    
    eval "$upgrade_cmd"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ System upgraded successfully${NC}"
        log_message "System packages upgraded"
    else
        echo -e "${RED}✗ Failed to upgrade system${NC}"
        log_message "ERROR: Failed to upgrade system"
    fi
}

search_package() {
    echo -e "${BLUE}--- Search for Package ---${NC}"
    echo
    
    local search_term
    echo -n "Enter package name to search: "
    read search_term
    
    if [[ -z "$search_term" ]]; then
        echo -e "${RED}Error: Search term cannot be empty${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Searching for '$search_term'...${NC}"
    log_message "Searching for package: $search_term"
    
    local search_cmd
    case $PACKAGE_MANAGER in
        apt)
            search_cmd="apt search $search_term"
            ;;
        dnf|yum)
            search_cmd="$PACKAGE_MANAGER search $search_term"
            ;;
        zypper)
            search_cmd="zypper search $search_term"
            ;;
        pacman)
            search_cmd="pacman -Ss $search_term"
            ;;
        *)
            echo -e "${RED}Unsupported package manager!${NC}"
            return 1
            ;;
    esac
    
    echo
    eval "$search_cmd" 2>/dev/null | head -n 20
    echo
    echo -e "${YELLOW}Showing first 20 results.${NC}"
}

show_common_packages() {
    echo -e "${BLUE}--- Common Software Packages ---${NC}"
    echo
    
    echo -e "${CYAN}Development Tools:${NC}"
    echo "  - git: Version control system"
    echo "  - build-essential: Compilers and build tools"
    echo "  - python3: Python programming language"
    echo "  - nodejs: JavaScript runtime"
    echo "  - docker: Container platform"
    echo
    
    echo -e "${CYAN}System Utilities:${NC}"
    echo "  - htop: Interactive process viewer"
    echo "  - nginx: Web server"
    echo "  - fail2ban: Intrusion prevention"
    echo "  - ufw: Firewall configuration"
    echo "  - rsync: File synchronization"
    echo
    
    echo -e "${CYAN}Network Tools:${NC}"
    echo "  - curl: Data transfer tool"
    echo "  - wget: File downloader"
    echo "  - net-tools: Network utilities"
    echo "  - nmap: Network scanner"
    echo "  - wireshark: Network analyzer"
    echo
}

# ============================================
# Main Menu
# ============================================

main() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}   Software Installer Tool${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${CYAN}Detected Package Manager: ${PACKAGE_MANAGER}${NC}"
    echo
    echo "1. Install a package"
    echo "2. Remove a package"
    echo "3. Update package lists"
    echo "4. Upgrade system"
    echo "5. Search for a package"
    echo "6. Show common packages"
    echo "7. Return to main menu"
    echo
    echo -n "Select option [1-7]: "
    read option
    
    case $option in
        1)
            echo
            echo -n "Enter package name to install: "
            read package
            
            if [[ -z "$package" ]]; then
                echo -e "${RED}Error: Package name cannot be empty${NC}"
            else
                if check_package_installed "$package"; then
                    echo -e "${YELLOW}Package '$package' is already installed${NC}"
                    log_message "Attempted to install already-installed package: $package"
                else
                    install_package "$package"
                fi
            fi
            ;;
        2)
            echo
            echo -n "Enter package name to remove: "
            read package
            
            if [[ -z "$package" ]]; then
                echo -e "${RED}Error: Package name cannot be empty${NC}"
            else
                if check_package_installed "$package"; then
                    remove_package "$package"
                else
                    echo -e "${YELLOW}Package '$package' is not installed${NC}"
                fi
            fi
            ;;
        3)
            echo
            update_system
            ;;
        4)
            echo
            upgrade_system
            ;;
        5)
            echo
            search_package
            ;;
        6)
            echo
            show_common_packages
            ;;
        7)
            return 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 2
            main
            ;;
    esac
    
    echo
    read -n 1 -s -r -p "Press any key to continue..."
}

# Run main function
main