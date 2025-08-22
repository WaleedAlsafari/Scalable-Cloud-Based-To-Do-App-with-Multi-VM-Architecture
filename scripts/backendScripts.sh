#!/usr/bin/env bash
# backendScripts.sh - robust setup for Azure CSE (non-blocking)
set -euxo pipefail

# Variables (adjust if needed)
APP_DIR="/opt/todo-app"
REPO_URL="https://github.com/WaleedAlsafari/Scalable-Cloud-Based-To-Do-App-with-Multi-VM-Architecture.git"
SERVER_DIR="$APP_DIR/app/server"
ENV_FILE="$SERVER_DIR/.env"
SERVICE_NAME="todo-backend.service"

#-----------------------------
# Helpers
#-----------------------------
retry() {
  # retry <max_tries> <sleep_seconds> <command...>
  local -r -i max_tries="$1"; shift
  local -r -i sleep_seconds="$1"; shift
  local -i try=1
  until "$@"; do
    if (( try >= max_tries )); then
      echo "Command failed after $try attempts: $*" >&2
      return 1
    fi
    echo "Retry $try/$max_tries failed. Sleeping $sleep_seconds..." >&2
    sleep "$sleep_seconds"
    ((try++))
  done
}

# Azure CSE typically runs as root; no need for sudo.
export DEBIAN_FRONTEND=noninteractive

#-----------------------------
# System prep & Node.js LTS
#-----------------------------
retry 5 10 apt-get update -y
retry 5 10 apt-get upgrade -y

# Basic tools
retry 5 10 apt-get install -y ca-certificates curl gnupg git build-essential

# Install Node 18.x from NodeSource (works well on Ubuntu 20.04/22.04/24.04)
if ! command -v node >/dev/null 2>&1 || [ "$(node -v | sed 's/v//; s/\..*//')" -lt 18 ]; then
  # Clean any distro Node to avoid conflicts
  apt-get remove -y nodejs npm || true

  # NodeSource setup
  retry 5 10 bash -lc 'curl -fsSL https://deb.nodesource.com/setup_18.x | bash -'
  retry 5 10 apt-get install -y nodejs
fi

# Ensure npm is present
command -v npm >/dev/null 2>&1 || (echo "npm missing after install" >&2; exit 1)

#-----------------------------
# App code
#-----------------------------
# Create app directory if not exists
mkdir -p "$APP_DIR"

if [ -d "$APP_DIR/.git" ]; then
  # Existing repo; update it
  git -C "$APP_DIR" remote set-url origin "$REPO_URL"
  retry 5 10 git -C "$APP_DIR" fetch --all --prune
  git -C "$APP_DIR" reset --hard origin/HEAD
else
  # Fresh clone (shallow for speed)
  retry 5 10 git clone --depth 1 "$REPO_URL" "$APP_DIR"
fi

#-----------------------------
# Environment configuration
#-----------------------------
mkdir -p "$SERVER_DIR"
cat > "$ENV_FILE" <<'EOF'
DB_HOST=10.0.2.4
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=Admin123@
DB_NAME=todoapp
EOF
chmod 600 "$ENV_FILE"

#-----------------------------
# Install dependencies
#-----------------------------
# Prefer clean install for reproducibility
retry 5 10 bash -lc "cd '$SERVER_DIR' && npm ci || npm install"

#-----------------------------
# systemd service (non-blocking)
#-----------------------------
# We use a small wrapper so systemd has a stable working dir.
WRAPPER="$SERVER_DIR/start-backend.sh"
cat > "$WRAPPER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
# If your package.json has "server": "node server.js" (or similar), this will work.
# Otherwise, change to the exact start command (e.g., npm start or node index.js)
exec npm run server
EOF
chmod +x "$WRAPPER"

# Create systemd unit
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=ToDo Backend Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$SERVER_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$WRAPPER
Restart=always
RestartSec=5
# If the app listens on a port, give it a little time to bind
StartLimitIntervalSec=0
# Optional: drop privileges (create user/group if you prefer)
#User=www-data
#Group=www-data

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

#-----------------------------
# Health check (optional but useful)
#-----------------------------
# If the backend exposes a health endpoint, you can probe it (adjust PORT/PATH).
# This should NOT block the script for long.
# Example:
# retry 5 5 bash -lc "curl -fsS http://127.0.0.1:3001/health >/dev/null"

echo "Setup complete. Service status:"
systemctl --no-pager --full status "$SERVICE_NAME" || true

exit 0
