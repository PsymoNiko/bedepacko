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

# Function to try system package manager first
install_rust_system() {
    echo -e "${YELLOW}→${NC} Attempting to install Rust via system package manager..."
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
        echo -e "${RED}✗${NC} No supported package manager found for Rust installation."
        return 1
    fi
}

# Function to try rustup (if system method fails or user wants latest)
install_rust_rustup() {
    echo -e "${YELLOW}→${NC} Trying rustup (official installer)..."
    # Use a mirror or retry logic
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        echo -e "${RED}✗${NC} rustup installation failed."
        return 1
    fi
    # Add cargo to PATH for this script
    export PATH="$HOME/.cargo/bin:$PATH"
    echo -e "${GREEN}✓${NC} Rust installed via rustup"
}

# Main Rust installation
install_rust() {
    if command -v cargo &> /dev/null; then
        echo -e "${GREEN}✓${NC} Rust already present: $(cargo --version)"
        return
    fi

    echo -e "${YELLOW}→${NC} Rust not found."

    # Always try system package manager first (more reliable on servers)
    if install_rust_system; then
        if command -v cargo &> /dev/null; then
            echo -e "${GREEN}✓${NC} Rust installed via system packages: $(cargo --version)"
            return
        fi
    fi

    # If system method failed, try rustup
    if install_rust_rustup; then
        return
    fi

    # Both failed
    echo -e "${RED}✗${NC} Could not install Rust. Please install manually: https://rustup.rs/"
    exit 1
}

# Build the engine
build_engine() {
    echo -e "${YELLOW}→${NC} Building bede-engine (release mode)..."
    cd "$(dirname "$0")/bede-engine"
    # Ensure cargo is in PATH (for rustup case)
    export PATH="$HOME/.cargo/bin:$PATH"
    cargo build --release
    cd - > /dev/null
    echo -e "${GREEN}✓${NC} Build complete"
}

# Install binaries
install_binaries() {
    echo -e "${YELLOW}→${NC} Installing binaries to /usr/local/bin..."
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

# Create data directories
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