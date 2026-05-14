# Interview Explanation

## Project Summary

This project demonstrates how I use Terraform and DevSecOps practices to provision secure AWS infrastructure using Infrastructure as Code.

It includes:

- AWS VPC design
- Public and private subnet separation
- Security Groups with restricted ingress and egress
- IAM roles with least privilege
- S3 security controls
- VPC Flow Logs to CloudWatch
- Terraform remote state
- GitHub Actions pipeline
- Checkov Infrastructure as Code security scanning

## Problem This Project Solves

Manual cloud infrastructure setup can lead to inconsistent configuration, weak security controls, overly permissive IAM policies, public exposure, missing logging, and lack of review before deployment.

This project solves that by using Terraform to define infrastructure consistently and Checkov to detect security misconfigurations before deployment.

## How I Explain This in an Interview

I built this Terraform AWS DevSecOps project to demonstrate secure cloud infrastructure provisioning using Infrastructure as Code. It creates a secure AWS network baseline with VPC, public and private subnets, security groups, IAM roles, S3 security controls, VPC Flow Logs, and Terraform remote state.

I also integrated GitHub Actions with Checkov so every push and pull request runs Terraform validation and Infrastructure as Code security scanning before changes are reviewed or deployed.

The main goal is to show how security can be shifted left into the infrastructure delivery process.

## Production Improvements

For production, I would add:

- NAT Gateway per Availability Zone
- VPC endpoints
- AWS KMS customer-managed keys
- GuardDuty
- Security Hub
- AWS Config
- CloudWatch alarms
- Centralized logging
- Manual approval before Terraform apply
- Separate dev, staging, and production environments