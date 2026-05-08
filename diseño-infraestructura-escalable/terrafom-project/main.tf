# 1. Localización de tu VPC por ID
data "aws_vpc" "mi_vpc" {
  id = "vpc-0dc414704fe461959"
}

# 2. Localización de subredes dentro de esa VPC
data "aws_subnets" "mis_subredes" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.mi_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

# Opcional / legado (ya no se inyecta en ECS si chat = OpenAI).
variable "groq_api_key" {
  type        = string
  sensitive   = true
  description = "Deprecated: chat usa OpenAI. Dejar vacío."
  default     = ""
}

variable "openai_api_key" {
  type        = string
  sensitive   = true
  description = "API key de OpenAI: chat (GPT-4.1 Mini) + embeddings RAG (OPENAI_API_KEY en ECS)."
  default     = ""
}

# 3. Agrupación lógica de subredes para la base de datos
resource "aws_db_subnet_group" "bsg_subnets" {
  name       = "bsg-subnet-group"
  subnet_ids = data.aws_subnets.mis_subredes.ids
  tags       = { Name = "BSG Subnet Group" }
}

# 4. Firewall (Security Group)
resource "aws_security_group" "rds_sg" {
  name   = "rds-security-group-v2"
  vpc_id = data.aws_vpc.mi_vpc.id
}

resource "aws_security_group_rule" "rds_ingress_ip" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds_sg.id
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds_sg.id
}

# 5. La Instancia RDS (PostgreSQL 16)
resource "aws_db_instance" "postgres_bsg" {
  identifier        = "bsg-rds-instance"
  allocated_storage = 20
  storage_type      = "gp3"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.micro"
  db_name           = "postgres"
  username          = "bsg_admin"
  password          = "PasswordSeguro123"

  db_subnet_group_name   = aws_db_subnet_group.bsg_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = true
  skip_final_snapshot = true
}

# 6. Salida de datos (Endpoint de conexión)
output "rds_endpoint" {
  value = aws_db_instance.postgres_bsg.endpoint
}

# =========================================================
# 7. DynamoDB - BSG Security (Tabla de Tokens Revocados)
# =========================================================
resource "aws_dynamodb_table" "bsg_revoked_tokens" {
  name         = "bsg_revoked_tokens"
  billing_mode = "PAY_PER_REQUEST" # Capacidad bajo demanda

  hash_key = "access_token_hash"

  attribute {
    name = "access_token_hash"
    type = "S"
  }

  attribute {
    name = "refresh_token_hash"
    type = "S"
  }

  global_secondary_index {
    name = "refresh_token_hash_index"
    key_schema {
      attribute_name = "refresh_token_hash"
      key_type       = "HASH"
    }
    projection_type = "ALL"
  }

  # Habilitamos el TTL para que Dynamo borre automáticamente los tokens que ya expiraron
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "bsg-revoked-tokens"
    Environment = "desarrollo"
    Project     = "bsg-security"
  }
}

output "dynamodb_revoked_tokens_table_name" {
  value = aws_dynamodb_table.bsg_revoked_tokens.name
}

# =========================================================
# 8. ElastiCache (Redis) - Caché de seguridad
# =========================================================
resource "aws_elasticache_subnet_group" "bsg_redis_subnet" {
  name       = "bsg-redis-subnet-group"
  subnet_ids = data.aws_subnets.mis_subredes.ids
}

resource "aws_security_group" "redis_sg" {
  name   = "redis-security-group"
  vpc_id = data.aws_vpc.mi_vpc.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir acceso desde la VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_cluster" "redis_bsg" {
  cluster_id           = "bsg-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.bsg_redis_subnet.name
  security_group_ids   = [aws_security_group.redis_sg.id]
}

output "redis_endpoint" {
  value       = aws_elasticache_cluster.redis_bsg.cache_nodes[0].address
  description = "Endpoint de conexión para el clúster Redis"
}

# =========================================================
# 9. Cloud Map (Service Discovery) - Red interna
# =========================================================
resource "aws_service_discovery_private_dns_namespace" "bsg_namespace" {
  name        = "bsg.internal"
  description = "Namespace para descubrimiento de microservicios BSG"
  vpc         = data.aws_vpc.mi_vpc.id
}

