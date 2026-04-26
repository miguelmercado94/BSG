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
  cidr_blocks       = ["170.245.158.194/32"]
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
  identifier           = "bsg-rds-instance"
  allocated_storage    = 20
  storage_type         = "gp3"
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.t3.micro" 
  db_name              = "postgres"
  username             = "bsg_admin"
  password             = "PasswordSeguro123" 
  
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

  hash_key     = "access_token_hash"

  attribute {
    name = "access_token_hash"
    type = "S"
  }

  attribute {
    name = "refresh_token_hash"
    type = "S"
  }

  global_secondary_index {
    name               = "refresh_token_hash_index"
    key_schema {
      attribute_name = "refresh_token_hash"
      key_type       = "HASH"
    }
    projection_type    = "ALL"
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
  value       = aws_dynamodb_table.bsg_revoked_tokens.name
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
    allow_origins = ["*"] # En producción se cambia por tu dominio real
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
  }
}

resource "aws_apigatewayv2_stage" "bsg_gateway_default_stage" {
  api_id      = aws_apigatewayv2_api.bsg_gateway.id
  name        = "$default"
  auto_deploy = true
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
  health_check_custom_config {}
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
    name      = "back-security"
    image     = "mmercado94/back-security-sesion1:1.0.2"
    essential = true
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
    registry_arn = aws_service_discovery_service.back_security_sd.arn
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

resource "aws_apigatewayv2_route" "security_route" {
  api_id    = aws_apigatewayv2_api.bsg_gateway.id
  route_key = "ANY /security-auth/{proxy+}"
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
      Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
      Effect   = "Allow"
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
  health_check_custom_config {}
}

resource "aws_ecs_task_definition" "backend_task" {
  family                   = "bsg-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"  # 0.5 vCPU 
  memory                   = "1024" # 1GB RAM 
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_backend_task_role.arn

  container_definitions = jsonencode([{
    name      = "backend"
    image     = "mmercado94/backend-sesion1:3.0.0"
    essential = true
    portMappings = [{ containerPort = 8080, hostPort = 8080, protocol = "tcp" }]
    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "pdn" },
      { name = "DATABASE_URL", value = "jdbc:postgresql://${aws_db_instance.postgres_bsg.endpoint}/docviz" },
      { name = "DATABASE_USER", value = "bsg_admin" },
      { name = "DATABASE_PASSWORD", value = "PasswordSeguro123" },
      { name = "GEMINI_API_KEY", value = "AIzaSyDU3TtHQH9N-DGDeQlARuk1voQ_h77BQjQ" },
      { name = "GEMINI_MODEL", value = "gemini-2.5-flash" },
      { name = "FIREBASE_ENABLED", value = "true" },
      { name = "FIREBASE_PROJECT_ID", value = "sesion-bsg" },
      { name = "FIREBASE_CREDENTIALS_PATH", value = "sesion-bsg-firebase-adminsdk-fbsvc-25ee0429da.json" },
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

  lifecycle {
    ignore_changes = [task_definition]
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
  api_id    = aws_apigatewayv2_api.bsg_gateway.id
  route_key = "ANY /docviz/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.backend_integration.id}"
}