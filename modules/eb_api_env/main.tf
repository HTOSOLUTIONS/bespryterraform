data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_in_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_elastic_beanstalk_solution_stack" "dotnet8_al2023" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux 2023.*running \\.NET 8$"
}

locals {
  resolved_vpc_id = var.vpc_id != null ? var.vpc_id : data.aws_vpc.default.id

  resolved_public_subnets = (
    var.public_subnet_ids != null && length(var.public_subnet_ids) > 0
  ) ? var.public_subnet_ids : data.aws_subnets.default_in_vpc.ids

  env_vars = var.environment_variables
}

resource "aws_elastic_beanstalk_application" "this" {
  name = var.app_name
}

resource "aws_security_group" "eb_instance" {
  name        = "${var.env_name}-eb-instances"
  description = "Security group for EB EC2 instances"
  vpc_id      = local.resolved_vpc_id

	tags = {
	  Name      = "${var.env_name}-eb-instances"
	  App       = var.app_name
	  Env       = var.env
	  ManagedBy = "Terraform"
	}

}


resource "aws_elastic_beanstalk_environment" "this" {
  name        = var.env_name
  application = aws_elastic_beanstalk_application.this.name

  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.dotnet8_al2023.name

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = tostring(var.min_size)
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = tostring(var.max_size)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = local.resolved_vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", local.resolved_public_subnets)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", local.resolved_public_subnets)
  }

  # HTTPS listener + cert
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "ListenerEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = var.cert_arn
  }

  # Redirect HTTP -> HTTPS
  setting {
    namespace = "aws:elbv2:listener:80"
    name      = "ListenerEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elbv2:listener:80"
    name      = "RedirectHTTPToHTTPS"
    value     = "true"
  }


	# EB control plane permissions (shared across stacks)
	setting {
	  namespace = "aws:elasticbeanstalk:environment"
	  name      = "ServiceRole"
	  value     = var.service_role_arn
	}

	# Required: runtime identity of EC2 instances (per-stack)
	setting {
	  namespace = "aws:autoscaling:launchconfiguration"
	  name      = "IamInstanceProfile"
	  value     = var.instance_profile_name
	}

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.eb_instance.id
  }



  dynamic "setting" {
    for_each = local.env_vars
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
    }
  }
}