output "service_discovery_namespace_id" {
  value = aws_service_discovery_private_dns_namespace.bsg_namespace.id
}

# =========================================================
# 10. API Gateway (HTTP API v2) - Entrada Pública
# =========================================================
resource "aws_apigatewayv2_api" "bsg_gateway" {
  name          = "bsg-api-gateway"
  protocol_type = "HTTP"
  description   = "Gateway principal para enrutar peticiones al frontend y microservicios"

  # Habilitamos CORS por defecto para evitar bloqueos con el SPA del frontend
  cors_configuration {
    allow_credentials = true
    allow_origins = [
      "http://bsg-frontend-alb-1943066260.us-east-1.elb.amazonaws.com",
      "https://bsg-frontend-alb-1943066260.us-east-1.elb.amazonaws.com",
      "http://localhost:5173",
      "http://127.0.0.1:5173",
    ]
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    # Cabeceras pedidas en Access-Control-Request-Headers (incl. extensiones); * evita fallos de preflight.
    allow_headers = ["*"]
    expose_headers = ["X-DocViz-Resolved-Conversation-Id"]
    max_age          = 3600
  }
}

resource "aws_apigatewayv2_stage" "bsg_gateway_default_stage" {
  api_id      = aws_apigatewayv2_api.bsg_gateway.id
  name        = "$default"
  auto_deploy = true
}

locals {
  # Base pública del HTTP API (tests/cURL externos). El SPA en el ALB NO debe apuntar aquí:
  # API Gateway HTTP tiene tope ~30s en integraciones → 503 en NDJSON largos (/vector/ingest/stream, rag-turn, etc.).
  api_gateway_http_base = trimsuffix(aws_apigatewayv2_api.bsg_gateway.api_endpoint, "/")
}

output "api_gateway_endpoint" {
  value       = aws_apigatewayv2_api.bsg_gateway.api_endpoint
  description = "URL base pública del API Gateway"
}

# =========================================================
# 11. S3 Buckets - Archivos y Soporte DocViz
# =========================================================
# Nota: Los nombres de S3 deben ser únicos a nivel mundial.
# Agregamos una terminación aleatoria o tu ID para evitar choques de nombres.
resource "aws_s3_bucket" "soporte_bucket" {
  bucket        = "bsg-docviz-soporte-env"
  force_destroy = true # Permite destruir el bucket con Terraform aunque tenga archivos
}

resource "aws_s3_bucket" "borradores_bucket" {
  bucket        = "bsg-docviz-borradores-env"
  force_destroy = true
}

resource "aws_s3_bucket" "workarea_bucket" {
  bucket        = "bsg-docviz-workarea-env"
  force_destroy = true
}

output "s3_buckets" {
  value = {
    soporte    = aws_s3_bucket.soporte_bucket.bucket
    borradores = aws_s3_bucket.borradores_bucket.bucket
    workarea   = aws_s3_bucket.workarea_bucket.bucket
  }
}

# =========================================================
# 12. ECS Fargate - Clúster, Roles y Permisos
# =========================================================
resource "aws_ecs_cluster" "bsg_cluster" {
  name = "bsg-cluster"
}

# Rol de ejecución (Para que AWS pueda descargar tu imagen y escribir logs)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "bsg-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Rol de la Tarea (Para que tu código Java pueda interactuar con DynamoDB)
resource "aws_iam_role" "ecs_task_role" {
  name = "bsg-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "dynamodb_task_policy" {
  name = "bsg-dynamodb-task-policy"
  role = aws_iam_role.ecs_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:Scan", "dynamodb:Query", "dynamodb:DescribeTable"]
      Effect   = "Allow"
      Resource = aws_dynamodb_table.bsg_revoked_tokens.arn
    }]
  })
}

# Grupo de Logs para ver la consola de Spring Boot
resource "aws_cloudwatch_log_group" "back_security_logs" {
  name              = "/ecs/bsg-back-security"
  retention_in_days = 7
}

