resource "aws_security_group" "api_ec2" {
  name        = "api-ec2-${var.environment}"
  description = "Future EC2 API security group (source for DB access)"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "api-ec2-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds_postgres" {
  name        = "rds-postgres-${var.environment}"
  description = "RDS Postgres access: dev IP + future EC2 SG"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Developer access (pgAdmin/EF)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.developer_cidr]
  }

  ingress {
    description     = "EC2 API access"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.api_ec2.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "rds-postgres-${var.environment}"
    Environment = var.environment
  }
}
