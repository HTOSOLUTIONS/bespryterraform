output "api_fqdn" {
  value = local.api_fqdn
}

output "acm_cert_arn" {
  value = var.enable_acm ? module.api_cert[0].cert_arn : null
}

output "eb_environment_name" {
  value = module.eb_api.env_name
}

output "eb_environment_cname" {
  value = module.eb_api.environment_cname
}

output "reminders_queue_url" {
  value = aws_sqs_queue.reminders.id
}

output "reminders_queue_arn" {
  value = aws_sqs_queue.reminders.arn
}