# Grupo de Seguridad del Contenedor
resource "aws_security_group" "ecs_security_sg" {
  name   = "ecs-back-security-sg"
  vpc_id = data.aws_vpc.mi_vpc.id

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Abierto para el API Gateway
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Reglas para que ECS pueda hablar con RDS y Redis internamente
resource "aws_security_group_rule" "rds_from_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.ecs_security_sg.id
}

resource "aws_security_group_rule" "redis_from_ecs" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redis_sg.id
  source_security_group_id = aws_security_group.ecs_security_sg.id
}

# =========================================================
# 13. ECS Task & Service - BSG Security
# =========================================================
resource "aws_service_discovery_service" "back_security_sd" {
  name = "security" # El nombre DNS será: security.bsg.internal
  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.bsg_namespace.id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl  = 60
      type = "SRV"
    }
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "back_security_task" {
  family                   = "bsg-back-security"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512MB RAM
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name         = "back-security"
    image        = "mmercado94/back-security-sesion1:1.0.7"
    essential    = true
    portMappings = [{ containerPort = 8081, hostPort = 8081, protocol = "tcp" }]
    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "pdn" },
      { name = "SPRING_R2DBC_URL", value = "r2dbc:postgresql://${aws_db_instance.postgres_bsg.endpoint}/bsg_security?sslMode=REQUIRE" },
      { name = "SPRING_R2DBC_USERNAME", value = "bsg_admin" },
      { name = "SPRING_R2DBC_PASSWORD", value = "PasswordSeguro123" },
      { name = "BSG_SECURITY_AWS_DYNAMODB_ENABLED", value = "true" },
      { name = "BSG_SECURITY_AWS_DYNAMODB_REGION", value = "us-east-1" },
      { name = "BSG_SECURITY_AWS_DYNAMODB_REVOKED_TOKENS_TABLE", value = aws_dynamodb_table.bsg_revoked_tokens.name },
      { name = "SPRING_DATA_REDIS_HOST", value = aws_elasticache_cluster.redis_bsg.cache_nodes[0].address },
      { name = "SPRING_DATA_REDIS_PORT", value = "6379" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.back_security_logs.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "back_security_service" {
  name            = "bsg-back-security-service"
  cluster         = aws_ecs_cluster.bsg_cluster.id
  task_definition = aws_ecs_task_definition.back_security_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.mis_subredes.ids
    security_groups  = [aws_security_group.ecs_security_sg.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.back_security_sd.arn
    container_name = "back-security"
    container_port = 8081
  }

  # Ignoramos cambios en la tarea para que GitHub Actions pueda actualizar 
  # la versión de la imagen sin que Terraform lo revierta en el futuro.
  lifecycle {
    ignore_changes = [task_definition]
  }
}

# =========================================================
# 14. Integración de API Gateway con ECS (VPC Link)
# =========================================================
resource "aws_apigatewayv2_vpc_link" "bsg_vpc_link" {
  name               = "bsg-vpc-link"
  security_group_ids = [aws_security_group.ecs_security_sg.id]
  subnet_ids         = data.aws_subnets.mis_subredes.ids
}

resource "aws_apigatewayv2_integration" "security_integration" {
  api_id             = aws_apigatewayv2_api.bsg_gateway.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_service_discovery_service.back_security_sd.arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.bsg_vpc_link.id
}

# HTTP API solo admite integraciones proxy; ANY incluye OPTIONS y lo manda por VPC Link → preflight no 2xx.
# Sin ruta ANY, API Gateway contesta OPTIONS usando cors_configuration del API.
locals {
  api_gateway_proxy_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]
}

resource "aws_apigatewayv2_route" "security_route" {
  for_each  = toset(local.api_gateway_proxy_methods)
  api_id    = aws_apigatewayv2_api.bsg_gateway.id
  route_key = "${each.key} /security-auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.security_integration.id}"
}

