# create-terraform-structure.ps1
param(
  [string]$Root = (Get-Location).Path,

  # Project/name prefix for state paths, tags, etc.
  [string]$Project = "bespry",

  # AWS region default
  [string]$AwsRegion = "us-east-1",

  # Remote state config defaults (edit as needed)
  [string]$TfStateBucket = "REPLACE_ME_tfstate_bucket",
  [string]$TfStateDdbTable = "REPLACE_ME_tfstate_lock_table",

  # If set, overwrite existing files
  [switch]$Force
)

$folders = @(
  "modules",
  "modules\eb_api_env",
  "modules\acm_api_cert",
  "modules\amplify_app",
  "modules\route53",

  "live",
  "live\_global",
  "live\dev",
  "live\stage",
  "live\prod"
)

function Ensure-Dir([string]$relativePath) {
  $path = Join-Path $Root $relativePath
  New-Item -ItemType Directory -Path $path -Force | Out-Null
}

function Ensure-FileWithContent([string]$relativePath, [string]$content) {
  $path = Join-Path $Root $relativePath
  $exists = Test-Path $path

  if ($exists -and -not $Force) {
    return
  }

  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  Set-Content -Path $path -Value $content -Encoding UTF8
}

# --- Create folders ---
foreach ($f in $folders) { Ensure-Dir $f }

# --- Global files ---
$versionsTf = @"
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
"@

$providersTf = @"
# Providers shared across all environments
provider "aws" {
  region = var.aws_region

  # Optional: if you use AWS SSO profiles, you can uncomment and set:
  # profile = var.aws_profile
}
"@

$localsTf = @"
locals {
  project = "$Project"

  # Common tags applied to resources (use in modules/resources as needed)
  tags = {
    Project   = "$Project"
    ManagedBy = "Terraform"
  }
}
"@

Ensure-FileWithContent "live\_global\versions.tf"  $versionsTf
Ensure-FileWithContent "live\_global\providers.tf" $providersTf
Ensure-FileWithContent "live\_global\locals.tf"    $localsTf

# --- Env templates ---
function BackendHcl([string]$env) {
@"
# Terraform remote state config for $env
bucket         = "$TfStateBucket"
key            = "$Project/$env/terraform.tfstate"
region         = "$AwsRegion"
dynamodb_table = "$TfStateDdbTable"
encrypt        = true
"@
}

function MainTf([string]$env) {
@"
# Root module for $env
# Recommended: keep this file thin—wire modules together here.

module "eb_api_env" {
  source = "../../modules/eb_api_env"

  # Example inputs (define in your module as needed)
  # env        = "$env"
  # project    = local.project
  # tags       = local.tags
  # aws_region = var.aws_region
}

# Optional modules
# module "acm_api_cert" {
#   source = "../../modules/acm_api_cert"
# }

# module "amplify_app" {
#   source = "../../modules/amplify_app"
# }

# module "route53" {
#   source = "../../modules/route53"
# }
"@
}

function VariablesTf([string]$env) {
@"
variable "aws_region" {
  type    = string
  default = "$AwsRegion"
}

# Optional if you use AWS profiles locally (SSO, named profiles, etc.)
# variable "aws_profile" {
#   type    = string
#   default = "default"
# }

variable "environment" {
  type    = string
  default = "$env"
}
"@
}

function OutputsTf([string]$env) {
@"
# Add outputs as your modules produce them, e.g.:
# output "api_url" {
#   value = module.eb_api_env.api_url
# }

output "environment" {
  value = var.environment
}
"@
}

foreach ($env in @("dev", "stage", "prod")) {
  Ensure-FileWithContent "live\$env\backend.hcl"   (BackendHcl $env)
  Ensure-FileWithContent "live\$env\main.tf"       (MainTf $env)
  Ensure-FileWithContent "live\$env\variables.tf"  (VariablesTf $env)
  Ensure-FileWithContent "live\$env\outputs.tf"    (OutputsTf $env)
}

# --- Optional: module placeholders (README files so folders aren't empty) ---
$moduleReadme = @"
# Module placeholder

Define resources for this module here.
Suggested files:
- main.tf
- variables.tf
- outputs.tf
"@

foreach ($m in @("modules\eb_api_env", "modules\acm_api_cert", "modules\amplify_app", "modules\route53")) {
  Ensure-FileWithContent "$m\README.md" $moduleReadme
}

Write-Host "Done."
Write-Host "Created structure at: $Root"
Write-Host "NOTE: Update TfStateBucket/TfStateDdbTable placeholders before running 'terraform init'."
Write-Host "Tip: Re-run with -Force to overwrite template content."
