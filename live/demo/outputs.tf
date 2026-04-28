output "api_fqdn" {
  value = local.api_fqdn
}

output "acm_cert_arn" {
  value = module.api_cert.cert_arn
}

output "eb_environment_name" {
  value = module.eb_api.env_name
}

output "eb_environment_cname" {
  value = module.eb_api.environment_cname
}
