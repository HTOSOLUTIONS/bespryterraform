/*
  Outputs for the Elastic Beanstalk environment.

  We now explicitly create and own the EB *instance* security group in this module,
  so we output it directly (no parsing / no EB-managed SG dependency).

  Elastic Beanstalk still does not expose the ALB/ELB security group IDs as direct attributes,
  so we continue parsing ELBSecurityGroups from all_settings (optional).
*/

output "env_name" {
  value = aws_elastic_beanstalk_environment.this.name
}

output "environment_cname" {
  value = aws_elastic_beanstalk_environment.this.cname
}

# -------------------------
# Instance Security Group
# -------------------------

output "instance_security_group_id" {
  description = "Security group ID used by EB EC2 instances (Terraform-managed)."
  value       = aws_security_group.eb_instance.id
}

output "instance_security_group_ids" {
  description = "Security group IDs used by EB EC2 instances (Terraform-managed)."
  value       = [aws_security_group.eb_instance.id]
}

# -------------------------
# ALB / ELB Security Groups (parsed)
# -------------------------

locals {
  # Might be missing, null, or empty depending on EB lifecycle/state.
  eb_elb_sg_csv_raw = try(
    one([
      for s in aws_elastic_beanstalk_environment.this.all_settings : s.value
      if s.namespace == "aws:ec2:vpc" && s.name == "ELBSecurityGroups"
    ]),
    null
  )

  eb_elb_sg_csv = (
    local.eb_elb_sg_csv_raw == null
      ? ""
      : tostring(local.eb_elb_sg_csv_raw)
  )

  eb_elb_sg_ids = (
    length(trimspace(local.eb_elb_sg_csv)) > 0
      ? split(",", local.eb_elb_sg_csv)
      : []
  )
}

output "elb_security_group_ids" {
  description = "Security group IDs attached to the EB load balancer (ALB)."
  value       = local.eb_elb_sg_ids
}

output "elb_security_group_id" {
  description = "First security group ID attached to the EB load balancer (ALB)."
  value       = try(local.eb_elb_sg_ids[0], null)
}
