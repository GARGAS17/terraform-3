#!/bin/bash
# =====================================================================
# Script para configurar la Capa 2 (Lógica / Node.js Express)
# Ejecutar en la instancia EC2 de Aplicación
# =====================================================================

set -e

DB_HOST="${1:-localhost}"
DB_PASSWORD="${2:-ClaveSegura2026!}"
DB_USER="admin_app"
DB_NAME="appdb"
PORT="8080"

echo "[1/4] Instalando Node.js..."
dnf update -y
dnf install -y nodejs npm

echo "[2/4] Creando directorio y servicio de aplicación..."
mkdir -p /opt/tienda-backend
cd /opt/tienda-backend

cat << EOF > .env
PORT=${PORT}
NODE_ENV=production
DB_HOST=${DB_HOST}
DB_PORT=5432
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_SSL=false
EOF

echo "[3/4] Creando servicio systemd..."
cat << 'EOF' > /etc/systemd/system/tienda-backend.service
[Unit]
Description=Backend Tienda Capa 2
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/tienda-backend
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
EnvironmentFile=/opt/tienda-backend/.env

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo "[4/4] Servicio configurado."

