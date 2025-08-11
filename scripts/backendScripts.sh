#!/bin/bash

# Exit on any error
set -e

# Update and upgrade packages
sudo apt update && sudo apt upgrade -y

# Install curl, git, nodejs, and npm
sudo apt install -y curl git nodejs npm

# Ensure npm is installed and PATH is updated
if ! command -v npm &> /dev/null; then
    echo "npm not found after installation. Attempting to fix..."
    sudo apt install -y npm
fi

# Refresh environment to ensure PATH includes npm
source /etc/profile || true

# Verify node and npm versions
node -v || { echo "Node.js not found"; exit 1; }
npm -v || { echo "npm not found"; exit 1; }

# Clone the repository
git clone https://github.com/WaleedAlsafari/PERN-ToDo-App.git
cd PERN-ToDo-App/server

# Run npm commands
npm install
npm run build
