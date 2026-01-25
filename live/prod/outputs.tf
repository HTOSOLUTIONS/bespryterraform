# Add outputs as your modules produce them, e.g.:
# output "api_url" {
#   value = module.eb_api_env.api_url
# }

output "environment" {
  value = var.environment
}
