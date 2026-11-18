# =====================================================================
# UNIVERSIDAD POPULAR DEL CESAR
# Paso 2: Definición de Variables Parametrizables y Secretos (variables.tf)
# =====================================================================

variable "aws_region" {
  description = "Región de AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo para nombrar los recursos del proyecto"
  type        = string
  default     = "webapp-3capas"
}

variable "vpc_cidr" {
  description = "Bloque CIDR principal de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 permitida (Capa Gratuita / Academy)"
  type        = string
  default     = "t3.micro"
}

variable "db_username" {
  description = "Usuario administrador de la base de datos RDS"
  type        = string
  default     = "admin_app"
}

variable "db_password" {
  description = "Contraseña de la base de datos (mínimo 8 caracteres)"
  type        = string
  sensitive   = true
}

# --- REPOSITORIOS GITHUB INDEPENDIENTES PARA CADA CAPA ---
variable "frontend_repo_url" {
  description = "URL del repositorio de GitHub para la Capa 1 (Frontend / Web)"
  type        = string
  default     = "https://github.com/cuadradoA/tienda-frontend.git"
}

variable "backend_repo_url" {
  description = "URL del repositorio de GitHub para la Capa 2 (Lógica / Backend)"
  type        = string
  default     = "https://github.com/cuadradoA/tienda-backend.git"
}

variable "database_repo_url" {
  description = "URL del repositorio de GitHub para la Capa 3 (Datos / SQL)"
  type        = string
  default     = "https://github.com/cuadradoA/tienda-database.git"
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway para que la Capa 2 privada descargue paquetes y clone de GitHub"
  type        = bool
  default     = true
}

variable "key_name" {
  description = "Nombre del Key Pair para acceso SSH (predeterminado vockey en AWS Academy Learner Lab)"
  type        = string
  default     = "vockey"
}



