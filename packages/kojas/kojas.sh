#!/bin/bash

# Define color codes
GREEN='\033[0;32m'   # Green for folders
YELLOW='\033[0;33m'  # Yellow for files
BLUE='\033[0;34m'    # Blue for text matches
NC='\033[0m'         # No Color

# Check if the user provided a name
if [ "$#" -lt 1 ]; then
    echo "Usage: kojas <name> [-f | -F | -t]"
    exit 1
fi

name="$1"
shift

# Initialize search type
search_type="all"

# Parse options
while getopts "fFt" opt; do
    case $opt in
        f) search_type="file" ;;
        F) search_type="folder" ;;
        t) search_type="text" ;;
        *) echo "Invalid option"; exit 1 ;;
    esac
done

# Function to search for folders
search_folders() {
    find . -type d -name "*$name*" -print | while read -r dir; do
        echo -e "${GREEN}$dir${NC}"
    done
}

# Function to search for files
search_files() {
    find . -type f -name "*$name*" -print | while read -r file; do
        echo -e "${YELLOW}$file${NC}"
    done
}

# Function to search for text matches
search_text() {
    find . -type f -exec grep -H --color=never "$name" {} \; 2>/dev/null | while read -r line; do
        echo -e "${BLUE}$line${NC}"
    done
}

# Perform the search based on the specified type
case $search_type in
    "folder") search_folders ;;
    "file") search_files ;;
    "text") search_text ;;
    "all") 
        search_folders
        search_files
        search_text
        ;;
esac

