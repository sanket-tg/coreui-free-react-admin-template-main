# ==============================================================================
# CI/CD Pipeline - Outputs
# Smart: Returns values from existing resources or newly created ones
# ==============================================================================

output "discovery_summary" {
  description = "What was found vs what was created"
  value = {
    ecr_repository = local.ecr_exists ? "FOUND (existing)" : "CREATED"
    iam_role       = local.iam_role_exists ? "FOUND (existing)" : "CREATED"
    oidc_provider  = local.oidc_exists ? "FOUND (existing)" : "CREATED"
    codedeploy_app = local.codedeploy_exists ? "FOUND (existing)" : (var.deploy_target != "eks" ? "CREATED" : "N/A")
    s3_bucket      = local.s3_bucket_exists ? "FOUND (existing)" : (var.deploy_target == "ec2" ? "CREATED" : "N/A")
  }
}

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions (set as AWS_ROLE_ARN secret)"
  value       = local.iam_role_arn
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = local.ecr_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = local.ecr_repo
}

output "deploy_target" {
  description = "Configured deployment target"
  value       = var.deploy_target
}

output "codedeploy_app_name" {
  description = "CodeDeploy application name"
  value       = local.cd_app_name
}

output "codedeploy_deployment_group" {
  description = "CodeDeploy deployment group (EC2)"
  value       = var.deploy_target == "ec2" ? local.cd_dg_name : ""
}

output "artifacts_bucket" {
  description = "S3 bucket for deployment artifacts (EC2 only)"
  value       = var.deploy_target == "ec2" ? "${var.project_name}-${var.environment}-deploy-artifacts-${local.account_id}" : ""
}

output "sns_topic_arn" {
  description = "SNS topic ARN for pipeline notifications"
  value       = try(aws_sns_topic.pipeline_notifications[0].arn, "")
}

# ==============================================================================
# GitHub Configuration Guide
# ==============================================================================

output "github_secrets_to_set" {
  description = "Secrets to configure in GitHub (Settings → Secrets → Actions)"
  value = {
    AWS_ROLE_ARN = local.iam_role_arn
  }
}

output "github_variables_to_set" {
  description = "Variables to configure in GitHub (Settings → Variables → Actions)"
  value = {
    AWS_REGION                  = var.aws_region
    ECR_REPOSITORY              = local.ecr_repo
    DEPLOY_TARGET               = var.deploy_target
    ENABLE_SNYK                 = tostring(var.enable_snyk_scan)
    ECS_CLUSTER                 = var.deploy_target == "ecs" ? var.ecs_cluster_name : ""
    ECS_SERVICE                 = var.deploy_target == "ecs" ? var.ecs_service_name : ""
    ECS_TASK_DEFINITION         = var.deploy_target == "ecs" ? var.ecs_task_family : ""
    ECS_CONTAINER_NAME          = var.deploy_target == "ecs" ? var.ecs_container_name : ""
    ECS_DEPLOYMENT_TYPE         = var.deploy_target == "ecs" ? var.ecs_deployment_type : ""
    EKS_CLUSTER                 = var.deploy_target == "eks" ? var.eks_cluster_name : ""
    EKS_NAMESPACE               = var.deploy_target == "eks" ? var.eks_namespace : ""
    EKS_DEPLOYMENT_NAME         = var.deploy_target == "eks" ? var.eks_deployment_name : ""
    CODEDEPLOY_APPLICATION      = var.deploy_target != "eks" ? local.cd_app_name : ""
    CODEDEPLOY_DEPLOYMENT_GROUP = var.deploy_target == "ec2" ? local.cd_dg_name : ""
    ARTIFACTS_BUCKET            = var.deploy_target == "ec2" ? "${var.project_name}-${var.environment}-deploy-artifacts-${local.account_id}" : ""
  }
}
