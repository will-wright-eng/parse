#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path-to-binary>"
    exit 1
fi

binary_path="$1"
binary_name=$(basename "$binary_path")
target_path="/usr/local/bin/$binary_name"

# Check if binary exists
if [ ! -f "$binary_path" ]; then
    echo "Error: Binary file not found: $binary_path"
    exit 1
fi

# Make binary executable
chmod +x "$binary_path"

# Check if binary already exists in target location
if [ -f "$target_path" ]; then
    read -p "Warning: $binary_name already exists in /usr/local/bin. Overwrite? (y/N) " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 1
    fi
    # Remove existing binary if overwriting
    sudo rm "$target_path"
fi

# Copy binary to /usr/local/bin (instead of moving)
sudo cp "$binary_path" "$target_path"

if [ $? -eq 0 ]; then
    echo "Successfully installed $binary_name to /usr/local/bin"
else
    echo "Error: Failed to install binary"
    exit 1
fi
