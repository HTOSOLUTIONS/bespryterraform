module "db" {
  source     = "../../modules/rds_postgres"
  identifier = "bespry-demo-db"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  tags     = local.tags

  # TEMP: allow PostgreSQL from your developer machine
  developer_cidr = var.developer_cidr

  # PERMANENT: allow PostgreSQL from EB EC2 instances only
  allowed_security_group_ids = [
    module.eb_api.instance_security_group_id,
    module.eb_service.instance_security_group_id
  ]



  publicly_accessible = var.db_publicly_accessible


}
