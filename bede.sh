#!/bin/bash
# bede.sh – wrapper for bedepacko with custom commands

set -e

ENGINE_DIR="$HOME/.local/share/bedepacko/engine"
ENGINE_BIN="$ENGINE_DIR/target/release/bede-engine"
REPO_URL="https://raw.githubusercontent.com/PsymoNiko/bedepacko/main/repo.json"   # change to your actual repo URL
INSTALL_DIR="$HOME/.local/share/bedepacko/installed"
DOWNLOADS_DIR="$HOME/.local/share/bedepacko/downloads"

# Build the engine if missing
if [ ! -f "$ENGINE_BIN" ]; then
    echo "First run: building bede-engine (requires cargo) ..."
    mkdir -p "$ENGINE_DIR"
    # Clone only the engine subdirectory (adjust if your repo structure differs)
    git clone --depth 1 https://github.com/PsymoNiko/bedepacko.git /tmp/bedepacko-tmp
    cp -r /tmp/bedepacko-tmp/bede-engine "$ENGINE_DIR/"
    cd "$ENGINE_DIR/bede-engine"
    cargo build --release
    cd - > /dev/null
    rm -rf /tmp/bedepacko-tmp
    echo "Build complete."
fi

# Ensure directories exist
mkdir -p "$INSTALL_DIR" "$DOWNLOADS_DIR"

# Download package database if needed
if [ ! -f "$HOME/.local/share/bedepacko/repo.json" ]; then
    echo "Fetching package database..."
    curl -s "$REPO_URL" -o "$HOME/.local/share/bedepacko/repo.json"
fi

# Command mapping
case "$1" in
    biad|install)
        shift
        # Use the engine to download packages
        "$ENGINE_BIN" fetch --repo "$HOME/.local/share/bedepacko/repo.json" --dest "$DOWNLOADS_DIR" --packages "$@"
        # For each downloaded package, extract/install to INSTALL_DIR
        # (You'll need to add your extraction logic here – example for .tar.gz)
        for pkg in "$@"; do
            # find the downloaded file (simplistic)
            found=$(find "$DOWNLOADS_DIR" -name "${pkg}-*.pkg" | head -1)
            if [ -n "$found" ]; then
                mkdir -p "$INSTALL_DIR/$pkg"
                # extract logic depends on your package format
                echo "Installed $pkg (extraction not implemented – add your own)"
            else
                echo "Download for $pkg not found"
            fi
        done
        ;;
    bere|remove)
        shift
        "$ENGINE_BIN" remove "$@"
        ;;
    chi|list)
        "$ENGINE_BIN" list
        ;;
    resolve)
        shift
        "$ENGINE_BIN" resolve "$@"
        ;;
    lock)
        shift
        "$ENGINE_BIN" lock "$@"
        ;;
    *)
        echo "Usage: bede {biad|install|bere|remove|chi|list|resolve|lock} ..."
        exit 1
        ;;
esac
