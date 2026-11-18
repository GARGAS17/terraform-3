# =====================================================================
# UNIVERSIDAD POPULAR DEL CESAR
# Paso 4: Seguridad Perimetral Encadenada (security.tf)
# Principio de Menor Privilegio (Security Group Chaining)
# =====================================================================

# 1. Security Group Capa Web (Recibe tráfico HTTP/HTTPS desde Internet)
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Permite trafico HTTP/HTTPS publico hacia la capa web"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS desde Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH para administracion remota (EC2 Instance Connect)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    description = "Permite salida de trafico hacia cualquier destino"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# 2. Security Group Capa Aplicación (Solo acepta tráfico desde web_sg)
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Permite trafico unicamente desde la capa web"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Trafico backend desde capa Web"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    description     = "SSH interno desde Capa Web"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }


  egress {
    description = "Permite salida de trafico hacia cualquier destino"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# 3. Security Group Capa Base de Datos (Solo acepta tráfico PostgreSQL desde app_sg)
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Permite trafico PostgreSQL unicamente desde la capa de aplicacion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL desde Capa de Aplicacion"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    description = "Permite salida interna"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

