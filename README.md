# Arquitectura de Tres Capas en AWS con Terraform (`terraform-3tier-app`)

Guía de referencia del proyecto: ciclo de vida de Terraform (`init`, `plan`, `apply`, `destroy`), descripción de cada archivo y buenas prácticas aplicadas.

---

## Estructura de la carpeta

```text
terraform-3tier-app/
├── providers.tf               # Configuración de Terraform y proveedor AWS
├── variables.tf               # Declaración de variables de entrada
├── terraform.tfvars.example   # Plantilla de ejemplo para variables
├── terraform.tfvars           # Valores reales de las variables
├── network.tf                 # VPC, subredes, IGW, NAT y rutas
├── security.tf                # Security Groups encadenados por capa
├── database.tf                # Base de datos RDS PostgreSQL
├── compute.tf                 # Instancias EC2 (Web y App) + user_data
├── outputs.tf                 # Salidas dinámicas tras el despliegue
└── scripts/
    ├── setup_store_web.sh     # Script opcional de configuración Web (Nginx)
    └── setup_store_app.sh     # Script opcional de configuración App (Node.js)
```

---

## 1. Ciclo de vida de Terraform

Todos los comandos se ejecutan **en la terminal, desde la raíz de esta carpeta** (`terraform-3tier-app/`).

### 1.1 `terraform init` — Inicialización

```bash
terraform init
```

* **Cuándo se usa:** Es el primer paso al iniciar el proyecto o cuando se modifican proveedores.
* **Qué archivos lee:** Principalmente `providers.tf` (versión de Terraform `>= 1.5.0` y proveedor `hashicorp/aws` `~> 5.0`).
* **Qué genera:** Descarga el proveedor en `.terraform/` y crea el archivo de bloqueo `.terraform.lock.hcl`.

### 1.2 `terraform plan` — Planificación

```bash
terraform plan
```

* **Cuándo se usa:** Antes de aplicar cambios, para validar la sintaxis y previsualizar qué recursos se crearán, modificarán o destruirán sin tocar AWS.
* **Qué archivos lee:**
  * Todos los `.tf` de la carpeta.
  * Los valores definidos en `terraform.tfvars`.
  * Los `data` sources de `network.tf` (zonas de disponibilidad) y `compute.tf` (AMI de Amazon Linux 2023).

### 1.3 `terraform apply` — Despliegue

```bash
terraform apply
```

* **Cuándo se usa:** Cuando el `plan` es correcto y se desea crear o actualizar la infraestructura real en AWS.
* **Qué archivos lee:** Ejecuta en orden de dependencias `network.tf` → `security.tf` → `database.tf` → `compute.tf` y, al terminar, muestra los valores definidos en `outputs.tf`.
* **Qué genera:** Crea o actualiza `terraform.tfstate` con el estado real de la infraestructura.

### 1.4 `terraform destroy` — Destrucción

```bash
terraform destroy
```

* **Cuándo se usa:** Al finalizar las pruebas o prácticas para eliminar toda la infraestructura en AWS y evitar costos.
* **Qué archivos lee:** Usa `terraform.tfstate` junto con los `.tf` para borrar los recursos en orden inverso.
* **Detalle clave:** En `database.tf`, `skip_final_snapshot = true` permite eliminar el RDS sin exigir un snapshot final manual.

---

## 2. Explicación de cada archivo

### `providers.tf`
Configura el motor de Terraform y la conexión con AWS.
* Fija `required_version = ">= 1.5.0"` y el proveedor `hashicorp/aws` (`~> 5.0`).
* Configura `provider "aws"` con la región `var.aws_region`.
* Aplica `default_tags` globales (`Project`, `Environment = "Academico"`, `ManagedBy = "Terraform"`) a todos los recursos.

### `variables.tf`
Declara todas las variables parametrizables del proyecto con `description`, `type` y `default`.
* **Infraestructura:** `aws_region`, `project_name`, `vpc_cidr`, `instance_type`, `enable_nat_gateway`, `key_name`.
* **Base de datos:** `db_username` y `db_password` (marcada con `sensitive = true`).
* **Repositorios:** `frontend_repo_url`, `backend_repo_url` y `database_repo_url`.

