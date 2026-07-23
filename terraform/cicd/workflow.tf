# ==============================================================================
# GitHub Actions Workflow - Deploy via Terraform local_file
# Copies the workflow template to .github/workflows/
# ==============================================================================

resource "local_file" "github_workflow" {
  content  = file("${path.module}/templates/deploy.yaml")
  filename = "${path.module}/../../.github/workflows/deploy.yaml"

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# GitHub Repository Variables Setup Guide
# After terraform apply, set these in GitHub → Settings → Secrets and Variables
# ==============================================================================

resource "local_file" "github_vars_guide" {
  filename = "${path.module}/../../.github/PIPELINE_SETUP.md"
  content  = <<-EOT
# Pipeline Setup - GitHub Configuration

## Secrets (Settings → Secrets → Actions)

| Secret | Value |
|--------|-------|
| `AWS_ROLE_ARN` | `${local.iam_role_arn}` |
| `SNYK_TOKEN` | *(from snyk.io dashboard, optional)* |

## Variables (Settings → Variables → Actions)

| Variable | Value |
|----------|-------|
| `AWS_REGION` | `${var.aws_region}` |
| `ECR_REPOSITORY` | `${local.ecr_repo}` |
| `DEPLOY_TARGET` | `${var.deploy_target}` |
| `ENABLE_SNYK` | `${var.enable_snyk_scan}` |
%{if var.deploy_target == "ecs"~}
| `ECS_CLUSTER` | `${var.ecs_cluster_name}` |
| `ECS_SERVICE` | `${var.ecs_service_name}` |
| `ECS_TASK_DEFINITION` | `${var.ecs_task_family}` |
| `ECS_CONTAINER_NAME` | `${var.ecs_container_name}` |
| `ECS_DEPLOYMENT_TYPE` | `${var.ecs_deployment_type}` |
| `CODEDEPLOY_APPLICATION` | `${local.cd_app_name}` |
| `CODEDEPLOY_DEPLOYMENT_GROUP` | `${local.cd_dg_name}` |
%{endif~}
%{if var.deploy_target == "eks"~}
| `EKS_CLUSTER` | `${var.eks_cluster_name}` |
| `EKS_NAMESPACE` | `${var.eks_namespace}` |
| `EKS_DEPLOYMENT_NAME` | `${var.eks_deployment_name}` |
%{endif~}
%{if var.deploy_target == "ec2"~}
| `CODEDEPLOY_APPLICATION` | `${local.cd_app_name}` |
| `CODEDEPLOY_DEPLOYMENT_GROUP` | `${local.cd_dg_name}` |
| `ARTIFACTS_BUCKET` | `${var.project_name}-${var.environment}-deploy-artifacts-${local.account_id}` |
%{endif~}

## Pipeline Trigger
Push to `${var.github_branch}` branch or use **Actions → Run workflow** for manual dispatch.
EOT
}