# =========================================================
# 15. IAM Roles & Security Group - DocViz Backend
# =========================================================
resource "aws_iam_role" "ecs_backend_task_role" {
  name = "bsg-ecs-backend-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Permisos explícitos para que el backend maneje los 3 buckets de S3
resource "aws_iam_role_policy" "s3_task_policy" {
  name = "bsg-s3-task-policy"
  role = aws_iam_role.ecs_backend_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
      Effect = "Allow"
      Resource = [
        aws_s3_bucket.soporte_bucket.arn,
        "${aws_s3_bucket.soporte_bucket.arn}/*",
        aws_s3_bucket.borradores_bucket.arn,
        "${aws_s3_bucket.borradores_bucket.arn}/*",
        aws_s3_bucket.workarea_bucket.arn,
        "${aws_s3_bucket.workarea_bucket.arn}/*"
      ]
    }]
  })
}

resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/ecs/bsg-backend"
  retention_in_days = 7
}

resource "aws_security_group" "ecs_backend_sg" {
  name   = "ecs-backend-sg"
  vpc_id = data.aws_vpc.mi_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rds_from_backend" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.ecs_backend_sg.id
}

# =========================================================
# 16. ECS Task & Service - DocViz Backend
# =========================================================
resource "aws_service_discovery_service" "backend_sd" {
  name = "docviz" # Dominio: docviz.bsg.internal
  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.bsg_namespace.id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl  = 60
      type = "SRV"
    }
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "backend_task" {
  family                   = "bsg-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024" # 1 vCPU — ingesta + embeddings + Git + Tomcat
  memory                   = "2048" # 2 GB — evita OOM con OpenAI/pgvector bajo carga
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_backend_task_role.arn

  container_definitions = jsonencode([{
    name         = "backend"
    image        = "mmercado94/backend-sesion1:3.0.33"
    essential    = true
    portMappings = [{ containerPort = 8080, hostPort = 8080, protocol = "tcp" }]
    environment = [
      { name = "JAVA_TOOL_OPTIONS", value = "-XX:MaxRAMPercentage=68 -XX:+ExitOnOutOfMemoryError -XX:+UseStringDeduplication" },
      { name = "SPRING_PROFILES_ACTIVE", value = "pdn" },
      { name = "DATABASE_URL", value = "jdbc:postgresql://${aws_db_instance.postgres_bsg.endpoint}/docviz" },
      { name = "DATABASE_USER", value = "bsg_admin" },
      { name = "DATABASE_PASSWORD", value = "PasswordSeguro123" },
      # Chat + embeddings OpenAI (misma clave). Modelos por defecto en application-pdn.properties.
      { name = "OPENAI_API_KEY", value = var.openai_api_key },
      # Spring Boot 3: relaxed binding a spring.ai.openai.*.api-key (por si el placeholder de properties falla en ECS).
      { name = "SPRING_AI_OPENAI_API_KEY", value = var.openai_api_key },
      { name = "SPRING_AI_OPENAI_CHAT_API_KEY", value = var.openai_api_key },
      { name = "SPRING_AI_OPENAI_EMBEDDING_API_KEY", value = var.openai_api_key },
      { name = "OPENAI_CHAT_MODEL", value = "gpt-4o-mini" },
      { name = "SPRING_AI_MODEL_EMBEDDING_TEXT", value = "openai" },
      { name = "FIREBASE_ENABLED", value = "true" },
      { name = "FIREBASE_PROJECT_ID", value = "sesion-bsg" },
      { name = "FIREBASE_CREDENTIALS_PATH", value = "sesion-bsg-firebase-adminsdk-fbsvc-25ee0429da.json" },
      { name = "GOOGLE_APPLICATION_CREDENTIALS", value = "sesion-bsg-firebase-adminsdk-fbsvc-25ee0429da.json" },
      { name = "DOCVIZ_EMBEDDINGS_PROVIDER", value = "spring-ai" },
      { name = "DOCVIZ_VECTOR_EMBEDDINGS_PROVIDER", value = "spring-ai" },
      { name = "DOCVIZ_SUPPORT_ENABLED", value = "true" },
      { name = "DOCVIZ_WORKSPACE_S3_ENABLED", value = "true" },
      { name = "DOCVIZ_SUPPORT_S3_REGION", value = "us-east-1" },
      { name = "DOCVIZ_SUPPORT_S3_BUCKET", value = aws_s3_bucket.soporte_bucket.bucket },
      { name = "DOCVIZ_WORKSPACE_S3_BORRADOR_BUCKET", value = aws_s3_bucket.borradores_bucket.bucket },
      { name = "DOCVIZ_WORKSPACE_S3_WORKAREA_BUCKET", value = aws_s3_bucket.workarea_bucket.bucket }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.backend_logs.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "backend_service" {
  name            = "bsg-backend-service"
  cluster         = aws_ecs_cluster.bsg_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.mis_subredes.ids
    security_groups  = [aws_security_group.ecs_backend_sg.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.backend_sd.arn
    container_name = "backend"
    container_port = 8080
  }
}

# =========================================================
# 17. Integración de API Gateway con Backend DocViz
# =========================================================
resource "aws_apigatewayv2_integration" "backend_integration" {
  api_id             = aws_apigatewayv2_api.bsg_gateway.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_service_discovery_service.backend_sd.arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.bsg_vpc_link.id
}

resource "aws_apigatewayv2_route" "backend_route" {
  for_each  = toset(local.api_gateway_proxy_methods)
  api_id    = aws_apigatewayv2_api.bsg_gateway.id
  route_key = "${each.key} /docviz/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.backend_integration.id}"
}

# =========================================================
# 18. Frontend SPA (Nginx) — ALB + ECS Fargate
# =========================================================
# Imagen: Docker Hub (misma convención que los backends). Build:
#   docker build -t mmercado94/frontend-sesion1:1.0.7 sesion1/frontend-sesion1
# El entrypoint genera runtime-config.js con BACKEND_URL / SECURITY_URL → API Gateway público.

resource "aws_security_group" "alb_frontend_sg" {
  name        = "alb-bsg-frontend"
  description = "HTTP del balanceador hacia el SPA"
  vpc_id      = data.aws_vpc.mi_vpc.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_frontend_sg" {
  name        = "ecs-bsg-frontend-sg"
  description = "ECS frontend tasks; ingress only from frontend ALB"
  vpc_id      = data.aws_vpc.mi_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_frontend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "bsg_frontend_alb" {
  name               = "bsg-frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_frontend_sg.id]
  subnets            = data.aws_subnets.mis_subredes.ids
}

resource "aws_lb_target_group" "bsg_frontend_tg" {
  name        = "bsg-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.mi_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "bsg_frontend_http" {
  load_balancer_arn = aws_lb.bsg_frontend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bsg_frontend_tg.arn
  }
}

resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/ecs/bsg-frontend"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "bsg-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name         = "frontend"
    image        = "mmercado94/frontend-sesion1:1.0.10"
    essential    = true
    portMappings = [{ containerPort = 80, hostPort = 80, protocol = "tcp" }]
    environment = [
      # Rutas relativas al mismo ALB: Nginx /api/ y /security-api/ → Cloud Map (timeouts largos). Evita API Gateway en el navegador.
      { name = "BACKEND_URL", value = "/api" },
      { name = "SECURITY_URL", value = "/security-api" },
      { name = "DOCVIZ_UPSTREAM", value = "http://docviz.bsg.internal:8080" },
      { name = "SECURITY_UPSTREAM", value = "http://security.bsg.internal:8081" },
      { name = "NGINX_RESOLVER", value = "169.254.169.253" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.frontend_logs.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "frontend_service" {
  name            = "bsg-frontend-service"
  cluster         = aws_ecs_cluster.bsg_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.bsg_frontend_tg.arn
    container_name   = "frontend"
    container_port   = 80
  }

  network_configuration {
    subnets          = data.aws_subnets.mis_subredes.ids
    security_groups  = [aws_security_group.ecs_frontend_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_lb_listener.bsg_frontend_http]
}

output "frontend_alb_dns" {
  value       = "http://${aws_lb.bsg_frontend_alb.dns_name}"
  description = "URL del SPA (HTTP). Añade HTTPS con ACM + listener 443 cuando tengas dominio."
}