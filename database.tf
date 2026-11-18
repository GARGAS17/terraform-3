# =====================================================================
# UNIVERSIDAD POPULAR DEL CESAR
# Paso 6: Capa de Datos con Amazon RDS (database.tf)
# =====================================================================

# Grupo de subredes privadas obligatorio para RDS (Multi-AZ mínimo 2 AZs)
resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Recurso de Datos: Instancia relacional Amazon RDS (PostgreSQL 16)
resource "aws_db_instance" "postgres_db" {
  identifier             = "${var.project_name}-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "appdb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "${var.project_name}-rds-postgres"
    Tier = "Database"
  }
}

