BeSpry stack invariants (do not break)

Primary region is us-east-2 for all infrastructure stacks
Elastic Beanstalk, EC2, ALB, RDS, S3, SSM, CloudWatch, etc. live in us-east-2.
Terraform’s default provider region must remain us-east-2.

Frontend hosting uses AWS Amplify with custom domains
Amplify uses CloudFront under the hood. We do not manage CloudFront directly in Terraform.
Frontend SSL is Amplify-managed (ACM + CloudFront handled by Amplify). Do not add Terraform-managed frontend certs unless explicitly planned.

API SSL terminates at the ALB (not on EC2 instances)
The API uses ACM certificates in us-east-2 attached to the Elastic Beanstalk ALB.
We do not use certbot/Let’s Encrypt or commit private keys into .ebextensions.

Environment identity is explicit
Elastic Beanstalk environment variables set ASPNETCORE_ENVIRONMENT to one of: dev|stage|prod.
This selects appsettings.{env}.json in the API.
builder.Environment.IsDevelopment() is reserved for local development only.

Secrets are Option A
Secrets are stored in SSM Parameter Store (SecureString) under /bespry/{env}/... and referenced at runtime (dynamic references). Terraform must not read secret values.