# BASH_AUTOMATION_TOOL
# Linux Bash Automation Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)

## 🚀 What is this?

**Linux Bash Automation Toolkit** is a menu-driven collection of shell scripts designed to automate common Linux system administration tasks. It solves the real-world problem of repetitive, time-consuming, and error-prone manual operations.

## ✨ Features

- **Backup Automation** - Create compressed, timestamped backups of directories
- **Log Manager** - Clean old logs, analyze log sizes, and search for errors
- **User Management** - Create, delete, and manage system users and groups
- **System Monitor** - Real-time CPU, memory, disk, and process monitoring
- **Software Installer** - Automated package installation with dependency checking

## 🛠 Technologies Used

- **Bash 4.0+** - Main scripting language
- **Linux CLI Tools** - grep, awk, sed, tar, rsync
- **System Commands** - useradd, systemctl, df, free, ps
- **Git** - Version control
- **Markdown** - Documentation

## 📋 Prerequisites

- Linux operating system (Ubuntu/Debian/RHEL-based)
- Bash 4.0 or higher
- Sudo/root privileges for user management and installations
- Basic understanding of command line

## 🔧 Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/bash-automation-toolkit.git

# Navigate to the toolkit directory
cd bash-automation-toolkit

# Make scripts executable
chmod +x scripts/*.sh

# Run the main menu
./scripts/main.sh
