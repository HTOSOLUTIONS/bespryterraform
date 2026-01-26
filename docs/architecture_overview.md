# Architecture Overview

## Purpose
This document explains the *why* behind the current AWS architecture for BeSpry’s infrastructure-as-code (IaC) repository. It is intentionally narrative and decision-focused rather than a Terraform walkthrough.

This repo is designed to support:
- Multiple isolated environments (stage, prod, future dev)
- Predictable, repeatable infrastructure via Terraform
- A gradual transition from legacy patterns to a clean, modern stack

---

## High-Level Architecture

Each environment (e.g. `stage`, `prod`) is a **self-contained stack** that includes:

- Elastic Beanstalk application + environment (API)
- Application Load Balancer (managed by EB)
- EC2 instances (managed by EB Auto Scaling)
- Dedicated IAM *instance profile* for runtime permissions
- Optional database (MySQL today, Postgres long-term)
- Application S3 bucket
- Cognito User Pool
- Route53 DNS + ACM certificates

The only *shared* infrastructure across environments is:
- Terraform remote state bucket
- Terraform DynamoDB lock table
- Elastic Beanstalk **service role**

---

## Environment Isolation Model

Each environment:
- Has its own Elastic Beanstalk **environment**
- Has its own EC2 **instance profile**
- Has its own **security groups**
- Can choose its own database engine

This ensures:
- Stage can break without impacting prod
- IAM permissions are minimized per environment
- Databases can evolve independently

---

## Why Elastic Beanstalk (for now)

Elastic Beanstalk is intentionally used as a *control plane*:
- Handles ALB provisioning
- Handles Auto Scaling Groups
- Handles EC2 lifecycle

Terraform is used to:
- Define EB configuration declaratively
- Control IAM, networking, and security explicitly
- Avoid ClickOps drift

This gives us most of the benefits of ECS/EKS *without* the operational overhead at the current scale.

---

## Future Direction

This architecture is designed to evolve toward:
- Postgres-only databases
- Potential ECS migration if/when scale demands it
- Tighter network controls (private subnets, NAT)

All current decisions are reversible without large rewrites.

