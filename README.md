# AWS Infrastructure as Code (IaC)

This repository defines the **BeSpry AWS infrastructure** using **Terraform**.  
Its primary goal is to provide **repeatable, auditable, and environment-safe** infrastructure for running the BeSpry platform across multiple environments (dev, stage, prod), while minimizing ClickOps and preserving institutional knowledge.

This repo intentionally favors **clarity and long-term maintainability** over cleverness.

---

## High-Level Goals

- Fully scripted AWS infrastructure (ScriptOps / CodeOps)
- Clear separation between **shared** and **per-environment** resources
- Safe Terraform state management
- Explicit IAM boundaries
- Support a **temporary MySQL → long-term Postgres** migration path
- Make the system understandable to future engineers (and future-you)

---

## What This Repo Manages

At a high level, this repo provisions:

- **Elastic Beanstalk** (.NET 8 on Amazon Linux 2023)
- **Application Load Balancer (ALB)** with HTTPS
- **ACM certificates** with Route53 DNS validation
- **Amazon Cognito** user pools and clients
- **RDS databases** (MySQL today, Postgres as the long-term target)
- **S3 buckets** for application storage
- **IAM roles & instance profiles**
- **Terraform remote state** (S3 + DynamoDB locking)

---

## Repository Structure

```text
aws-iac/
├── README.md                # This document (orientation + how to use)
│
├── bootstrap/               # One-time Terraform backend setup
│   └── terraform-state/     # S3 bucket + DynamoDB lock table
│
├── modules/                 # Reusable Terraform modules
│   ├── eb_api_env/          # Elastic Beanstalk app + environment
│   ├── rds_mysql/           # RDS MySQL (temporary / legacy support)
│   ├── rds_postgres/        # RDS Postgres (long-term target)
│   ├── cognito_user_pool/   # Cognito user pool + client
│   └── s3_app_bucket/       # Application S3 bucket
│
├── live/                    # Environment-specific stacks
│   ├── _global/             # Shared Terraform config (providers, versions)
│   ├── dev/                 # Development environment
│   ├── stage/               # Staging / demo environment
│   └── prod/                # Production environment
│
└── docs/                    # Deep-dive documentation (architecture, IAM, etc.)
```

---

## Terraform State & Backend

Terraform state is **remote and shared**:

- **S3** stores state files
- **DynamoDB** provides state locking
- One backend is shared across all stacks

This backend is created **once** using the `bootstrap/` folder and should rarely (if ever) change.

Each environment (`dev`, `stage`, `prod`) uses:

```hcl
backend "s3" {}
```

with environment-specific `backend.hcl` files.

---

## Environment Model

Each folder under `live/` represents **one complete AWS stack**:

- Independent Terraform state
- Independent RDS database
- Independent EB environment
- Independent Cognito user pool

This ensures:

- No accidental cross-environment coupling
- Safe experimentation in lower environments
- Predictable blast radius

### Example

```text
live/stage/
├── backend.hcl
├── main.tf
├── rds.tf
├── s3.tf
├── cognito.tf
├── variables.tf
├── outputs.tf
└── stage.tfvars
```

---

## IAM Model (Important)

IAM responsibilities are intentionally split:

### 1. Elastic Beanstalk **Service Role** (Shared)

- Used by the EB control plane
- Manages load balancers, autoscaling, health checks
- Shared across environments

### 2. EC2 **Instance Profile** (Per Environment)

- Attached to EC2 instances
- Grants runtime permissions (S3, Cognito admin, etc.)
- Scoped per environment

This avoids privilege creep and makes environment boundaries explicit.

---

## Databases: MySQL vs Postgres

### Current State

- **MySQL** is supported to enable a stable staging/demo stack
- Used temporarily while application stacks are retooled

### Target State

- **All environments will move to Postgres**
- Postgres modules already exist to support gradual migration

### How Switching Works

The environment chooses its database by module source:

```hcl
module "db" {
  source = "../../modules/rds_mysql"  # or rds_postgres
}
```

This avoids conditional logic and keeps Terraform plans simple and readable.

---

## Security Groups

- **Elastic Beanstalk EC2 instances** use a dedicated security group
- **RDS databases** use their own security group
- Database access is restricted to **only the EB instance SG**

This ensures:

- No public DB access
- Clear, auditable network paths

---

## Running Terraform (Day-to-Day)

From an environment folder (example: `stage`):

```powershell
terraform init -reconfigure -backend-config="backend.hcl"
terraform plan -var-file="stage.tfvars"
terraform apply -var-file="stage.tfvars"
```

### Secrets

Sensitive values (like DB passwords) should be passed via environment variables:

```powershell
$env:TF_VAR_db_password = "your-secure-password"
```

They are **never** committed to source control.

---

## Documentation Philosophy

- **README.md** = orientation and usage
- **/docs** = rationale, tradeoffs, deep dives

If you are wondering *why* something exists or *why it was designed this way*, look in `/docs`.

---

## Non-Goals

This repo intentionally does **not**:

- Manage application deployments
- Manage CI/CD pipelines
- Handle data migrations
- Contain business logic

Those concerns live elsewhere by design.

---

## Final Note

This repository is designed to be:

- Boring to operate
- Predictable to change
- Easy to reason about months or years later

If something here feels explicit or repetitive, that is intentional.

