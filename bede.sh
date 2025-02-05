#!/bin/bash

GITHUB_USER="PsymoNiko"
REPO_NAME="bedepacko"
INSTALL_DIR="/usr/local/bin"
BASE_URL="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME"

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

install_package() {
    package=$1
    if [[ -z "$package" ]]; then
        echo "Usage: sudo bede install <package>"
        exit 1
    fi

    PACKAGE_SCRIPT_URL="$BASE_URL/$DISTRO/packages/$package/install.sh"

    if curl --output /dev/null --silent --head --fail "$PACKAGE_SCRIPT_URL"; then
        echo "Downloading and installing $package..."
        curl -sSL "$PACKAGE_SCRIPT_URL" | sudo bash
        echo "$package installed successfully!"
    else
        echo "Package '$package' not found for '$DISTRO'."
    fi
}

case $1 in
    install) install_package "$2" ;;
    *) echo "Usage: bede {install} <package>" ;;
esac
