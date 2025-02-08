#!/bin/bash

GITHUB_USER="PsymoNiko"
REPO_NAME="bedepacko"
INSTALL_DIR="/usr/local/bin"

# We assume your packages.json is in the MAIN branch of bedepacko.
PACKAGE_INDEX="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/main/packages.json"

# Retrieve the operating system information using hostnamectl.
os_line=$(hostnamectl | grep "Operating System")
# Extract the OS name by splitting on ':' and trimming whitespace.
os_info=$(echo "$os_line" | cut -d: -f2 | sed 's/^[[:space:]]*//')

echo "Detected OS: $os_info"

# Determine the default package manager based on common OS identifiers.
if [[ "$os_info" == *"Ubuntu"* || "$os_info" == *"Debian"* ]]; then
    package_manager="apt"
elif [[ "$os_info" == *"Fedora"* || "$os_info" == *"Red Hat"* || "$os_info" == *"CentOS"* ]]; then
    package_manager="dnf"
elif [[ "$os_info" == *"Arch"* ]]; then
    package_manager="pacman"
elif [[ "$os_info" == *"openSUSE"* ]]; then
    package_manager="zypper"
else
    package_manager="unknown"
fi

echo "Default Package Manager: $package_manager"
echo "The detected package manager is: $package_manager"

# Ensure 'jq' is installed for parsing JSON.
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: 'jq' is required but not installed."
    echo "Attempting to install jq..."
    case "$package_manager" in
        apt)
            sudo apt update && sudo apt install -y jq
            ;;
        dnf)
            sudo dnf install -y jq
            ;;
        pacman)
            sudo pacman -Sy --noconfirm jq
            ;;
        zypper)
            sudo zypper install -y jq
            ;;
        *)
            echo "Error: Could not install 'jq' automatically. Please install it manually."
            exit 1
            ;;
    esac
fi

# Function: list all available packages.
list_packages() {
    echo "Fetching the list of available packages..."
    curl -s "$PACKAGE_INDEX" | jq -r 'keys[]' || echo "No package index found."
}

# Function: install a package.
install_package() {
    local package="$1"
    if [[ -z "$package" ]]; then
        echo "Usage: sudo bede install <package>"
        exit 1
    fi

    # Fetch the package metadata from packages.json.
    local pkg_data
    pkg_data=$(curl -s "$PACKAGE_INDEX" | jq -r --arg pkg "$package" '.[$pkg]')

    if [[ "$pkg_data" == "null" ]]; then
        echo "Package '$package' not found in the custom index. Falling back to the system package manager..."
        # Use the globally detected package_manager variable.
        case "$package_manager" in
            apt)
                sudo apt update && sudo apt install -y "$package"
                ;;
            dnf)
                sudo dnf install -y "$package"
                ;;
            pacman)
                sudo pacman -Sy --noconfirm "$package"
                ;;
            zypper)
                sudo zypper install -y "$package"
                ;;
            *)
                echo "Error: Unsupported package manager. Please install '$package' manually."
                exit 1
                ;;
        esac
        return $?
    fi

    # Extract fields from JSON.
    local url
    local dependencies
    url=$(echo "$pkg_data" | jq -r '.url')
    dependencies=$(echo "$pkg_data" | jq -r '.dependencies[]?')  # The '?' makes the array optional.

    if [[ -z "$url" || "$url" == "null" ]]; then
        echo "Error: No valid 'url' provided for package '$package'."
        exit 1
    fi

    # Install any dependencies first.
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

    # Download the package installer to /tmp.
    echo "Downloading $package from $url..."
    curl -sSL "$url" -o "/tmp/$package"

    if [[ ! -s "/tmp/$package" ]]; then
        echo "Error: Failed to download installer for '$package'!"
        exit 1
    fi

    # Move the installer to INSTALL_DIR and make it executable.
    echo "Installing $package to $INSTALL_DIR..."
    sudo mv "/tmp/$package" "$INSTALL_DIR/$package"
    sudo chmod +x "$INSTALL_DIR/$package"

    echo "$package installed successfully! Run '$package' to use it."
}

# Function: remove a package.
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

# Main command handling.
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

