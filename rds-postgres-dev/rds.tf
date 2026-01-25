resource "aws_db_subnet_group" "default_vpc" {
  name       = "dbsubnet-defaultvpc-${var.environment}"
  subnet_ids = data.aws_subnets.default_vpc_subnets.ids

  tags = {
    Name        = "dbsubnet-defaultvpc-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "postgres-${var.environment}"

  engine            = "postgres"
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  port = 5432

  publicly_accessible    = var.publicly_accessible
  vpc_security_group_ids = [aws_security_group.rds_postgres.id]
  db_subnet_group_name   = aws_db_subnet_group.default_vpc.name

  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true

  # Keep it simple for dev; you can harden later.
  apply_immediately = true

  tags = {
    Name        = "postgres-${var.environment}"
    Environment = var.environment
  }
}