### `terraform.tfvars.example`
Plantilla de ejemplo para que cualquier persona copie el archivo como `terraform.tfvars` y rellene sus propios valores antes de ejecutar `plan` o `apply`.

### `terraform.tfvars`
Archivo con los valores concretos del entorno que Terraform carga automáticamente al ejecutar `plan` y `apply` (región, CIDR, contraseña de RDS, URLs de repositorios, etc.).

### `network.tf`
Define la topología de red Multi-AZ en AWS:
* Consulta las zonas de disponibilidad con `data "aws_availability_zones"`.
* Crea la VPC principal (`aws_vpc.main`) y el Internet Gateway (`aws_internet_gateway.igw`).
* Crea **6 subredes** (2 por capa):
  * `public` (Capa 1 - Web)
  * `private_app` (Capa 2 - Aplicación)
  * `private_db` (Capa 3 - Base de datos)
* Configura tablas de enrutamiento (`public_rt` y `private_rt`) y, si `enable_nat_gateway = true`, crea una IP elástica (`aws_eip.nat`) y un NAT Gateway (`aws_nat_gateway.nat`).

### `security.tf`
Define los Security Groups aplicando el **principio de menor privilegio (encadenamiento)**:
* `web_sg`: acepta HTTP (`80`), HTTPS (`443`) y SSH (`22`) desde Internet (`0.0.0.0/0`).
* `app_sg`: solo acepta tráfico en el puerto `8080` y SSH (`22`) proveniente de `web_sg`.
* `db_sg`: solo acepta PostgreSQL (`5432`) proveniente de `app_sg`.

### `database.tf`
Despliega la **Capa 3 (Datos)**:
* Crea `aws_db_subnet_group.db_subnets` usando las subredes privadas `private_db`.
* Crea `aws_db_instance.postgres_db` (PostgreSQL 16, `db.t3.micro`, 20 GB `gp2`, base `appdb`).
* Configurada con `publicly_accessible = false` y `skip_final_snapshot = true`.

### `compute.tf`
Despliega las **Capas 1 y 2 (Cómputo)** usando la AMI más reciente de Amazon Linux 2023 (`data "aws_ami"`):
* `web_server` (subred pública): ejecuta un `user_data` que instala Nginx y Git, clona `frontend_repo_url` y configura Nginx como reverse proxy `/api/` hacia `app_server` (`:8080`).
* `app_server` (subred privada, con `depends_on = [aws_db_instance.postgres_db]`): ejecuta un `user_data` que instala Node.js y Git, clona `backend_repo_url`, crea el archivo `.env` con las credenciales de RDS y levanta el servicio `systemd` `tienda-backend`.

### `outputs.tf`
Muestra información útil al terminar `terraform apply`:
* `vpc_id`
* `web_server_public_ip`
* `web_server_url`
* `app_server_private_ip`
* `rds_endpoint`

### `scripts/setup_store_web.sh`
Script bash auxiliar (uso manual/opcional) para configurar la Capa 1 (Web): instala Nginx, configura `/etc/nginx/conf.d/tienda.conf` apuntando a la IP privada del backend (`$1`) e inicia el servicio.

### `scripts/setup_store_app.sh`
Script bash auxiliar (uso manual/opcional) para configurar la Capa 2 (App): instala Node.js/npm, crea `/opt/tienda-backend/.env` con `DB_HOST` (`$1`) y `DB_PASSWORD` (`$2`), y registra el servicio `systemd` `tienda-backend.service`.

---

## 3. Buenas prácticas aplicadas

1. **Separación por responsabilidad:** Cada capa o función vive en su propio archivo (`.tf`), evitando un único `main.tf` gigante.
2. **Versionado explícito:** `providers.tf` fija las versiones mínimas y compatibles de Terraform y AWS.
3. **Etiquetado centralizado:** `default_tags` etiqueta todos los recursos automáticamente para control de costos y auditoría.
4. **Manejo seguro de variables:** `db_password` usa `sensitive = true` y se incluye `terraform.tfvars.example` como plantilla.
5. **Seguridad por capas:** Encadenamiento de Security Groups (`web_sg` → `app_sg` → `db_sg`) y base de datos sin IP pública.
6. **Recomendación pendiente:** Agregar un archivo `.gitignore` si se va a subir a Git, para excluir `.terraform/`, `*.tfstate` y `terraform.tfvars`.
