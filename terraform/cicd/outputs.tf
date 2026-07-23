# ==============================================================================
# CI/CD Pipeline - Outputs
# ==============================================================================

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions (set as AWS_ROLE_ARN secret)"
  value       = aws_iam_role.github_actions.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.this.name
}

output "deploy_target" {
  description = "Configured deployment target"
  value       = var.deploy_target
}

output "codedeploy_app_name" {
  description = "CodeDeploy application name (EC2/ECS blue-green)"
  value       = var.deploy_target == "ec2" ? try(aws_codedeploy_app.ec2[0].name, "") : try(aws_codedeploy_app.ecs[0].name, "")
}

output "codedeploy_deployment_group" {
  description = "CodeDeploy deployment group (EC2)"
  value       = var.deploy_target == "ec2" ? try(aws_codedeploy_deployment_group.ec2[0].deployment_group_name, "") : ""
}

output "artifacts_bucket" {
  description = "S3 bucket for deployment artifacts (EC2 only)"
  value       = var.deploy_target == "ec2" ? try(aws_s3_bucket.artifacts[0].bucket, "") : ""
}

output "sns_topic_arn" {
  description = "SNS topic ARN for pipeline notifications"
  value       = try(aws_sns_topic.pipeline_notifications[0].arn, "")
}

# ==============================================================================
# GitHub Repository Variables (set these in GitHub Settings > Variables)
# ==============================================================================

output "github_variables_to_set" {
  description = "Variables to configure in GitHub repository settings"
  value = {
    AWS_REGION                 = var.aws_region
    ECR_REPOSITORY             = aws_ecr_repository.this.name
    DEPLOY_TARGET              = var.deploy_target
    ECS_CLUSTER                = var.deploy_target == "ecs" ? var.ecs_cluster_name : ""
    ECS_SERVICE                = var.deploy_target == "ecs" ? var.ecs_service_name : ""
    ECS_TASK_DEFINITION        = var.deploy_target == "ecs" ? var.ecs_task_family : ""
    ECS_CONTAINER_NAME         = var.deploy_target == "ecs" ? var.ecs_container_name : ""
    EKS_CLUSTER                = var.deploy_target == "eks" ? var.eks_cluster_name : ""
    EKS_NAMESPACE              = var.deploy_target == "eks" ? var.eks_namespace : ""
    EKS_DEPLOYMENT_NAME        = var.deploy_target == "eks" ? var.eks_deployment_name : ""
    CODEDEPLOY_APPLICATION     = var.deploy_target != "eks" ? local.cd_app_name : ""
    CODEDEPLOY_DEPLOYMENT_GROUP = var.deploy_target == "ec2" ? local.cd_dg_name : ""
    ARTIFACTS_BUCKET           = var.deploy_target == "ec2" ? try(aws_s3_bucket.artifacts[0].bucket, "") : ""
  }
}

output "github_secrets_to_set" {
  description = "Secrets to configure in GitHub repository settings"
  value = {
    AWS_ROLE_ARN = aws_iam_role.github_actions.arn
  }
}
