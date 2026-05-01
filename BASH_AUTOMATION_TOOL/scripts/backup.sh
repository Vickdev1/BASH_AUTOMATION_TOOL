#!/bin/bash

# ============================================
# Backup Automation Script
# ============================================
# Description: Creates compressed backups of directories
# Usage: backup.sh
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../logs/toolkit.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# Helper Functions
# ============================================

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

validate_directory() {
    local dir="$1"
    if [[ -z "$dir" ]]; then
        echo -e "${RED}Error: Directory path cannot be empty${NC}"
        return 1
    fi
    
    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}Error: Directory '$dir' does not exist${NC}"
        return 1
    fi
    
    if [[ ! -r "$dir" ]]; then
        echo -e "${RED}Error: No read permission for '$dir'${NC}"
        return 1
    fi
    
    return 0
}

validate_destination() {
    local dest="$1"
    if [[ -z "$dest" ]]; then
        echo -e "${RED}Error: Destination path cannot be empty${NC}"
        return 1
    fi
    
    # Create destination if it doesn't exist
    if [[ ! -d "$dest" ]]; then
        echo -e "${YELLOW}Destination directory does not exist. Creating...${NC}"
        mkdir -p "$dest"
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Error: Could not create destination directory${NC}"
            return 1
        fi
    fi
    
    if [[ ! -w "$dest" ]]; then
        echo -e "${RED}Error: No write permission for '$dest'${NC}"
        return 1
    fi
    
    return 0
}

get_backup_name() {
    local source_dir="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local dir_name=$(basename "$source_dir")
    echo "backup_${dir_name}_${timestamp}.tar.gz"
}

perform_backup() {
    local source_dir="$1"
    local dest_dir="$2"
    local backup_name="$3"
    local backup_path="$dest_dir/$backup_name"
    
    echo -e "${BLUE}Creating backup...${NC}"
    echo "Source: $source_dir"
    echo "Destination: $backup_path"
    echo
    
    # Create compressed archive
    tar -czf "$backup_path" -C "$(dirname "$source_dir")" "$(basename "$source_dir")" 2>/dev/null
    
    if [[ $? -eq 0 && -f "$backup_path" ]]; then
        local size=$(du -h "$backup_path" | cut -f1)
        echo -e "${GREEN}✓ Backup completed successfully!${NC}"
        echo -e "${GREEN}Backup size: $size${NC}"
        echo -e "${GREEN}Location: $backup_path${NC}"
        log_message "Backup created: $backup_path (Size: $size)"
        return 0
    else
        echo -e "${RED}✗ Backup failed!${NC}"
        log_message "ERROR: Backup failed for $source_dir"
        return 1
    fi
}

list_recent_backups() {
    local dest_dir="$1"
    echo -e "${BLUE}Recent backups in $dest_dir:${NC}"
    echo
    
    local backups=$(find "$dest_dir" -name "backup_*.tar.gz" -type f -printf "%T@ %p\n" 2>/dev/null | sort -rn | head -n 5)
    
    if [[ -z "$backups" ]]; then
        echo "No existing backups found."
    else
        echo "$backups" | while read timestamp path; do
            local date=$(date -d "@${timestamp%.*}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
            local size=$(du -h "$path" | cut -f1)
            echo "  📦 $(basename "$path") - $size (Created: $date)"
        done
    fi
    echo
}

# ============================================
# Main Backup Function
# ============================================

main() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}   Backup Automation Tool${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # Get source directory
    while true; do
        echo -n "Enter source directory to backup: "
        read source_dir
        
        # Expand tilde to home directory
        source_dir="${source_dir/#\~/$HOME}"
        
        if validate_directory "$source_dir"; then
            break
        fi
        echo "Please try again."
    done
    
    echo
    
    # Get destination directory
    while true; do
        echo -n "Enter destination directory for backup: "
        read dest_dir
        
        dest_dir="${dest_dir/#\~/$HOME}"
        
        if validate_destination "$dest_dir"; then
            break
        fi
        echo "Please try again."
    done
    
    echo
    
    # Show recent backups
    list_recent_backups "$dest_dir"
    
    # Confirm backup
    echo -n "Proceed with backup? (y/n): "
    read confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Backup cancelled.${NC}"
        log_message "Backup cancelled by user"
        return 0
    fi
    
    # Perform backup
    local backup_name=$(get_backup_name "$source_dir")
    perform_backup "$source_dir" "$dest_dir" "$backup_name"
}

# Run main function
main