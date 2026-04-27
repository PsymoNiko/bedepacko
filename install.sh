#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logo
echo -e "${GREEN}"
cat << "EOF"
  ██████╗ ███████╗██████╗ ███████╗██████╗  █████╗  ██████╗██╗  ██╗ ██████╗ 
  ██╔══██╗██╔════╝██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔═══██╗
  ██████╔╝█████╗  ██║  ██║█████╗  ██████╔╝███████║██║     █████╔╝ ██║   ██║
  ██╔══██╗██╔══╝  ██║  ██║██╔══╝  ██╔═══╝ ██╔══██║██║     ██╔═██╗ ██║   ██║
  ██████╔╝███████╗██████╔╝███████╗██║     ██║  ██║╚██████╗██║  ██╗╚██████╔╝
  ╚═════╝ ╚══════╝╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ 
EOF
echo -e "${NC}"
echo "bedepacko installer – fast, safe, Rust-powered package manager"
echo "================================================================"

# Check internet connectivity
check_internet() {
    if ping -c 1 google.com &> /dev/null || curl -s --head https://rustup.rs &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Install Rust using system package manager (fallback)
install_rust_system() {
    echo -e "${YELLOW}→${NC} No internet or rustup failed. Trying system package manager..."
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y cargo
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y cargo
    elif command -v yum &> /dev/null; then
        sudo yum install -y cargo
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm rust
    else
        echo -e "${RED}✗${NC} Could not install Rust automatically. Please install Rust manually: https://rustup.rs/"
        exit 1
    fi
}

# Main Rust installation logic
install_rust() {
    if command -v cargo &> /dev/null; then
        echo -e "${GREEN}✓${NC} Rust already present: $(cargo --version)"
        return
    fi

    echo -e "${YELLOW}→${NC} Rust not found. Attempting to install..."

    if check_internet; then
        echo "Internet detected. Installing via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # Source cargo environment – handle root vs normal user
        if [ "$EUID" -eq 0 ]; then
            # Running as root
            source /root/.cargo/env
        else
            source "$HOME/.cargo/env"
        fi
    else
        echo -e "${YELLOW}⚠${NC} No internet connection. Falling back to system packages."
        install_rust_system
    fi

    # Verify again
    if ! command -v cargo &> /dev/null; then
        echo -e "${RED}✗${NC} Rust installation failed. Please install manually: https://rustup.rs/"
        exit 1
    else
        echo -e "${GREEN}✓${NC} Rust installed: $(cargo --version)"
    fi
}

# Build the engine
build_engine() {
    echo -e "${YELLOW}→${NC} Building bede-engine (release mode)..."
    cd "$(dirname "$0")/bede-engine"
    cargo build --release
    cd - > /dev/null
    echo -e "${GREEN}✓${NC} Build complete"
}

# Install binaries
install_binaries() {
    echo -e "${YELLOW}→${NC} Installing binaries to /usr/local/bin..."
    # If not root, use sudo
    if [ "$EUID" -ne 0 ]; then
        sudo cp "$(dirname "$0")/bede.sh" /usr/local/bin/bede
        sudo cp "$(dirname "$0")/bede-engine/target/release/bede-engine" /usr/local/bin/
        sudo chmod +x /usr/local/bin/bede /usr/local/bin/bede-engine
    else
        cp "$(dirname "$0")/bede.sh" /usr/local/bin/bede
        cp "$(dirname "$0")/bede-engine/target/release/bede-engine" /usr/local/bin/
        chmod +x /usr/local/bin/bede /usr/local/bin/bede-engine
    fi
    echo -e "${GREEN}✓${NC} Binaries installed"
}

# Create directories
create_dirs() {
    echo -e "${YELLOW}→${NC} Creating data directories..."
    mkdir -p "$HOME/.local/share/bedepacko"/{engine,installed,downloads}
    echo -e "${GREEN}✓${NC} Directories ready"
}

# Create sample repo.json
create_sample_repo() {
    local repo_file="$HOME/.local/share/bedepacko/repo.json"
    if [ ! -f "$repo_file" ]; then
        echo -e "${YELLOW}→${NC} Creating sample package database..."
        cat > "$repo_file" << 'EOF'
[
  {
    "name": "nmap",
    "version": "7.95",
    "dependencies": {},
    "download_url": "https://example.com/nmap-7.95.pkg",
    "sha256": "0000000000000000000000000000000000000000000000000000000000000000"
  }
]
EOF
        echo -e "${YELLOW}⚠${NC} Sample repo.json created. Replace with real package data!"
    else
        echo -e "${GREEN}✓${NC} Existing repo.json found"
    fi
}

# Verify
verify() {
    echo -e "${YELLOW}→${NC} Verifying installation..."
    if command -v bede &> /dev/null; then
        echo -e "${GREEN}✓${NC} 'bede' command is available"
        bede chi
    else
        echo -e "${RED}✗${NC} Installation failed – 'bede' not in PATH"
        exit 1
    fi
}

# Main
main() {
    install_rust
    build_engine
    install_binaries
    create_dirs
    create_sample_repo
    verify
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}bedepacko installed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo "Try: bede chi / bede biad <pkg> / bede bere <pkg>"
}

main