#!/bin/bash

GITHUB_USER="PsymoNiko"
REPO_NAME="bedepacko"
INSTALL_DIR="/usr/local/bin"
BASE_URL="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME"

# Detect Linux distribution
detect_distro() {
    if command -v lsb_release >/dev/null 2>&1; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

# Fetch the correct packages.json from the corresponding branch
PACKAGE_INDEX="$BASE_URL/$DISTRO/packages/packages.json"

# Function to detect package manager
detect_package_manager() {
    if command -v apt >/dev/null; then
        echo "apt"
    elif command -v dnf >/dev/null; then
        echo "dnf"
    elif command -v pacman >/dev/null; then
        echo "pacman"
    elif command -v zypper >/dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Ensure jq is installed
if ! command -v jq >/dev/null; then
    echo "Error: 'jq' is required but not installed."
    echo "Installing jq..."
    PACKAGE_MANAGER=$(detect_package_manager)

    case "$PACKAGE_MANAGER" in
        apt) sudo apt install -y jq ;;
        dnf) sudo dnf install -y jq ;;
        pacman) sudo pacman -S --noconfirm jq ;;
        zypper) sudo zypper install -y jq ;;
        *) echo "Error: Could not install 'jq'. Please install it manually."; exit 1 ;;
    esac
fi

# Function to list available packages
list_packages() {
    echo "Fetching available packages for $DISTRO..."
    curl -s "$PACKAGE_INDEX" | jq -r 'keys[]' || echo "No package index found for $DISTRO."
}

# Function to install a package
install_package() {
    package=$1
    if [[ -z "$package" ]]; then
        echo "Usage: sudo bede install <package>"
        exit 1
    fi

    echo "Checking for '$package' in the '$DISTRO' branch..."
    data=$(curl -s "$PACKAGE_INDEX" | jq -r --arg pkg "$package" '.[$pkg]')

    if [[ "$data" != "null" ]]; then
        # Install from bede
        url=$(echo "$data" | jq -r '.url')
        dependencies=$(echo "$data" | jq -r '.dependencies[]')

        if [[ -z "$url" || "$url" == "null" ]]; then
            echo "Error: Package '$package' found in index, but no valid download URL is provided."
            exit 1
        fi

        # Install dependencies first
        if [[ -n "$dependencies" ]]; then
            echo "Installing dependencies: $dependencies"
            for dep in $dependencies; do
                sudo apt install -y $dep 2>/dev/null || \
                sudo dnf install -y $dep 2>/dev/null || \
                sudo pacman -S --noconfirm $dep 2>/dev/null || \
                sudo zypper install -y $dep 2>/dev/null || \
                echo "Warning: Failed to install dependency: $dep"
            done
        fi

        # Download and install package
        echo "Downloading $package from $url..."
        curl -sSL "$url" -o "/tmp/$package"

        if [[ ! -s "/tmp/$package" ]]; then
            echo "Error: Download failed!"
            exit 1
        fi

        echo "Installing $package to $INSTALL_DIR..."
        sudo mv "/tmp/$package" "$INSTALL_DIR/$package"
        sudo chmod +x "$INSTALL_DIR/$package"
        echo "$package installed successfully! You can now run '$package'."
        exit 0
    fi

    # If package is not in bede, suggest system package manager installation
    echo "Package '$package' not found in bede."

    PACKAGE_MANAGER=$(detect_package_manager)

    case "$PACKAGE_MANAGER" in
        apt)
            INSTALL_CMD="apt install -y $package"
            ;;
        dnf)
            INSTALL_CMD="sudo dnf install -y $package"
            ;;
        pacman)
            INSTALL_CMD="sudo pacman -S --noconfirm $package"
            ;;
        zypper)
            INSTALL_CMD="sudo zypper install -y $package"
            ;;
        *)
            echo "Error: No compatible package manager found."
            exit 1
            ;;
    esac

    echo "However, you can install it using your system package manager:"
    echo "$INSTALL_CMD"

    # Ask for confirmation before installing
    read -p "Do you want to proceed with the installation? (yes/no): " choice
    case "$choice" in
        yes|y)
            echo "Installing $package..."
            eval "$INSTALL_CMD"
            echo "$package installed successfully!"
            ;;
        *)
            echo "Installation aborted."
            ;;
    esac
}

# Function to remove a package installed from bede
remove_package() {
    package=$1
    if [[ -z "$package" ]]; then
        echo "Usage: bede remove <package>"
        exit 1
    fi

    echo "Removing $package..."
    sudo rm -f "$INSTALL_DIR/$package"
    echo "$package removed."
}

# Main command handling
case $1 in
    list) list_packages ;;
    install) install_package "$2" ;;
    remove) remove_package "$2" ;;
    *)
        echo "Usage: bede {list|install|remove} <package>"
        ;;
esac
