api_env_vars = {
  ASPNETCORE_ENVIRONMENT = "demo"
  DB_PROVIDER = "mysql"
}

# Pins the Solution Stack Name used in Elastic Beanstalk
solution_stack_name = "64bit Amazon Linux 2023 v3.7.1 running .NET 8"

# Temporary IPs for developer access
ssh_ingress_cidr = "68.118.0.123/32"
developer_cidr   = "68.118.0.123/32"
db_publicly_accessible = true

enable_acm = true
