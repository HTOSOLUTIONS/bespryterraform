api_env_vars = {
  ASPNETCORE_ENVIRONMENT = "stage"
  db_password            = "bamBoo$209" # for POC; move to Secrets Manager soon
}


ssh_ingress_cidr = "47.134.129.33/32"
developer_cidr   = "47.134.129.33/32"
db_publicly_accessible = true

