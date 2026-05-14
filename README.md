# terraform-aws-devsecops

Infrastructure as Code (IaC) project deploying a secure AWS DevSecOps lab environment following production-ready design principles using Terraform — with automated security scanning via Checkov integrated into the CI pipeline.

![Terraform Security Pipeline](https://github.com/TengkuRizal/terraform-aws-devsecops/actions/workflows/terraform-security.yml/badge.svg)
![Checkov](https://img.shields.io/badge/Checkov-61%20passed%2C%200%20failed-brightgreen)
![Terraform](https://img.shields.io/badge/Terraform-v1.8.5-7B42BC?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-ap--southeast--1-FF9900?logo=amazonaws)

---

## Overview

This project provisions a secure AWS network infrastructure following DevSecOps principles — security is enforced **before** deployment, not after. Security validation is automated through GitHub Actions, where Terraform formatting, validation, and Checkov IaC scanning run on every push and pull request before infrastructure changes are reviewed or deployed.

This is part of a broader homelab DevSecOps portfolio that includes:

- GitLab CI/CD pipeline with security gates such as Gitleaks, Semgrep, Trivy, and Kubernetes deployment
- Wazuh SIEM with active threat detection and MITRE ATT&CK mapping
- Security Onion for network traffic analysis using Zeek
- Shuffle SOAR for automated incident response workflows
- 3-node Kubernetes cluster with runtime security monitoring

---

## Architecture

<pre>
ap-southeast-1 (Singapore)
│
├── VPC: 10.0.0.0/16
│   ├── Public Subnets (x2, multi-AZ)
│   │   ├── 10.0.0.0/24  (ap-southeast-1a)
│   │   └── 10.0.1.0/24  (ap-southeast-1b)
│   ├── Private Subnets (x2, multi-AZ)
│   │   ├── 10.0.10.0/24 (ap-southeast-1a)
│   │   └── 10.0.11.0/24 (ap-southeast-1b)
│   ├── Internet Gateway
│   ├── Route Tables (public only routes to IGW)
│   └── VPC Flow Logs → CloudWatch (7-day retention)
│
├── Security Groups
│   ├── Bastion SG : SSH from admin IP only, HTTPS/HTTP egress only
│   └── App SG     : HTTP from Bastion SG only, HTTPS egress only
│
├── S3 Bucket
│   ├── AES-256 encryption at rest
│   ├── Versioning enabled
│   ├── Access logging enabled
│   ├── Block all public access
│   └── Lifecycle: expire at 90 days, abort incomplete uploads at 7 days
│
├── IAM
│   ├── EC2 role      : S3 read-only, scoped to specific bucket ARN
│   └── Flow Log role : CloudWatch write, scoped to specific log group ARN
│
└── Terraform State
    ├── S3 backend : encrypted + versioned
    └── State lock : S3 native lockfile (Terraform v1.10+)
</pre>

---

## Security Design Decisions

### Why no NAT Gateway?

NAT Gateway costs around USD 32/month minimum before data processing charges. Private subnets in this lab design do not require internet egress. In production, NAT Gateways would normally be deployed per Availability Zone for high availability and controlled outbound access.

### Why AES-256 instead of KMS?

KMS customer-managed keys introduce additional monthly and API request costs. AES-256 using SSE-S3 provides encryption at rest with no extra key-management cost. For regulated environments such as PCI-DSS or HIPAA, KMS with key rotation and stricter access control would be recommended.

### Why restrict Security Group egress?

Allowing all outbound traffic to `0.0.0.0/0` increases the risk of data exfiltration if an instance is compromised. Restricting egress to required ports such as 80 and 443 reduces the blast radius.

### Why scope IAM policies to specific ARNs?

Wildcard resources violate least privilege and can increase privilege escalation risk. The Flow Log role can only write to its specific CloudWatch log group, not every log group in the account.

### Why restrict the default VPC security group?

AWS creates a default security group that allows inbound traffic from itself. Any EC2 instance launched without explicit security group assignment can fall back to this default. Restricting the default security group helps close that gap.

---

## Checkov Results

Passed checks: **61**  
Failed checks: **0**  
Skipped checks: **0**

Intentionally skipped with justification:

| Check | Reason |
| --- | --- |
| CKV_AWS_338 | Log retention less than 1 year due to free-tier cost constraint |
| CKV_AWS_158 | CloudWatch KMS encryption skipped due to cost constraint for non-regulated homelab |
| CKV_AWS_145 | S3 KMS skipped because SSE-S3 AES-256 provides encryption at rest for this lab |
| CKV2_AWS_5 | Security groups are not attached to EC2 because this module currently does not deploy EC2 instances |
| CKV2_AWS_62 | S3 event notifications are not required for this use case |

---

## CI/CD Security Pipeline

This repository includes a GitHub Actions workflow that runs on every push and pull request to the `main` branch.

Pipeline stages:

```text
Checkout Repository
↓
Setup Terraform
↓
Terraform fmt -check
↓
Terraform init -backend=false
↓
Terraform validate
↓
Checkov IaC Security Scan
```

The purpose of this pipeline is to detect Terraform formatting issues, validation errors, and infrastructure security misconfigurations before deployment.

---

## Project Structure

```text
terraform-aws-devsecops/
├── .github/
│   └── workflows/
│       └── terraform-security.yml
├── .checkov.yaml
├── .gitignore
├── README.md
├── docs/
│   └── production-readiness.md
├── environments/
│   └── dev/
│       ├── backend.tf
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── modules/
    ├── iam/
    ├── s3/
    ├── security_groups/
    └── vpc/
```

---

## Production Readiness

This project is designed as a cost-conscious DevSecOps lab. For production use, additional controls such as NAT Gateway, VPC endpoints, KMS CMK, GuardDuty, Security Hub, AWS Config, centralized logging, and approval gates should be implemented.

See: [Production Readiness Review](docs/production-readiness.md)

---

## How to Deploy

```bash
# 1. Scan first
checkov -d . --framework terraform

# 2. Deploy
cd environments/dev
terraform init
terraform plan
terraform apply

# 3. Destroy when done for cost control
terraform destroy
```

---

## Key Concepts Demonstrated

- Modular Terraform structure with reusable modules
- Remote state with S3 backend and native state locking
- Default tags applied to all resources through provider configuration
- Dynamic Availability Zone discovery using Terraform data sources
- Least privilege IAM using ARN-scoped policies
- Public and private subnet separation across multiple Availability Zones
- VPC Flow Logs integration with CloudWatch
- Secure S3 configuration with encryption, versioning, lifecycle rules, logging, and public access block
- IaC security scanning with Checkov
- GitHub Actions pipeline for Terraform validation and security scanning
- Cost-conscious lab design with documented production trade-offs

---

## Interview Talking Points

This project demonstrates how I approach cloud infrastructure from a DevSecOps perspective:

- Use Terraform to define repeatable AWS infrastructure
- Apply security controls early through Infrastructure as Code scanning
- Design networks with public and private subnet separation
- Restrict IAM and security group access using least privilege
- Enable logging and visibility through VPC Flow Logs and CloudWatch
- Document lab-to-production trade-offs clearly
- Use CI/CD to validate infrastructure changes before deployment

Example explanation:

> I built this Terraform AWS DevSecOps project to demonstrate secure cloud infrastructure provisioning. It creates a VPC with public and private subnets, security groups, IAM roles, S3 security controls, VPC Flow Logs, and Terraform remote state. I also integrated Checkov with GitHub Actions so every push and pull request is checked for Terraform formatting, validation, and IaC security misconfiguration before infrastructure changes are reviewed or deployed.

---

## Future Improvements

- Add Terraform plan output as a GitHub Actions artifact
- Add manual approval before `terraform apply`
- Add separate environments for dev, staging, and production
- Add VPC endpoints for private AWS service access
- Add NAT Gateway per Availability Zone for production-grade outbound access
- Add AWS GuardDuty, Security Hub, and AWS Config
- Add CloudWatch alarms and dashboards
- Add AWS WAF and Application Load Balancer for public-facing workloads
- Add EKS or ECS workload deployment layer
- Add policy-as-code enforcement using OPA or Conftest

---

## Author

**Tengku Rizal** — DevSecOps Engineer  
Building: GitLab CI/CD · Kubernetes · Wazuh SIEM · Terraform · Security Automation  
Location: Kuala Lumpur, Malaysia
