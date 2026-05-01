#!/bin/bash

# ============================================
# User Management Script
# ============================================
# Description: Create, delete, and manage system users
# Usage: user_manager.sh (requires root/sudo)
# ============================================

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "\033[0;31mError: This script must be run as root or with sudo!\033[0m"
   echo "Please run: sudo $0"
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../logs/toolkit.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================
# Helper Functions
# ============================================

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

validate_username() {
    local username="$1"
    
    # Check if empty
    if [[ -z "$username" ]]; then
        echo -e "${RED}Error: Username cannot be empty${NC}"
        return 1
    fi
    
    # Check length (typically 1-32 characters)
    if [[ ${#username} -lt 1 ]] || [[ ${#username} -gt 32 ]]; then
        echo -e "${RED}Error: Username must be between 1-32 characters${NC}"
        return 1
    fi
    
    # Check for valid characters (only alphanumeric and underscore)
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo -e "${RED}Error: Username must start with a letter or underscore and contain only lowercase letters, numbers, hyphens, or underscores${NC}"
        return 1
    fi
    
    return 0
}

user_exists() {
    local username="$1"
    if id "$username" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ============================================
# User Management Functions
# ============================================

create_user() {
    echo -e "${BLUE}--- Create New User ---${NC}"
    echo
    
    local username
    local fullname
    local password
    
    # Get username
    while true; do
        echo -n "Enter username: "
        read username
        
        if validate_username "$username"; then
            if user_exists "$username"; then
                echo -e "${RED}Error: User '$username' already exists${NC}"
                continue
            fi
            break
        fi
    done
    
    # Get full name (optional)
    echo -n "Enter full name (optional): "
    read fullname
    
    # Get password
    while true; do
        echo -n "Enter password: "
        read -s password
        echo
        
        if [[ -z "$password" ]]; then
            echo -e "${RED}Error: Password cannot be empty${NC}"
            continue
        fi
        
        echo -n "Confirm password: "
        read -s password_confirm
        echo
        
        if [[ "$password" != "$password_confirm" ]]; then
            echo -e "${RED}Error: Passwords do not match${NC}"
            continue
        fi
        break
    done
    
    echo
    echo -e "${CYAN}Creating user '$username'...${NC}"
    
    # Create user
    if [[ -n "$fullname" ]]; then
        useradd -m -c "$fullname" -s /bin/bash "$username"
    else
        useradd -m -s /bin/bash "$username"
    fi
    
    if [[ $? -eq 0 ]]; then
        echo "$username:$password" | chpasswd
        echo -e "${GREEN}✓ User '$username' created successfully!${NC}"
        echo -e "  Home directory: /home/$username"
        echo -e "  Shell: /bin/bash"
        log_message "User created: $username (Full name: $fullname)"
    else
        echo -e "${RED}✗ Failed to create user '$username'${NC}"
        log_message "ERROR: Failed to create user $username"
        return 1
    fi
    
    # Ask to add to groups
    echo
    echo -n "Add user to additional groups? (y/n): "
    read add_groups
    if [[ "$add_groups" == "y" || "$add_groups" == "Y" ]]; then
        echo -n "Enter groups (comma-separated, e.g., sudo,developers): "
        read groups
        if [[ -n "$groups" ]]; then
            usermod -aG "$groups" "$username"
            echo -e "${GREEN}✓ User added to groups: $groups${NC}"
            log_message "User $username added to groups: $groups"
        fi
    fi
}

delete_user() {
    echo -e "${BLUE}--- Delete User ---${NC}"
    echo
    
    local username
    
    # Get username
    while true; do
        echo -n "Enter username to delete: "
        read username
        
        if validate_username "$username"; then
            if ! user_exists "$username"; then
                echo -e "${RED}Error: User '$username' does not exist${NC}"
                continue
            fi
            break
        fi
    done
    
    # Show user info
    echo
    echo -e "${CYAN}User Information:${NC}"
    echo "  Username: $username"
    echo "  UID: $(id -u $username)"
    echo "  Home: $(eval echo ~$username)"
    echo "  Groups: $(id -Gn $username | tr ' ' ',')"
    echo
    
    # Confirm deletion
    echo -e "${RED}WARNING: This will delete user '$username' and their home directory!${NC}"
    echo -n "Are you sure? (y/n): "
    read confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Deletion cancelled.${NC}"
        log_message "User deletion cancelled for $username"
        return 0
    fi
    
    # Ask about home directory
    echo
    echo -n "Delete home directory? (y/n): "
    read delete_home
    
    # Delete user
    if [[ "$delete_home" == "y" || "$delete_home" == "Y" ]]; then
        userdel -r "$username"
    else
        userdel "$username"
    fi
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ User '$username' deleted successfully!${NC}"
        log_message "User deleted: $username (Home deleted: $delete_home)"
    else
        echo -e "${RED}✗ Failed to delete user '$username'${NC}"
        log_message "ERROR: Failed to delete user $username"
        return 1
    fi
}

manage_user_groups() {
    echo -e "${BLUE}--- Manage User Groups ---${NC}"
    echo
    
    local username
    
    # Get username
    while true; do
        echo -n "Enter username: "
        read username
        
        if validate_username "$username"; then
            if ! user_exists "$username"; then
                echo -e "${RED}Error: User '$username' does not exist${NC}"
                continue
            fi
            break
        fi
    done
    
    echo
    echo -e "${CYAN}Current groups for $username:${NC}"
    echo "  $(id -Gn $username | tr ' ' ',')"
    echo
    
    echo "1. Add user to group"
    echo "2. Remove user from group"
    echo "3. Return"
    echo
    echo -n "Select option [1-3]: "
    read group_option
    
    case $group_option in
        1)
            echo -n "Enter group name to add: "
            read group_name
            if [[ -n "$group_name" ]]; then
                usermod -aG "$group_name" "$username"
                if [[ $? -eq 0 ]]; then
                    echo -e "${GREEN}✓ User added to group '$group_name'${NC}"
                    log_message "User $username added to group $group_name"
                else
                    echo -e "${RED}✗ Failed to add user to group '$group_name'${NC}"
                fi
            fi
            ;;
        2)
            echo -n "Enter group name to remove from: "
            read group_name
            if [[ -n "$group_name" ]]; then
                gpasswd -d "$username" "$group_name"
                if [[ $? -eq 0 ]]; then
                    echo -e "${GREEN}✓ User removed from group '$group_name'${NC}"
                    log_message "User $username removed from group $group_name"
                else
                    echo -e "${RED}✗ Failed to remove user from group '$group_name'${NC}"
                fi
            fi
            ;;
        3)
            return 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
}

change_user_password() {
    echo -e "${BLUE}--- Change User Password ---${NC}"
    echo
    
    local username
    
    # Get username
    while true; do
        echo -n "Enter username: "
        read username
        
        if validate_username "$username"; then
            if ! user_exists "$username"; then
                echo -e "${RED}Error: User '$username' does not exist${NC}"
                continue
            fi
            break
        fi
    done
    
    echo
    local new_password
    local password_confirm
    
    while true; do
        echo -n "Enter new password: "
        read -s new_password
        echo
        
        if [[ -z "$new_password" ]]; then
            echo -e "${RED}Error: Password cannot be empty${NC}"
            continue
        fi
        
        echo -n "Confirm new password: "
        read -s password_confirm
        echo
        
        if [[ "$new_password" != "$password_confirm" ]]; then
            echo -e "${RED}Error: Passwords do not match${NC}"
            continue
        fi
        break
    done
    
    echo "$username:$new_password" | chpasswd
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Password changed successfully for user '$username'${NC}"
        log_message "Password changed for user $username"
    else
        echo -e "${RED}✗ Failed to change password for user '$username'${NC}"
        log_message "ERROR: Failed to change password for $username"
    fi
}

list_users() {
    echo -e "${BLUE}--- System Users ---${NC}"
    echo
    
    echo -e "${CYAN}Regular users (UID >= 1000):${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    awk -F: '$3 >= 1000 && $3 < 65534 {printf "  %-15s UID: %-5s Home: %s\n", $1, $3, $6}' /etc/passwd
    echo
    echo -e "${YELLOW}Total regular users: $(awk -F: '$3 >= 1000 && $3 < 65534' /etc/passwd | wc -l)${NC}"
    
    log_message "Listed system users"
}

# ============================================
# Main Menu
# ============================================

main() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}   User Management Tool${NC}"
    echo -e "${RED}   (Running with root privileges)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo "1. Create new user"
    echo "2. Delete user"
    echo "3. Manage user groups"
    echo "4. Change user password"
    echo "5. List all users"
    echo "6. Return to main menu"
    echo
    echo -n "Select option [1-6]: "
    read option
    
    case $option in
        1)
            create_user
            ;;
        2)
            delete_user
            ;;
        3)
            manage_user_groups
            ;;
        4)
            change_user_password
            ;;
        5)
            list_users
            ;;
        6)
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