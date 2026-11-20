# =====================================================================
# Configuración de Backend Remoto en AWS S3 + Bloqueo en DynamoDB
# =====================================================================

terraform {
  backend "s3" {
    bucket         = "gargas17-terraform-state-lab"
    key            = "3tier-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
