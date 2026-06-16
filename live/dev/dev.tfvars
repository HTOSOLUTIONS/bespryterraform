api_env_vars = {
  ASPNETCORE_ENVIRONMENT = "dev"
  DB_PROVIDER            = "postgres"
}

# Pins the Solution Stack Name used in Elastic Beanstalk
solution_stack_name = "64bit Amazon Linux 2023 v3.7.2 running .NET 8"

# Temporary IPs for developer access
ssh_ingress_cidr       = "68.118.0.123/32"
developer_cidr         = ["68.118.0.123/32", "75.100.99.207/32"]
db_publicly_accessible = true

enable_acm = true


# SMS
sms_origination_identity   = "arn:aws:sms-voice:us-east-2:891377401485:phone-number/phone-7232eb869a824266bf051743495180f0"
sms_configuration_set_name = "bespry-dev-sms"
