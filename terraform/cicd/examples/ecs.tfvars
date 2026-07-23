# ==============================================================================
# ECS Fargate Blue-Green Deployment
# Project: coreui-react-admin
# ==============================================================================

project_name = "myapp"
environment  = "dev"
aws_region   = "us-east-1"

deploy_target = "ecs"

# GitHub
github_repo   = "sanket-tg/coreui-free-react-admin-template-main"
github_branch = "main"

# ECR
ecr_repository_name      = "ecs-demo"
ecr_image_tag_mutability = "IMMUTABLE"
ecr_scan_on_push         = true
ecr_lifecycle_max_images = 30

# ECS
ecs_cluster_name    = "myapp-dev-cluster"
ecs_service_name    = "myapp-dev-service"
ecs_task_family     = "myapp-dev-task"
ecs_container_name  = "ecs-demo"
ecs_container_port  = 8080
ecs_deployment_type = "blue-green"

# CodeDeploy
codedeploy_app_name         = "myapp-dev-app"
codedeploy_deployment_group = "myapp-dev-dg"

# Security Scanning
enable_trivy_scan                = true
enable_snyk_scan                 = true
enable_checkov_scan              = true
enable_gitleaks_scan             = true
vulnerability_severity_threshold = "HIGH"

# Notifications
notification_email = ""

tags = {
  Team        = "platform"
  Project     = "myapp"
  Environment = "dev"
}
