#!/bin/bash

GITHUB_USER="PsymoNiko"
REPO_NAME="bedepacko"
INSTALL_DIR="/usr/local/bin"

# We assume your packages.json is in the MAIN branch of bedepacko
PACKAGE_INDEX="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/main/packages.json"

# Function to detect the system package manager
detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Ensure 'jq' is installed for parsing JSON
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: 'jq' is required but not installed."
    echo "Attempting to install jq..."
    PACKAGE_MANAGER=$(detect_package_manager)

    case "$PACKAGE_MANAGER" in
        apt)    sudo apt update && sudo apt install -y jq ;;
        dnf)    sudo dnf install -y jq ;;
        pacman) sudo pacman -Sy --noconfirm jq ;;
        zypper) sudo zypper install -y jq ;;
        *)
            echo "Error: Could not install 'jq' automatically. Please install it manually."
            exit 1
            ;;
    esac
fi

# Function: list all available packages
list_packages() {
    echo "Fetching the list of available packages..."
    curl -s "$PACKAGE_INDEX" | jq -r 'keys[]' || echo "No package index found."
}

# Function: install a package
install_package() {
    local package="$1"
    if [[ -z "$package" ]]; then
        echo "Usage: sudo bede install <package>"
        exit 1
    fi

    # Fetch the package metadata from packages.json
    local pkg_data
    pkg_data=$(curl -s "$PACKAGE_INDEX" | jq -r --arg pkg "$package" '.[$pkg]')

    # Check if the package exists
    if [[ "$pkg_data" == "null" ]]; then
        echo "Error: Package '$package' not found in the index."
        exit 1
    fi

    # Extract fields from JSON
    local url
    local dependencies
    url=$(echo "$pkg_data" | jq -r '.url')
    dependencies=$(echo "$pkg_data" | jq -r '.dependencies[]?')  # ? = optional in case there's no dependencies array

    if [[ -z "$url" || "$url" == "null" ]]; then
        echo "Error: No valid 'url' provided for $package."
        exit 1
    fi

    # Install any dependencies first
    if [[ -n "$dependencies" ]]; then
        echo "Installing dependencies: $dependencies"
        for dep in $dependencies; do
            sudo apt install -y "$dep" 2>/dev/null || \
            sudo dnf install -y "$dep" 2>/dev/null || \
            sudo pacman -S --noconfirm "$dep" 2>/dev/null || \
            sudo zypper install -y "$dep" 2>/dev/null || \
            echo "Warning: Failed to install dependency: $dep"
        done
    fi

    # Download the package installer to /tmp
    echo "Downloading $package from $url..."
    curl -sSL "$url" -o "/tmp/$package"

    if [[ ! -s "/tmp/$package" ]]; then
        echo "Error: Failed to download installer!"
        exit 1
    fi

    # Move the script to /usr/local/bin and make it executable
    echo "Installing $package to $INSTALL_DIR..."
    sudo mv "/tmp/$package" "$INSTALL_DIR/$package"
    sudo chmod +x "$INSTALL_DIR/$package"

    echo "$package installed successfully! Run '$package' to use it."
}

# Function: remove a package
remove_package() {
    local package="$1"
    if [[ -z "$package" ]]; then
        echo "Usage: bede remove <package>"
        exit 1
    fi

    echo "Removing $package from $INSTALL_DIR..."
    sudo rm -f "$INSTALL_DIR/$package"
    echo "$package removed."
}

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Clear the terminal
clear

# Print "Bede" in different colors
echo -e "${RED}$(figlet Bede)${NC}"
# Main command handling
case "$1" in
    list)
        list_packages
        ;;
    install)
        install_package "$2"
        ;;
    remove)
        remove_package "$2"
        ;;
    *)
        echo "Usage: bede {list|install|remove} <package>"
        ;;
esac
