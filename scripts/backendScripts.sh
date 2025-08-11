#!/bin/bash

# Exit on any error
set -e

# Update and upgrade packages
sudo apt update && sudo apt upgrade -y

# Install curl and git (required for cloning and NodeSource setup)
sudo apt install -y curl git

# Set up NodeSource repository for Node.js v20 (LTS)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js (includes npm automatically)
sudo apt install -y nodejs

# Refresh environment to ensure PATH includes node and npm
source /etc/profile || true

# Verify installations (fail if not found)
node -v || { echo "Node.js not found"; exit 1; }
npm -v || { echo "npm not found"; exit 1; }

# Clone the repository and set up the backend
git clone https://github.com/WaleedAlsafari/PERN-ToDo-App.git
cd PERN-ToDo-App/server

# Run npm commands
npm install
npm run build

echo "Setup complete!"
