#!/bin/bash
set -e

INSTALL_DIR="/usr/local/bin"
REPO_URL="https://github.com/PsymoNiko/bedepacko.git"
CLONE_PATH="/tmp/bedepacko_install"

echo "Installing bede package manager..."

# Check for Rust and Cargo
if ! command -v cargo &> /dev/null; then
    echo "Error: Rust/Cargo is not installed. Please install Rust first: https://rustup.rs/"
    exit 1
fi

# Clone and build the project
git clone --depth 1 "$REPO_URL" "$CLONE_PATH"
cd "$CLONE_PATH/bede-engine"
cargo build --release
cd - > /dev/null

# Install the binaries
sudo cp "$CLONE_PATH/bede-engine/target/release/bede-engine" "$INSTALL_DIR/"
sudo cp "$CLONE_PATH/bede.sh" "$INSTALL_DIR/bede"
sudo chmod +x "$INSTALL_DIR/bede" "$INSTALL_DIR/bede-engine"

# Clean up
rm -rf "$CLONE_PATH"

echo "Installation complete! You can now run 'bede'."
