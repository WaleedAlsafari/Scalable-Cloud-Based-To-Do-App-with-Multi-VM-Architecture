#!/bin/bash
# backendScripts.sh

# Set non-interactive mode to avoid debconf prompts
export DEBIAN_FRONTEND=noninteractive

# Update package index and upgrade packages
sudo apt update && sudo apt upgrade -y

# Install nodejs, npm, git, and curl
sudo apt install -y nodejs npm git curl

# Clone the repository
git clone https://github.com/WaleedAlsafari/Scalable-Cloud-Based-To-Do-App-with-Multi-VM-Architecture.git

# Navigate to the server directory
cd Scalable-Cloud-Based-To-Do-App-with-Multi-VM-Architecture/app/server

# Create .env file
cat <<EOF > .env
DB_HOST=10.0.2.4
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=Admin123@
DB_NAME=todoapp
EOF

# Install dependencies and start the server
npm install
npm run server
