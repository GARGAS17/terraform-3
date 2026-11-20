# =====================================================================
# Variables de Entrada para Despliegue en AWS
# Universidad Popular del Cesar • Cloud Computing
# =====================================================================

aws_region    = "us-east-1"
project_name  = "webapp-3capas"
instance_type = "t3.micro"

# Credenciales de Base de Datos PostgreSQL en RDS
# db_password se suministra vía TF_VAR_db_password en GitHub Actions
db_username = "admin_app"

# URLs de los 3 Repositorios en GitHub (cuadradoA)
frontend_repo_url = "https://github.com/cuadradoA/tienda-frontend.git"
backend_repo_url  = "https://github.com/cuadradoA/tienda-backend.git"
database_repo_url = "https://github.com/cuadradoA/tienda-database.git"

# Habilitar NAT Gateway para que EC2 App tenga salida a Internet (clonar GitHub y npm install)
enable_nat_gateway = true

# Key Pair de AWS Academy para conexión SSH
key_name = "vockey"


