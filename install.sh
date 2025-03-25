#!/bin/bash

# Create ~/.local directory if it doesn't exist
mkdir -p "$HOME/.local"

# Download the scripts
if command -v wget &>/dev/null; then
    wget -q -O "$HOME/.local/d.sh" "https://raw.githubusercontent.com/astappiev/simple-docker/refs/heads/main/d.sh"
    wget -q -O "$HOME/.local/dc.sh" "https://raw.githubusercontent.com/astappiev/simple-docker/refs/heads/main/dc.sh"
elif command -v curl &>/dev/null; then
    curl -s -o "$HOME/.local/d.sh" "https://raw.githubusercontent.com/astappiev/simple-docker/refs/heads/main/d.sh"
    curl -s -o "$HOME/.local/dc.sh" "https://raw.githubusercontent.com/astappiev/simple-docker/refs/heads/main/dc.sh"
else
    echo "Error: Neither curl nor wget is available. Please install one of them and try again."
    exit 1
fi

# Make the scripts executable
chmod +x "$HOME/.local/d.sh" "$HOME/.local/dc.sh"

# Add aliases to .bashrc if they don't already exist
if ! grep -q "alias d='. ~/.local/d.sh'" "$HOME/.bashrc"; then
    echo "# Docker CLI simplified" >> "$HOME/.bashrc"
    echo "alias d='. ~/.local/d.sh'" >> "$HOME/.bashrc"
    echo "alias dc='. ~/.local/dc.sh'" >> "$HOME/.bashrc"
fi

echo "Installation complete. Run 'source ~/.bashrc' to use the aliases."
