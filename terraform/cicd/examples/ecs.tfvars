# ==============================================================================
# Example: ECS Fargate Blue-Green Deployment
# ==============================================================================

project_name = "myapp"
environment  = "prod"
aws_region   = "ap-south-1"

deploy_target = "ecs"

# GitHub
github_repo   = "your-org/your-repo"
github_branch = "main"

# ECR
ecr_repository_name      = "myapp-prod"
ecr_image_tag_mutability = "IMMUTABLE"
ecr_scan_on_push         = true
ecr_lifecycle_max_images = 30

# ECS
ecs_cluster_name    = "my-existing-cluster"
ecs_service_name    = "myapp-service"
ecs_task_family     = "myapp-task"
ecs_container_name  = "app"
ecs_container_port  = 8080
ecs_deployment_type = "blue-green"

# Security Scanning
enable_trivy_scan                = true
enable_snyk_scan                 = true
enable_checkov_scan              = true
enable_gitleaks_scan             = true
vulnerability_severity_threshold = "HIGH"

# Notifications
notification_email = "devops@example.com"

tags = {
  Team    = "platform"
  Project = "myapp"
}
