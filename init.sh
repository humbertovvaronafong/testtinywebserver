#!/bin/sh
set -e

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1"; }
error() { echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >&2; }
success() { echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1"; }
warn() { echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1"; }

log "Starting container initialization..."

if [ -n "$TIMEZONE" ] && [ -f "/usr/share/zoneinfo/$TIMEZONE" ]; then
    ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    echo "$TIMEZONE" > /etc/timezone
    success "Timezone set to $TIMEZONE"
else
    warn "Invalid or unset TIMEZONE. Using container default."
fi

if [ -n "$NGINX_WORKER_PROCESSES" ]; then
    sed -i "s|^worker_processes .*;|worker_processes ${NGINX_WORKER_PROCESSES};|" /etc/nginx/nginx.conf
    success "Nginx worker_processes set to $NGINX_WORKER_PROCESSES"
fi

DEFAULT_CONF="/etc/nginx/conf.d/default.conf"
SSL_CERT="/config/ssl/fullchain.pem"
SSL_KEY="/config/ssl/privkey.pem"
WEBROOT="/config/www"
WARN_DIR="/config/warnings"
WARN_FILE="$WARN_DIR/cert-warn.log"
USE_HTTPS=no
CERT_WARN_DAYS=${CERT_WARN_DAYS:-30}

if [ "$AUTOCERT" = "yes" ] && [ "$REDIRECT_TO_HTTPS" = "yes" ]; then
    if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
        log "AUTOCERT is enabled and REDIRECT_TO_HTTPS is yes. Generating self-signed cert..."
        apk add --no-cache openssl >/dev/null 2>&1
        mkdir -p /config/ssl
        openssl req -x509 -nodes -days 365 \
          -newkey rsa:2048 \
          -keyout "$SSL_KEY" \
          -out "$SSL_CERT" \
          -subj "/C=US/ST=Dev/L=Local/O=SelfSigned/CN=localhost"
        success "Self-signed SSL certificate generated in /config/ssl/"
    fi
fi

if [ "$REDIRECT_TO_HTTPS" = "yes" ] && [ -f "$SSL_CERT" ] && [ -f "$SSL_KEY" ]; then
    USE_HTTPS=yes
    success "SSL certificates found and REDIRECT_TO_HTTPS is enabled. HTTPS will be configured."

    EXP_DATE_RAW=$(openssl x509 -enddate -noout -in "$SSL_CERT" 2>/dev/null | cut -d= -f2)
    EXP_DATE_SEC=$(date -d "$EXP_DATE_RAW" +%s)
    NOW_DATE_SEC=$(date +%s)
    DAYS_LEFT=$(( (EXP_DATE_SEC - NOW_DATE_SEC) / 86400 ))

    warn "SSL certificate expires in $DAYS_LEFT day(s) → $EXP_DATE_RAW"

    if [ "$DAYS_LEFT" -le "$CERT_WARN_DAYS" ]; then
        warn "⚠️  SSL certificate will expire in less than $CERT_WARN_DAYS days!"
        mkdir -p "$WARN_DIR"
        echo "$DAYS_LEFT day(s) left — expires on $EXP_DATE_RAW" > "$WARN_FILE"
        success "cert-warn.log created at $WARN_FILE"
    elif [ "$DAYS_LEFT" -le 90 ]; then
        warn "ℹ️  SSL certificate expires in less than 3 months."
    else
        warn "✅ SSL certificate is valid for more than 90 days."
    fi
else
    if [ "$REDIRECT_TO_HTTPS" = "yes" ]; then
        warn "REDIRECT_TO_HTTPS is enabled, but no valid SSL certificates found. Skipping HTTPS."
    else
        log "REDIRECT_TO_HTTPS is disabled. Serving site over HTTP only."
    fi
fi

log "Checking nginx.conf structure..."
if grep -q 'include /etc/nginx/conf.d/\*\.conf;' /etc/nginx/nginx.conf; then
    sed -i '/include \/etc\/nginx\/conf\.d\/\*\.conf;/d' /etc/nginx/nginx.conf
    sed -i '/http {/a\    include /etc/nginx/conf.d/*.conf;' /etc/nginx/nginx.conf
    success "nginx.conf structure fixed."
else
    success "nginx.conf structure OK."
fi

log "Cleaning /etc/nginx/http.d/"
rm -f /etc/nginx/http.d/*.conf
success "Old configs removed."

log "Generating $DEFAULT_CONF ..."
cat <<EOF > "$DEFAULT_CONF"
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root $WEBROOT;
    index index.html index.htm;

    location / {
EOF

if [ "$REDIRECT_TO_HTTPS" = "yes" ] && [ "$USE_HTTPS" = "yes" ]; then
cat <<EOF >> "$DEFAULT_CONF"
        return 301 https://\$host\$request_uri;
EOF
else
cat <<EOF >> "$DEFAULT_CONF"
        try_files \$uri \$uri/ =404;
EOF
fi

cat <<EOF >> "$DEFAULT_CONF"
    }
}
EOF

if [ "$USE_HTTPS" = "yes" ]; then
cat <<EOF >> "$DEFAULT_CONF"

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;

    ssl_certificate     $SSL_CERT;
    ssl_certificate_key $SSL_KEY;

    root $WEBROOT;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
    success "HTTPS block added to default.conf"
fi

log "Checking $WEBROOT for index files..."
if [ -f "$WEBROOT/index.html" ] || [ -f "$WEBROOT/index.htm" ]; then
    success "Index file found in $WEBROOT."
else
    warn "No index.html/htm found in $WEBROOT!"
fi

log "Checking file permissions in /config..."
MISSING_PERMISSIONS=$(find /config -type f ! -perm -004)
if [ -n "$MISSING_PERMISSIONS" ]; then
    warn "Some files in /config are not world-readable:"
    echo "$MISSING_PERMISSIONS" | while read line; do warn "$line"; done
else
    success "All files in /config are readable."
fi

log "Stopping any previous Nginx instances..."
killall -q nginx || true
success "Previous Nginx stopped."

log "Starting Nginx..."
nginx -g "daemon off;"
