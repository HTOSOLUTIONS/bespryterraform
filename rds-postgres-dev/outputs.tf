output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "rds_port" {
  value = aws_db_instance.postgres.port
}

output "rds_db_name" {
  value = aws_db_instance.postgres.db_name
}

output "rds_security_group_id" {
  value = aws_security_group.rds_postgres.id
}

output "future_api_security_group_id" {
  value = aws_security_group.api_ec2.id
}
