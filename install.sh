#!/bin/bash
set -e  # exit on error

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logo (keep as requested)
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

# Function to detect OS and package manager
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt &> /dev/null; then
            PKG_MANAGER="apt"
        elif command -v dnf &> /dev/null; then
            PKG_MANAGER="dnf"
        elif command -v yum &> /dev/null; then
            PKG_MANAGER="yum"
        else
            PKG_MANAGER="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        if command -v brew &> /dev/null; then
            PKG_MANAGER="brew"
        else
            PKG_MANAGER="unknown"
        fi
    else
        OS="unknown"
        PKG_MANAGER="unknown"
    fi
    echo -e "${GREEN}✓${NC} Detected OS: $OS, Package manager: $PKG_MANAGER"
}

# Install Rust if missing
install_rust() {
    if ! command -v cargo &> /dev/null; then
        echo -e "${YELLOW}→${NC} Rust not found. Installing via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        echo -e "${GREEN}✓${NC} Rust installed successfully"
    else
        echo -e "${GREEN}✓${NC} Rust already present: $(cargo --version)"
    fi
}

# Build bede-engine
build_engine() {
    echo -e "${YELLOW}→${NC} Building bede-engine (release mode)..."
    cd "$(dirname "$0")/bede-engine"
    cargo build --release
    cd - > /dev/null
    echo -e "${GREEN}✓${NC} Build complete"
}

# Install binaries system-wide
install_binaries() {
    echo -e "${YELLOW}→${NC} Installing binaries to /usr/local/bin..."
    sudo cp "$(dirname "$0")/bede.sh" /usr/local/bin/bede
    sudo cp "$(dirname "$0")/bede-engine/target/release/bede-engine" /usr/local/bin/
    sudo chmod +x /usr/local/bin/bede /usr/local/bin/bede-engine
    echo -e "${GREEN}✓${NC} Binaries installed"
}

# Create data directories
create_dirs() {
    echo -e "${YELLOW}→${NC} Creating data directories in ~/.local/share/bedepacko..."
    mkdir -p "$HOME/.local/share/bedepacko"/{engine,installed,downloads}
    echo -e "${GREEN}✓${NC} Directories ready"
}

# Create sample repo.json if none exists
create_sample_repo() {
    REPO_FILE="$HOME/.local/share/bedepacko/repo.json"
    if [ ! -f "$REPO_FILE" ]; then
        echo -e "${YELLOW}→${NC} Creating sample package database (repo.json)..."
        cat > "$REPO_FILE" << 'EOF'
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
        echo -e "${YELLOW}⚠${NC} Sample repo.json created. Replace with real package metadata!"
    else
        echo -e "${GREEN}✓${NC} Existing repo.json found"
    fi
}

# Verify installation
verify() {
    echo -e "${YELLOW}→${NC} Verifying installation..."
    if command -v bede &> /dev/null; then
        echo -e "${GREEN}✓${NC} 'bede' command is available"
        bede chi
    else
        echo -e "${RED}✗${NC} Installation failed – 'bede' not found in PATH"
        exit 1
    fi
}

# Main execution
main() {
    detect_os
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
    echo "Try these commands:"
    echo "  bede chi                # list installed packages"
    echo "  bede biad <package>     # install a package"
    echo "  bede bere <package>     # remove a package"
    echo ""
    echo "For help: bede --help"
}

# Run the script
main