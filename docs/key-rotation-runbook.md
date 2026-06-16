# EC2 Key Pair Rotation Runbook

## Purpose

This document describes how EC2 SSH key pairs are managed across environments in this repo, and the exact steps to rotate a key pair safely when needed.

---

## How Key Pairs Are Managed

Both `dev` and `stage` use **Terraform-managed EC2 key pairs**. Terraform owns the full lifecycle:

| Resource | File | Description |
|---|---|---|
| `tls_private_key.eb_ssh` | `ssh_key.tf` | Generates a 4096-bit RSA key pair in Terraform state |
| `aws_key_pair.eb_ssh` | `ssh_key.tf` | Uploads the public key to AWS EC2 |
| `local_sensitive_file.eb_ssh_pem` | `ssh_key.tf` | Writes the private key to `.keys/<name>.pem` (mode 0600) |
| `local_file.eb_ssh_pub` | `ssh_key.tf` | Writes the public key to `.keys/<name>.pub` |

The EB modules (`module.eb_api`, `module.eb_service`) reference `aws_key_pair.eb_ssh.key_name` directly — not a variable — so the key name is always derived from the Terraform-managed resource.

The `.keys/` directory is excluded from git via `.gitignore`.

> **Important:** Private key material is stored in Terraform state. Treat state files as secrets.

---

## Key Rotation Steps

### 1. Apply the rotation

```powershell
$env:AWS_PROFILE='besprytwo'
Set-Location "c:/Users/jhrhi/source/repos/aws-iac/live/dev"   # or live/stage
terraform plan -var-file dev.tfvars   # review — expect aws_key_pair replacement
terraform apply -var-file dev.tfvars
```

Terraform will:
- Destroy the old `aws_key_pair` in AWS
- Generate a new `tls_private_key`
- Upload the new public key as a new `aws_key_pair`
- Write the new `.pem` and `.pub` to `.keys/`

### 2. Fix Windows PEM file permissions

OpenSSH on Windows rejects key files with inherited ACLs. After apply, run:

```powershell
$pem = "c:/Users/jhrhi/source/repos/aws-iac/live/dev/.keys/bespry-eb-dev.pem"
icacls $pem /inheritance:r
icacls $pem /grant:r "HTO-INSPIRON24\jhrhi:(R)"
```

Verify with:
```powershell
icacls $pem
# Expected: HTO-INSPIRON24\jhrhi:(R)
```

### 3. Recycle the EB instance

Existing EC2 instances retain their launch-time key. The rotated key only applies to **newly launched** instances. Recycle the running instance:

**Option A — Manual (safest for single-instance dev):**
1. EC2 Console → find the running EB instance (check `LaunchTime` vs rotation date)
2. Instance state → **Terminate (delete)**
3. ASG automatically launches a replacement with the new key

**Option B — Instance refresh (preferred for multi-instance):**
1. EC2 → Auto Scaling Groups → find the EB ASG
2. Instance refresh tab → Start instance refresh
3. Select **Launch before terminating** (Max 110% for single-instance groups)

### 4. Redeploy the application version

> **Critical gotcha:** When a new instance launches long after the initial environment deployment, the EB CloudFormation bootstrap URLs (pre-signed S3 URLs) may be expired. The instance will start but nginx will serve its default 404 page instead of proxying to the .NET app.

Force a fresh deployment after the instance replacement:

```powershell
$env:AWS_PROFILE='besprytwo'
$env:AWS_DEFAULT_REGION='us-east-2'

# Get current version label
aws elasticbeanstalk describe-environments `
  --environment-names bespry-api-dev `
  --query "Environments[0].VersionLabel" --output text

# Redeploy it
aws elasticbeanstalk update-environment `
  --environment-name bespry-api-dev `
  --version-label "<version-label-from-above>"
```

Wait for `Status: Ready` and `Health: Green`:

```powershell
aws elasticbeanstalk describe-environments `
  --environment-names bespry-api-dev `
  --query "Environments[0].{Status:Status,Health:Health}" --output table
```

### 5. Verify SSH access

```powershell
Set-Location "c:/Users/jhrhi/source/repos/aws-iac/live/dev/.keys"

# Get new instance public IP
$env:AWS_PROFILE='besprytwo'; $env:AWS_DEFAULT_REGION='us-east-2'
aws ec2 describe-instances `
  --filters "Name=tag:elasticbeanstalk:environment-name,Values=bespry-api-dev" `
            "Name=instance-state-name,Values=running" `
  --query "Reservations[].Instances[].PublicIpAddress" --output text

ssh -i bespry-eb-dev.pem ec2-user@<new-ip>
```

---

## Importing an Existing Key Pair

If a key pair already exists in AWS before Terraform managed it, import it before running `apply` to avoid a duplicate-name error:

```powershell
$env:AWS_PROFILE='besprytwo'
Set-Location "c:/Users/jhrhi/source/repos/aws-iac/live/dev"
terraform import aws_key_pair.eb_ssh bespry-eb-dev
```

After import, run `plan` and check whether Terraform wants to **replace** the key pair (because the public key differs). If it does, that means Terraform will rotate the key on apply — see steps above.

---

## Symptom Reference

| Symptom | Likely Cause | Fix |
|---|---|---|
| `Permission denied (publickey)` on SSH | Wrong PEM file, or instance still has old key | Use new PEM; recycle instance |
| `Bad permissions` on PEM file | Windows ACL too open | Run `icacls` fix (Step 2) |
| nginx default 404 on API endpoint | App not deployed to new instance (expired bootstrap URL) | Redeploy app version (Step 4) |
| `aws_key_pair must be replaced` in plan | Public key differs from Terraform-generated key | Expected on first rotation; apply to proceed |
