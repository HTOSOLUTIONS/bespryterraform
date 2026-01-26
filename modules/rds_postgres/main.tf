data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_in_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  resolved_vpc_id  = var.vpc_id != null ? var.vpc_id : data.aws_vpc.default.id
  resolved_subnets = (var.subnet_ids != null && length(var.subnet_ids) > 0) ? var.subnet_ids : data.aws_subnets.default_in_vpc.ids
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnets"
  subnet_ids = local.resolved_subnets
  tags       = var.tags
}

resource "aws_security_group" "rds" {
  name        = "${var.identifier}-sg"
  description = "RDS security group"
  vpc_id      = local.resolved_vpc_id
  tags        = var.tags
}

# NOTE: We will allow inbound from EB instances later by adding a SG rule
# that references the EB security group. For POC, you can keep it closed
# or temporarily open to your IP (not recommended).
# We'll do the clean SG-to-SG rule once we output EB SG from the EB module.

resource "aws_db_instance" "this" {
  identifier              = var.identifier
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  db_name                 = var.db_name
  username                = var.username
  password                = var.password

  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]

  publicly_accessible     = var.publicly_accessible
  skip_final_snapshot     = true

  tags = var.tags
}
