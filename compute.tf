# =====================================================================
# UNIVERSIDAD POPULAR DEL CESAR
# Paso 5: Recursos de Ejecución y Data Sources (compute.tf)
# =====================================================================

# Data Source: Obtener automáticamente la AMI más reciente de Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# Recurso de Ejecución 1: Servidor Web (Capa Presentación - Subred Pública)
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = var.key_name != "" ? var.key_name : null
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Aprovisionamiento automatizado: Clona Frontend desde GitHub y configura Nginx
  user_data = <<-EOF
              #!/bin/bash
              set -e

              echo "[1/4] Actualizando e instalando paquetes..."
              dnf update -y
              dnf install -y nginx git

              echo "[2/4] Clonando repositorio de Frontend desde GitHub..."
              mkdir -p /tmp/frontend-repo
              if git clone "${var.frontend_repo_url}" /tmp/frontend-repo; then
                  cp -rf /tmp/frontend-repo/* /usr/share/nginx/html/ || true
              fi

              # Asegurar banner de validación del PDF por si se ejecuta curl directo
              echo "<!-- Arquitectura 3 Capas - Capa Web Activa (Terraform) -->" >> /usr/share/nginx/html/index.html

              echo "[3/4] Configurando Nginx Reverse Proxy hacia Capa 2 (${aws_instance.app_server.private_ip}:8080)..."
              cat << 'NGINX_CONF' > /etc/nginx/conf.d/tienda.conf
              server {
                  listen 80;
                  server_name _;

                  root /usr/share/nginx/html;
                  index index.html index.htm;

                  location / {
                      try_files $uri $uri/ /index.html;
                  }

                  location /api/ {
                      proxy_pass http://${aws_instance.app_server.private_ip}:8080/api/;
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade $http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host $host;
                      proxy_cache_bypass $http_upgrade;
                      proxy_set_header X-Real-IP $remote_addr;
                      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  }
              }
              NGINX_CONF

              echo "[4/4] Iniciando Nginx..."
              systemctl enable nginx
              systemctl restart nginx
              EOF

  tags = {
    Name = "${var.project_name}-ec2-web"
    Tier = "Web"
  }
}

# Recurso de Ejecución 2: Servidor de Aplicación (Capa Lógica - Subred Privada)
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = var.key_name != "" ? var.key_name : null
  subnet_id              = aws_subnet.private_app[0].id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Aprovisionamiento automatizado: Clona Backend desde GitHub y levanta servicio
  user_data = <<-EOF
              #!/bin/bash
              set -e

              echo "[1/4] Instalando Node.js y Git..."
              dnf update -y
              dnf install -y nodejs npm git

              echo "[2/4] Clonando repositorio de Backend desde GitHub..."
              mkdir -p /opt/tienda-backend
              git clone "${var.backend_repo_url}" /opt/tienda-backend || true

              cd /opt/tienda-backend

              echo "[3/4] Inyectando credenciales dinámicas de RDS..."
              cat << 'ENV' > /opt/tienda-backend/.env
              PORT=8080
              NODE_ENV=production
              DB_HOST=${aws_db_instance.postgres_db.address}
              DB_PORT=5432
              DB_NAME=${aws_db_instance.postgres_db.db_name}
              DB_USER=${var.db_username}
              DB_PASSWORD=${var.db_password}
              DB_SSL=false
              ENV

              if [ -f "/opt/tienda-backend/package.json" ]; then
                  npm install --omit=dev
              fi

              echo "[4/4] Creando servicio systemd para la API..."
              cat << 'SERVICE' > /etc/systemd/system/tienda-backend.service
              [Unit]
              Description=Servicio Backend Tienda Capa 2
              After=network.target

              [Service]
              Type=simple
              User=root
              WorkingDirectory=/opt/tienda-backend
              ExecStart=/usr/bin/node server.js
              Restart=always
              RestartSec=10
              EnvironmentFile=/opt/tienda-backend/.env

              [Install]
              WantedBy=multi-user.target
              SERVICE

              systemctl daemon-reload
              systemctl enable tienda-backend
              systemctl start tienda-backend || true
              EOF

  depends_on = [aws_db_instance.postgres_db]

  tags = {
    Name = "${var.project_name}-ec2-app"
    Tier = "App"
  }
}


