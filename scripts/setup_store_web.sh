#!/bin/bash
# =====================================================================
# Script para configurar la Capa 1 (Web / Nginx) con la Tienda Virtual
# Uso opcional si se desea desplegar el frontend completo en EC2 Web
# =====================================================================

set -e

APP_PRIVATE_IP="${1:-127.0.0.1}"

echo "[1/4] Actualizando sistema e instalando Nginx..."
dnf update -y
dnf install -y nginx

echo "[2/4] Configurando Reverse Proxy hacia la Capa 2 (${APP_PRIVATE_IP}:8080)..."
cat << 'EOF' > /etc/nginx/conf.d/tienda.conf
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://BACKEND_HOST:8080/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

sed -i "s/BACKEND_HOST/${APP_PRIVATE_IP}/g" /etc/nginx/conf.d/tienda.conf

echo "[3/4] Habilitando e iniciando servicio Nginx..."
systemctl enable nginx
systemctl restart nginx

echo "[4/4] Servidor Web Listo."

