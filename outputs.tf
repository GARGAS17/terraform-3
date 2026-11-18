# =====================================================================
# UNIVERSIDAD POPULAR DEL CESAR
# Paso 7: Salidas Dinámicas Post-Despliegue (outputs.tf)
# =====================================================================

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "web_server_public_ip" {
  description = "IP pública para acceder al servidor web"
  value       = aws_instance.web_server.public_ip
}

output "web_server_url" {
  description = "URL de prueba del servidor Nginx"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "app_server_private_ip" {
  description = "IP privada del servidor de aplicación"
  value       = aws_instance.app_server.private_ip
}

output "rds_endpoint" {
  description = "Endpoint interno de conexión a la base de datos PostgreSQL"
  value       = aws_db_instance.postgres_db.endpoint
}

