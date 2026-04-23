#!/bin/bash
# bede.sh – now just a thin wrapper around bede-engine

BEDE_ENGINE="./bede-engine/target/release/bede-engine"
REPO_URL="https://your-repo.com/packages.json"

# Ensure engine is built
if [ ! -f "$BEDE_ENGINE" ]; then
    echo "Building bede-engine..."
    (cd bede-engine && cargo build --release)
fi

# Download package database if needed
if [ ! -f "repo.json" ]; then
    curl -s "$REPO_URL" -o repo.json
fi

case "$1" in
    install)
        shift
        echo "Fetching $* ..."
        "$BEDE_ENGINE" fetch --packages "$@" --dest ./downloads
        # your existing extraction/installation logic here
        ;;
    resolve)
        shift
        "$BEDE_ENGINE" resolve "$@"
        ;;
    lock)
        shift
        "$BEDE_ENGINE" lock "$@"
        ;;
    *)
        echo "Usage: bede {install|resolve|lock} ..."
        exit 1
        ;;
esac
