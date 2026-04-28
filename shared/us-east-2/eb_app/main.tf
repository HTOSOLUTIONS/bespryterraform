resource "aws_elastic_beanstalk_application" "this" {
  name = var.app_name

  # Safety: prevents accidental destroy of the shared app container
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    App       = "BeSpry"
    Scope     = "shared"
    ManagedBy = "Terraform"
  }
}
