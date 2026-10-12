resource "aws_db_subnet_group" "postgres" {
  name        = "${var.name}-postgres"
  description = "Private subnets for the PostgreSQL RDS instance"
  subnet_ids  = module.vpc.private_subnets

  tags = merge(var.tags, {
    Name = "${var.name}-postgres"
  })
}

# Access is deliberately limited to private IPv4 addresses in this VPC. There
# is no public IP or internet route to this database instance.
resource "aws_security_group" "postgres" {
  name_prefix = "${var.name}-postgres-"
  description = "PostgreSQL access from within the VPC only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow response traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-postgres"
  })
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.name}-postgres"

  engine         = "postgres"
  engine_version = var.postgres_engine_version
  instance_class = var.db_instance_class
  allocated_storage= 50

  db_name  = var.database_name
  username = var.database_username

  # RDS stores the generated password in AWS Secrets Manager. No password is
  # present in Terraform configuration or state inputs.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  backup_retention_period    = var.db_backup_retention_days
  backup_window              = "03:00-03:30"
  maintenance_window         = "sun:04:00-sun:04:30"
  copy_tags_to_snapshot      = true
  deletion_protection        = true
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${var.name}-postgres-final"
  auto_minor_version_upgrade = true
  apply_immediately          = false

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true

  tags = merge(var.tags, {
    Name = "${var.name}-postgres"
  })
}
