#!/usr/bin/env bash
# frontendScripts.sh - Build React app and serve via Nginx with API proxy
set -euxo pipefail

APP_DIR="/opt/todo-app"
REPO_URL="https://github.com/WaleedAlsafari/Scalable-Cloud-Based-To-Do-App-with-Multi-VM-Architecture.git"
CLIENT_DIR="$APP_DIR/app/client"
BUILD_DIR="/var/www/todo-client"
SITE_NAME="todo-client"
NGINX_SITE_PATH="/etc/nginx/sites-available/${SITE_NAME}"
NGINX_SITE_LINK="/etc/nginx/sites-enabled/${SITE_NAME}"

retry() {
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

export DEBIAN_FRONTEND=noninteractive

# تحديث النظام
retry 5 10 apt-get update -y
retry 5 10 apt-get upgrade -y

# أدوات أساسية + Node 18 + Nginx
retry 5 10 apt-get install -y ca-certificates curl gnupg git
apt-get remove -y nodejs npm || true
retry 5 10 bash -lc 'curl -fsSL https://deb.nodesource.com/setup_18.x | bash -'
retry 5 10 apt-get install -y nodejs nginx

# كود التطبيق
mkdir -p "$APP_DIR"
if [ -d "$APP_DIR/.git" ]; then
  git -C "$APP_DIR" remote set-url origin "$REPO_URL"
  retry 5 10 git -C "$APP_DIR" fetch --all --prune
  git -C "$APP_DIR" reset --hard origin/HEAD
else
  retry 5 10 git clone --depth 1 "$REPO_URL" "$APP_DIR"
fi

# تثبيت واعمل build للـ client
retry 5 10 bash -lc "cd '$CLIENT_DIR' && npm ci || npm install"
retry 5 10 bash -lc "cd '$CLIENT_DIR' && npm run build"

# نسخ الـ build إلى مسار Nginx
mkdir -p "$BUILD_DIR"
rsync -a --delete "$CLIENT_DIR/build/" "$BUILD_DIR/"

# تهيئة Nginx لموقع SPA + Proxy API
cat > "$NGINX_SITE_PATH" <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /var/www/todo-client;
    index index.html;

    # React SPA
    location / {
        try_files $uri /index.html;
    }

    # API Proxy → غيّر IP/BACKEND_PORT حسب بيئتك
    location /api/ {
        proxy_pass http://10.0.1.4:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # ملفات ثابتة
    location ~* \.(?:css|js|woff2?|ttf|eot|svg|png|jpg|jpeg|gif|ico)$ {
        expires 7d;
        add_header Cache-Control "public, max-age=604800, immutable";
        try_files $uri =404;
    }
}
EOF

# تفعيل الموقع وإلغاء الافتراضي القديم إن وجد
rm -f /etc/nginx/sites-enabled/default || true
ln -sf "$NGINX_SITE_PATH" "$NGINX_SITE_LINK"

# فحص الصيغة وإعادة التشغيل
nginx -t
systemctl enable nginx
systemctl restart nginx

echo "Frontend deployed to $BUILD_DIR and served by Nginx on port 80 with /api/ proxy to backend."
exit 0
