data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "api_ec2_role" {
  name               = "bespry-api-ec2-role-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Baseline permissions commonly required for EB web apps
resource "aws_iam_role_policy_attachment" "eb_webtier" {
  role       = aws_iam_role.api_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# Attach your existing Cognito admin policy (used by the API)
resource "aws_iam_role_policy_attachment" "cognito_admin" {
  role       = aws_iam_role.api_ec2_role.name
  policy_arn = "arn:aws:iam::891377401485:policy/aws-cognito-user-admin"
}

resource "aws_iam_instance_profile" "api_instance_profile" {
  name = "bespry-api-ec2-role-${var.env}"
  role = aws_iam_role.api_ec2_role.name
}
