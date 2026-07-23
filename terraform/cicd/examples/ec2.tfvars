# ==============================================================================
# Example: EC2 CodeDeploy Deployment
# ==============================================================================

project_name = "myapp"
environment  = "prod"
aws_region   = "ap-south-1"

deploy_target = "ec2"

# GitHub
github_repo   = "your-org/your-repo"
github_branch = "main"

# ECR (still used for building/scanning the image)
ecr_repository_name      = "myapp-prod"
ecr_image_tag_mutability = "IMMUTABLE"
ecr_scan_on_push         = true
ecr_lifecycle_max_images = 30

# EC2 / CodeDeploy
ec2_deployment_config = "CodeDeployDefault.OneAtATime"
ec2_autoscaling_group = "myapp-asg"

ec2_tag_filters = [
  {
    key   = "Name"
    value = "myapp-prod"
    type  = "KEY_AND_VALUE"
  },
  {
    key   = "Environment"
    value = "prod"
    type  = "KEY_AND_VALUE"
  }
]

# Security Scanning
enable_trivy_scan                = true
enable_snyk_scan                 = false
enable_checkov_scan              = true
enable_gitleaks_scan             = true
vulnerability_severity_threshold = "HIGH"

# Notifications
notification_email = "devops@example.com"

tags = {
  Team    = "platform"
  Project = "myapp"
}
