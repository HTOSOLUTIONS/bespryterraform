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
  ) ? var.public_subnet_ids : sort(data.aws_subnets.default_in_vpc.ids)

  env_vars = var.environment_variables
}


# Removed to implement shared environment
# data "aws_elastic_beanstalk_application" "this" {
#   name = var.app_name
# }


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


resource "aws_security_group_rule" "ssh_from_dev" {
  count             = var.ssh_ingress_cidr != null ? 1 : 0
  
  type              = "ingress"
  security_group_id = aws_security_group.eb_instance.id

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = [var.ssh_ingress_cidr]

  description = "TEMP SSH from developer machine"
}



resource "aws_elastic_beanstalk_environment" "this" {
  name        = var.env_name
  application = var.application_name

  solution_stack_name = coalesce(var.solution_stack_name, data.aws_elastic_beanstalk_solution_stack.dotnet8_al2023.name)


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
	  name      = "DisableIMDSv1"
	  value     = "true"
	}


  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.eb_instance.id
  }

  # Load Balancer Settings - Start

  # Ensure ALB (not Classic)
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  # ALB automatically adds listener for port 80
  # Listener :80 enabled (NO RedirectHTTPToHTTPS here)
  # setting {
  #  namespace = "aws:elbv2:listener:80"
  #  name      = "ListenerEnabled"
  #  value     = "true"
  # }

  # setting {
  #  namespace = "aws:elbv2:listener:80"
  #  name      = "Protocol"
  #  value     = "HTTP"
  # }

  # Listener :443 enabled
	dynamic "setting" {
	  for_each = var.cert_arn != null ? [1] : []
	  content {
		namespace = "aws:elbv2:listener:443"
		name      = "ListenerEnabled"
		value     = "true"
	  }
	}

	dynamic "setting" {
	  for_each = var.cert_arn != null ? [1] : []
	  content {
		namespace = "aws:elbv2:listener:443"
		name      = "Protocol"
		value     = "HTTPS"
	  }
	}

	dynamic "setting" {
	  for_each = var.cert_arn != null ? [1] : []
	  content {
		namespace = "aws:elbv2:listener:443"
		name      = "SSLCertificateArns"
		value     = var.cert_arn
	  }
	}


  # Load Balancer Settings - End

  dynamic "setting" {
    for_each = local.env_vars
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = tostring(setting.value)
    }
  }
  
	dynamic "setting" {
	  for_each = var.ec2_key_name != null ? [var.ec2_key_name] : []
	  content {
		namespace = "aws:autoscaling:launchconfiguration"
		name      = "EC2KeyName"
		value     = setting.value
	  }
	}
  
  
}

# EB exports the load balancer ARN(s) in load_balancers — look up by ARN
# EB exports the load balancer ARN(s) in load_balancers — look up by ARN
data "aws_lb" "eb_alb" {
  arn        = aws_elastic_beanstalk_environment.this.load_balancers[0]
  depends_on = [aws_elastic_beanstalk_environment.this]
}

data "aws_lb_listener" "http_80" {
  # count             = var.cert_arn != null ? 1 : 0
  count             = var.enable_http_to_https_redirect ? 1 : 0
  load_balancer_arn = data.aws_lb.eb_alb.arn
  port              = 80
}

resource "aws_lb_listener_rule" "redirect_http_to_https" {
  # Changing Rule
  # count        = var.cert_arn != null ? 1 : 0
  count        = var.enable_http_to_https_redirect ? 1 : 0
  
  listener_arn = data.aws_lb_listener.http_80[0].arn
  priority     = 10

  action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
