# terraform-aws-devsecops

Infrastructure as Code (IaC) project deploying a secure, production-grade AWS environment using Terraform — with automated security scanning via Checkov integrated into the pipeline.

![Terraform Security Pipeline](https://github.com/TengkuRizal/terraform-aws-devsecops/actions/workflows/terraform-security.yml/badge.svg)
![Checkov](https://img.shields.io/badge/Checkov-61%20passed%2C%200%20failed-brightgreen)
![Terraform](https://img.shields.io/badge/Terraform-v1.15.2-7B42BC?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-ap--southeast--1-FF9900?logo=amazonaws)

---

## Overview

This project provisions a secure AWS network infrastructure following DevSecOps principles — security is enforced **before** deployment, not after. Every `terraform apply` is preceded by a Checkov IaC security scan that must pass 0 critical findings before infrastructure is deployed.

This is part of a broader homelab DevSecOps portfolio that includes:
- GitLab CI/CD pipeline with 4-stage security gates (Gitleaks → Semgrep → Trivy → Deploy)
- Wazuh SIEM with active threat detection and MITRE ATT&CK mapping
- Security Onion for network traffic analysis via Zeek
- Shuffle SOAR for automated incident response
- 3-node Kubernetes cluster with runtime security monitoring

---

## Architecture

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
│   ├── EC2 role     : S3 read-only (scoped to specific bucket ARN)
│   └── Flow Log role: CloudWatch write (scoped to specific log group ARN)
│
└── Terraform State
    ├── S3 backend : encrypted + versioned
    └── State lock : S3 native lockfile (Terraform v1.10+)


---

## Security Design Decisions

**Why no NAT Gateway?**
NAT Gateway costs ~$32/month minimum. Private subnets in this project do not require internet egress. In production, NAT Gateways would be deployed per AZ for high availability.

**Why AES-256 instead of KMS?**
KMS custom keys cost $1/month per key plus API charges. AES-256 (SSE-S3) provides encryption at rest at zero cost. For regulated environments (PCI-DSS, HIPAA), KMS with envelope encryption would be required.

**Why restrict Security Group egress?**
Allowing all outbound (`0.0.0.0/0`) enables data exfiltration if an instance is compromised. Restricting egress to ports 80 and 443 limits blast radius of a compromise.

**Why scope IAM policies to specific ARNs?**
Wildcard resources violate least privilege and enable privilege escalation. The Flow Log role can only write to its specific CloudWatch log group — not any log group in the account.

**Why restrict the default VPC security group?**
AWS creates a default SG that allows all inbound traffic from itself. Any EC2 instance launched without explicit SG assignment falls back to this default. Restricting it to zero rules closes this gap.

---

## Checkov Results
Passed checks: 61   Failed checks: 0   Skipped checks: 0

Intentionally skipped (with justification):

| Check | Reason |
|---|---|
| CKV_AWS_338 | Log retention < 1 year — free tier cost constraint |
| CKV_AWS_158 | CloudWatch KMS — cost constraint, acceptable for non-regulated homelab |
| CKV_AWS_145 | S3 KMS — AES-256 provides encryption at rest |
| CKV2_AWS_5  | SGs not attached to EC2 — by design, no EC2 in this module |
| CKV2_AWS_62 | S3 event notifications — not required for this use case |

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
# 1. Scan first — must pass before deploy
checkov -d . --framework terraform

# 2. Deploy
cd environments/dev
terraform init
terraform plan
terraform apply

# 3. Destroy when done (free tier protection)
terraform destroy
```

---

## Key Concepts Demonstrated

- Modular Terraform structure with reusable modules
- Remote state with S3 backend and native state locking
- Default tags applied to all resources via provider block
- Dynamic AZ discovery using data sources
- Least privilege IAM with ARN-scoped policies
- IaC security scanning with Checkov before every deploy

---

## Author

**Tengku Rizal** — DevSecOps Engineer  
Building: GitLab CI/CD · Kubernetes · Wazuh SIEM · Terraform · Security Automation  
Location: Kuala Lumpur, Malaysia
