# IAM and Security Model

## Two Critical IAM Concepts

Elastic Beanstalk uses **two different IAM roles**, and confusing them causes most EB failures.

### 1. Elastic Beanstalk *Service Role* (Shared)

**Purpose:**
- Used by the EB control plane
- Allows EB to create ALBs, ASGs, CloudWatch resources, etc.

**Characteristics:**
- Shared across all environments
- Rarely changes
- Managed outside individual stacks

**Example:**
- `aws-elasticbeanstalk-service-role-bespry`

Terraform passes this role **by ARN** into each EB environment.

---

### 2. EC2 *Instance Profile* (Per Environment)

**Purpose:**
- Runtime identity of the API application
- Used by the .NET API code itself

**Examples of permissions:**
- Cognito user administration
- S3 read/write
- SES email sending
- CloudWatch logging

**Characteristics:**
- One per environment
- Created by Terraform
- Safely isolated

This is where application permissions live.

---

## Security Groups

### Elastic Beanstalk EC2 Security Group

Created explicitly by Terraform and attached via EB settings.

Controls:
- Outbound access to RDS
- Future inbound rules if needed

---

### RDS Security Group

Each database module creates its own SG.

Best practice (enforced):
- Allow inbound DB traffic **only** from the EB EC2 security group
- No public access

---

## Why This Matters

This model ensures:
- Least-privilege IAM
- No shared blast radius
- Easy environment teardown
- Predictable security reviews

If something breaks, it breaks *locally*, not globally.

