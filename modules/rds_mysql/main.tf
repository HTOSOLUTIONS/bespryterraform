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
  resolved_vpc_id = var.vpc_id != null ? var.vpc_id : data.aws_vpc.default.id

  resolved_subnets = (
    var.subnet_ids != null && length(var.subnet_ids) > 0
  ) ? var.subnet_ids : data.aws_subnets.default_in_vpc.ids
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnets"
  subnet_ids = local.resolved_subnets
  tags       = var.tags
}

resource "aws_security_group" "rds" {
  name        = "${var.identifier}-sg"
  description = "RDS MySQL security group"
  vpc_id      = local.resolved_vpc_id
  tags        = var.tags
}

# Permanent: allow MySQL from EB instances SG only
resource "aws_vpc_security_group_ingress_rule" "from_app_sg" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.allowed_security_group_id

  ip_protocol = "tcp"
  from_port   = var.db_port
  to_port     = var.db_port

  description = "MySQL from EB instance SG"
}


# Temporary: allow MySQL from your dev machine CIDR (e.g., x.x.x.x/32)
locals {
  create_dev_cidr_rule = var.developer_cidr != null
}

resource "aws_vpc_security_group_ingress_rule" "from_dev_cidr" {
  for_each = local.create_dev_cidr_rule ? { "rule" = true } : {}

  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = var.developer_cidr

  ip_protocol = "tcp"
  from_port   = var.db_port
  to_port     = var.db_port

  description = "TEMP MySQL from developer machine"
}


# Allow RDS outbound (AWS recommended default stance)
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound"
}

resource "aws_db_instance" "this" {
  identifier        = var.identifier
  engine            = "mysql"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.username
  password = var.password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = var.publicly_accessible
  skip_final_snapshot = true

  tags = var.tags
}
