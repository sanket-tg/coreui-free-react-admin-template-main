# CI/CD Pipeline — Terraform Module

One-shot setup for a production-ready CI/CD pipeline supporting **EC2**, **ECS**, and **EKS** deployments with full vulnerability scanning.

---

## Architecture

```
Developer → GitHub (push) → GitHub Actions
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
              Job 1: Security  Job 2: Build  Job 3: Deploy
              ├─ Gitleaks      ├─ Docker     ├─ EC2 (CodeDeploy)
              ├─ Semgrep       ├─ Push ECR   ├─ ECS (Blue-Green/Rolling)
              ├─ Snyk SCA      ├─ SBOM       └─ EKS (kubectl)
              ├─ Checkov IaC   └─ Provenance
              └─ Trivy
```

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Terraform | >= 1.5.0 |
| AWS Account | With OIDC provider for GitHub Actions already configured |
| VPC | Already provisioned |
| Cluster/Instances | ECS cluster, EKS cluster, or EC2 instances already running |
| GitHub Repo | Source code with a `Dockerfile` |

---

## Quick Start (One-Shot Setup)

### 1. Choose your deployment target

```bash
cd terraform/cicd
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Apply with the appropriate tfvars

```bash
# For ECS:
terraform apply -var-file=examples/ecs.tfvars

# For EKS:
terraform apply -var-file=examples/eks.tfvars

# For EC2:
terraform apply -var-file=examples/ec2.tfvars
```

### 4. Configure GitHub repository

After `terraform apply`, check the outputs:

```bash
terraform output github_variables_to_set
terraform output github_secrets_to_set
```

Set these in **GitHub → Settings → Secrets and Variables → Actions**.

### 5. Push to main

```bash
git add . && git commit -m "Setup CI/CD pipeline" && git push origin main
```

The pipeline will trigger automatically.

---

## Pipeline Jobs

| Job | Purpose | Runs On |
|-----|---------|---------|
| **Security & Test** | Secret detection, SAST, SCA, IaC scan, container scan | Every push & PR |
| **Build & Push** | Docker build, push to ECR with SBOM + provenance | Push to main only |
| **Deploy** | Deploy to target (EC2/ECS/EKS) | Push to main only |

---

## Security Scans

| Tool | Type | What It Catches |
|------|------|-----------------|
| **Gitleaks** | Secret Detection | API keys, tokens, passwords in code |
| **Semgrep** | SAST | Code vulnerabilities, OWASP Top 10 |
| **Snyk** | SCA | Vulnerable dependencies |
| **Checkov** | IaC Security | Terraform misconfigurations |
| **Trivy** | Container Scan | OS & library vulnerabilities in Docker image |
| **ECR Native** | Container Scan | Post-push vulnerability assessment |

---

## Variables Reference

### Required (all targets)

| Variable | Description |
|----------|-------------|
| `project_name` | Project identifier for naming |
| `deploy_target` | `ec2`, `ecs`, or `eks` |
| `github_repo` | `owner/repo` format |
| `aws_region` | AWS region |

### ECS-specific

| Variable | Description |
|----------|-------------|
| `ecs_cluster_name` | Existing ECS cluster |
| `ecs_service_name` | ECS service name |
| `ecs_task_family` | Task definition family |
| `ecs_deployment_type` | `blue-green` or `rolling` |

### EKS-specific

| Variable | Description |
|----------|-------------|
| `eks_cluster_name` | Existing EKS cluster |
| `eks_namespace` | Kubernetes namespace |
| `eks_deployment_name` | K8s Deployment resource name |

### EC2-specific

| Variable | Description |
|----------|-------------|
| `ec2_tag_filters` | Tags to identify target EC2 instances |
| `ec2_deployment_config` | CodeDeploy config name |

---

## Switching Targets

To switch from ECS to EKS (or any other target):

1. Update `deploy_target` in your `.tfvars`
2. Add the target-specific variables
3. Run `terraform apply`
4. Update GitHub variables (check `terraform output`)

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| OIDC auth fails | Verify GitHub OIDC provider exists in IAM |
| Trivy blocks pipeline | Set `vulnerability_severity_threshold` to `CRITICAL` or fix vulns |
| EKS deploy fails | Ensure IAM role is mapped in `aws-auth` ConfigMap |
| CodeDeploy timeout | Check EC2 instance CodeDeploy agent status |
| ECR push denied | Verify IAM policy includes `ecr:PutImage` |

---

## File Structure

```
terraform/cicd/
├── main.tf                    # Core resources (ECR, IAM, CodeDeploy, S3, SNS)
├── variables.tf               # All configurable inputs
├── outputs.tf                 # Outputs (role ARN, ECR URL, GitHub vars)
├── workflow.tf                # Deploys GitHub Actions workflow file
├── templates/
│   └── deploy.yaml            # GitHub Actions workflow (3 jobs)
├── examples/
│   ├── ecs.tfvars             # ECS blue-green example
│   ├── eks.tfvars             # EKS example
│   └── ec2.tfvars             # EC2 CodeDeploy example
└── README.md                  # This file
```
