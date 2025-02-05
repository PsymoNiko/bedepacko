#!/bin/bash

# Prompt the user for a commit message
echo "Enter your commit message:"
read commit_message

# Check if a commit message was provided
if [ -z "$commit_message" ]; then
    echo "Error: Commit message cannot be empty."
    exit 1
fi

# Add all changes
git add .

# Commit with the provided message
git commit -m "$commit_message"

# Get the current branch name
current_branch=$(git branch --show-current)

# Check if the current branch was found
if [ -z "$current_branch" ]; then
    echo "Error: Could not determine the current branch."
    exit 1
fi

# Push to the current branch
echo "Pushing changes to branch: $current_branch"
git push origin "$current_branch"
