#!/bin/bash

# ============================================
# Log Management Script
# ============================================
# Description: Clean, archive, and analyze log files
# Usage: log_manager.sh
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
    
    return 0
}

validate_number() {
    local num="$1"
    if [[ "$num" =~ ^[0-9]+$ ]]; then
        return 0
    else
        echo -e "${RED}Error: Please enter a valid number${NC}"
        return 1
    fi
}

# ============================================
# Log Management Functions
# ============================================

clean_old_logs() {
    echo -e "${BLUE}--- Clean Old Log Files ---${NC}"
    echo
    
    local log_dir
    local days_old
    
    # Get directory
    while true; do
        echo -n "Enter directory to scan for logs: "
        read log_dir
        log_dir="${log_dir/#\~/$HOME}"
        
        if validate_directory "$log_dir"; then
            break
        fi
    done
    
    # Get age threshold
    while true; do
        echo -n "Delete logs older than (days): "
        read days_old
        
        if validate_number "$days_old"; then
            break
        fi
    done
    
    echo
    
    # Find old logs
    echo -e "${CYAN}Searching for log files older than $days_old days...${NC}"
    local old_logs=$(find "$log_dir" -name "*.log" -type f -mtime +$days_old 2>/dev/null)
    
    if [[ -z "$old_logs" ]]; then
        echo -e "${GREEN}No log files older than $days_old days found.${NC}"
        log_message "No old logs found in $log_dir"
        return 0
    fi
    
    # Display found files
    local count=$(echo "$old_logs" | wc -l)
    local total_size=$(find "$log_dir" -name "*.log" -type f -mtime +$days_old -exec du -ch {} + 2>/dev/null | tail -n 1 | cut -f1)
    
    echo -e "${YELLOW}Found $count log file(s) (Total size: $total_size):${NC}"
    echo "$old_logs" | head -n 10 | while read file; do
        local size=$(du -h "$file" 2>/dev/null | cut -f1)
        local date=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1)
        echo "  📄 $(basename "$file") - $size (Modified: $date)"
    done
    
    if [[ $count -gt 10 ]]; then
        echo "  ... and $(($count - 10)) more files"
    fi
    echo
    
    # Confirm deletion
    echo -n "Delete these log files? (y/n): "
    read confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Operation cancelled.${NC}"
        log_message "Log cleanup cancelled"
        return 0
    fi
    
    # Delete files
    local deleted=0
    echo "$old_logs" | while read file; do
        rm -f "$file"
        if [[ $? -eq 0 ]]; then
            ((deleted++))
        fi
    done
    
    echo -e "${GREEN}✓ Deleted $count log file(s)${NC}"
    log_message "Cleaned $count log files from $log_dir (older than $days_old days)"
}

analyze_log_sizes() {
    echo -e "${BLUE}--- Log Size Analysis ---${NC}"
    echo
    
    local log_dir
    
    # Get directory
    while true; do
        echo -n "Enter directory to analyze: "
        read log_dir
        log_dir="${log_dir/#\~/$HOME}"
        
        if validate_directory "$log_dir"; then
            break
        fi
    done
    
    echo
    
    # Find all log files
    local log_files=$(find "$log_dir" -name "*.log" -type f 2>/dev/null)
    
    if [[ -z "$log_files" ]]; then
        echo -e "${YELLOW}No log files found in $log_dir${NC}"
        log_message "No log files found for analysis in $log_dir"
        return 0
    fi
    
    # Calculate statistics
    local total_files=$(echo "$log_files" | wc -l)
    local total_size=$(find "$log_dir" -name "*.log" -type f -exec du -ch {} + 2>/dev/null | tail -n 1 | cut -f1)
    
    echo -e "${CYAN}Log Directory Analysis: $log_dir${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}Total log files: $total_files${NC}"
    echo -e "${GREEN}Total size: $total_size${NC}"
    echo
    
    echo -e "${YELLOW}Largest log files:${NC}"
    find "$log_dir" -name "*.log" -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n 10 | while read size file; do
        echo "  📊 $size - $(basename "$file")"
    done
    echo
    
    echo -e "${YELLOW}Oldest log files:${NC}"
    find "$log_dir" -name "*.log" -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | head -n 5 | while read timestamp path; do
        local date=$(date -d "@${timestamp%.*}" '+%Y-%m-%d')
        local size=$(du -h "$path" 2>/dev/null | cut -f1)
        echo "  🕐 $date - $(basename "$path") ($size)"
    done
    
    log_message "Log analysis completed for $log_dir"
}

search_log_errors() {
    echo -e "${BLUE}--- Search Logs for Errors ---${NC}"
    echo
    
    local log_file
    local search_pattern
    
    # Get log file
    while true; do
        echo -n "Enter log file to search: "
        read log_file
        log_file="${log_file/#\~/$HOME}"
        
        if [[ -z "$log_file" ]]; then
            echo -e "${RED}Error: File path cannot be empty${NC}"
            continue
        fi
        
        if [[ ! -f "$log_file" ]]; then
            echo -e "${RED}Error: File '$log_file' does not exist${NC}"
            continue
        fi
        
        break
    done
    
    echo
    
    # Get search pattern or use default
    echo -n "Enter search pattern [default: ERROR|FATAL|WARNING]: "
    read search_pattern
    
    if [[ -z "$search_pattern" ]]; then
        search_pattern="ERROR\|FATAL\|WARNING"
    fi
    
    echo
    echo -e "${CYAN}Searching for '$search_pattern' in $(basename "$log_file")...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Search for patterns
    local matches=$(grep -E -i "$search_pattern" "$log_file" 2>/dev/null)
    
    if [[ -z "$matches" ]]; then
        echo -e "${GREEN}No matches found for pattern '$search_pattern'${NC}"
        log_message "No matches found in $log_file for pattern: $search_pattern"
    else
        local count=$(echo "$matches" | wc -l)
        echo -e "${YELLOW}Found $count match(es):${NC}"
        echo
        echo "$matches" | head -n 20 | while read line; do
            echo -e "${RED}  ⚠ $line${NC}"
        done
        
        if [[ $count -gt 20 ]]; then
            echo -e "${YELLOW}  ... and $(($count - 20)) more matches${NC}"
        fi
        echo
        echo -n "Save results to file? (y/n): "
        read save_confirm
        if [[ "$save_confirm" == "y" || "$save_confirm" == "Y" ]]; then
            local output_file="error_report_$(date '+%Y%m%d_%H%M%S').txt"
            echo "$matches" > "$output_file"
            echo -e "${GREEN}Results saved to $output_file${NC}"
            log_message "Error search results saved to $output_file"
        fi
    fi
    
    log_message "Searched $log_file for pattern: $search_pattern"
}

# ============================================
# Main Menu
# ============================================

main() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}   Log Management Tool${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo "1. Clean old log files"
    echo "2. Analyze log sizes"
    echo "3. Search logs for errors"
    echo "4. Return to main menu"
    echo
    echo -n "Select option [1-4]: "
    read option
    
    case $option in
        1)
            clean_old_logs
            ;;
        2)
            analyze_log_sizes
            ;;
        3)
            search_log_errors
            ;;
        4)
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