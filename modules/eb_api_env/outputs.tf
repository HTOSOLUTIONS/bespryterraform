output "env_name" {
  value = aws_elastic_beanstalk_environment.this.name
}

output "environment_cname" {
  value = aws_elastic_beanstalk_environment.this.cname
}
