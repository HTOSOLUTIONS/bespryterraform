# Terraform Layout and Workflow

## Repository Structure

```
aws-iac/
├─ modules/
│  ├─ eb_api_env/        # Elastic Beanstalk app + env + SGs
│  ├─ rds_mysql/         # Temporary MySQL RDS module
│  ├─ rds_postgres/      # Long-term Postgres module
│  ├─ s3_app_bucket/     # App data bucket
│  ├─ cognito_user_pool/ # Cognito user pool + client
│
├─ live/
│  ├─ _global/           # Providers, versions, shared locals
│  ├─ stage/
│  │  ├─ backend.hcl
│  │  ├─ main.tf
│  │  ├─ rds.tf
│  │  ├─ s3.tf
│  │  ├─ cognito.tf
│  │  └─ stage.tfvars
│  └─ prod/
│     └─ ...
```

---

## Design Rules

1. **Modules are reusable, environments are not**
   - Modules never reference environment names directly
   - Environment folders wire modules together

2. **One state file per environment**
   - Prevents accidental cross-env changes

3. **Databases are swappable**
   - Change only the module source in `rds.tf`
   - No flags or conditionals

---

## Typical Workflow

```powershell
terraform init -reconfigure -backend-config="backend.hcl"
terraform plan -var-file="stage.tfvars"
terraform apply -var-file="stage.tfvars"
```

Secrets are passed via environment variables:

```powershell
$env:TF_VAR_db_password = "your-secure-password"
```

---

## Why No Conditional DB Switch

Rather than:
- One module
- Many flags
- Complex conditionals

We prefer:
- One module per database engine
- Simple `source =` changes
- Clear intent

This keeps Terraform readable and auditable.

---

## Philosophy

This repo favors:
- Clarity over cleverness
- Isolation over reuse
- ScriptOps over ClickOps

Your future self should be able to understand *why* this works in one reading.


---

## IAM Model (Elastic Beanstalk)

Elastic Beanstalk uses **two distinct IAM roles**, and confusing them is the most common source of EB failures.

### 1. Service Role (Control Plane)

**Purpose**: Allows Elastic Beanstalk itself to manage AWS resources

- Created once
- Shared across all stacks
- Passed by ARN

Examples of what it does:
- Create / manage ALBs
- Attach listeners and certificates
- Coordinate autoscaling

**This repo assumes an existing role:**

```
arn:aws:iam::891377401485:role/service-role/aws-elasticbeanstalk-service-role-bespry
```

Terraform never mutates this role.

---

### 2. EC2 Instance Profile (Runtime Identity)

**Purpose**: Permissions used *by your application code*

- One per environment
- Created by Terraform
- Attached to EC2 instances via EB

Examples:
- Cognito admin access
- S3 read/write
- CloudWatch logging

Each stack gets its own blast radius.

---

## Networking & Security Groups

### Elastic Beanstalk

- EB **will create security groups automatically** if you do nothing
- This repo **explicitly creates** the instance security group

Why?
- Deterministic IDs
- Easier RDS rules
- Auditable ingress/egress

### RDS (MySQL / Postgres)

Each DB module creates:
- Subnet group
- Security group

**Ingress rule pattern**:

- Source: EB instance security group
- Port:
  - `3306` (MySQL)
  - `5432` (Postgres)

This prevents public access entirely.

---

## Database Strategy

### Current State

- **Stage** uses MySQL for stability
- Legacy schemas remain intact

### Target State

- All environments converge on Postgres
- MySQL module eventually retired

### Why Two Modules

Terraform is clearer when intent is explicit:

```hcl
module "db" {
  source = "../../modules/rds_mysql"
}
```

vs later:

```hcl
module "db" {
  source = "../../modules/rds_postgres"
}
```

No flags. No branching logic. Clean diffs.

---

## Documentation Layout

This repo uses **layered documentation**:

- `README.md` – orientation + intent
- `docs/terraform.md` – deep Terraform details
- `docs/operations.md` – human runbooks (future)

Why not everything in README?
- READMEs should be readable in one sitting
- Details belong where you go *looking* for them

---

## Operational Guardrails (Future-You Notes)

- Never reuse Terraform state across environments
- Never attach public IPs to RDS
- Treat IAM instance roles as code
- If EB fails fast, check **instance profile first**

---

## Final Thought

This repository is designed so that:

> A tired, distracted future-you can safely deploy infrastructure without guessing.

If something feels "too implicit", make it explicit.

