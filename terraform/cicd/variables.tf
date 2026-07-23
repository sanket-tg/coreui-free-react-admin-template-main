# ==============================================================================
# CI/CD Pipeline - Terraform Variables
# Supports: EC2, ECS, EKS deployment targets
# ==============================================================================

# ------------------------------------------------------------------------------
# GENERAL
# ------------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# DEPLOYMENT TARGET
# ------------------------------------------------------------------------------

variable "deploy_target" {
  description = "Deployment target: ec2, ecs, or eks"
  type        = string
  validation {
    condition     = contains(["ec2", "ecs", "eks"], var.deploy_target)
    error_message = "deploy_target must be one of: ec2, ecs, eks."
  }
}

# ------------------------------------------------------------------------------
# GITHUB / SOURCE
# ------------------------------------------------------------------------------

variable "github_repo" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

variable "github_branch" {
  description = "Branch that triggers the pipeline"
  type        = string
  default     = "main"
}

# ------------------------------------------------------------------------------
# ECR (Container Registry)
# ------------------------------------------------------------------------------

variable "ecr_repository_name" {
  description = "ECR repository name for Docker images"
  type        = string
  default     = ""
}

variable "ecr_image_tag_mutability" {
  description = "Image tag mutability: MUTABLE or IMMUTABLE"
  type        = string
  default     = "IMMUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Enable image vulnerability scanning on push"
  type        = bool
  default     = true
}

variable "ecr_lifecycle_max_images" {
  description = "Maximum number of images to retain in ECR"
  type        = number
  default     = 30
}

# ------------------------------------------------------------------------------
# ECS SPECIFIC
# ------------------------------------------------------------------------------

variable "ecs_cluster_name" {
  description = "Existing ECS cluster name (required if deploy_target = ecs)"
  type        = string
  default     = ""
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
  default     = ""
}

variable "ecs_task_family" {
  description = "ECS task definition family name"
  type        = string
  default     = ""
}

variable "ecs_container_name" {
  description = "Container name inside the task definition"
  type        = string
  default     = "app"
}

variable "ecs_container_port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "ecs_deployment_type" {
  description = "ECS deployment type: rolling or blue-green"
  type        = string
  default     = "blue-green"
  validation {
    condition     = contains(["rolling", "blue-green"], var.ecs_deployment_type)
    error_message = "ecs_deployment_type must be rolling or blue-green."
  }
}

# ------------------------------------------------------------------------------
# EKS SPECIFIC
# ------------------------------------------------------------------------------

variable "eks_cluster_name" {
  description = "Existing EKS cluster name (required if deploy_target = eks)"
  type        = string
  default     = ""
}

variable "eks_namespace" {
  description = "Kubernetes namespace for deployment"
  type        = string
  default     = "default"
}

variable "eks_deployment_name" {
  description = "Kubernetes Deployment resource name"
  type        = string
  default     = ""
}

variable "eks_service_account" {
  description = "Kubernetes service account for IRSA"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# EC2 SPECIFIC (CodeDeploy)
# ------------------------------------------------------------------------------

variable "ec2_tag_filters" {
  description = "EC2 tag filters for CodeDeploy target group"
  type = list(object({
    key   = string
    value = string
    type  = string
  }))
  default = []
}

variable "ec2_deployment_config" {
  description = "CodeDeploy deployment configuration for EC2"
  type        = string
  default     = "CodeDeployDefault.OneAtATime"
}

variable "ec2_autoscaling_group" {
  description = "Auto Scaling group name (optional, for EC2 deploy)"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# CODEDEPLOY (shared for EC2 and ECS blue-green)
# ------------------------------------------------------------------------------

variable "codedeploy_app_name" {
  description = "CodeDeploy application name (auto-generated if empty)"
  type        = string
  default     = ""
}

variable "codedeploy_deployment_group" {
  description = "CodeDeploy deployment group name (auto-generated if empty)"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# SECURITY / SCANNING
# ------------------------------------------------------------------------------

variable "enable_trivy_scan" {
  description = "Enable Trivy container image vulnerability scanning"
  type        = bool
  default     = true
}

variable "enable_snyk_scan" {
  description = "Enable Snyk SCA (Software Composition Analysis)"
  type        = bool
  default     = true
}

variable "enable_checkov_scan" {
  description = "Enable Checkov IaC security scanning"
  type        = bool
  default     = true
}

variable "enable_gitleaks_scan" {
  description = "Enable Gitleaks secret detection"
  type        = bool
  default     = true
}

variable "vulnerability_severity_threshold" {
  description = "Fail pipeline if vulnerabilities at or above this severity (LOW, MEDIUM, HIGH, CRITICAL)"
  type        = string
  default     = "HIGH"
  validation {
    condition     = contains(["LOW", "MEDIUM", "HIGH", "CRITICAL"], var.vulnerability_severity_threshold)
    error_message = "Severity must be one of: LOW, MEDIUM, HIGH, CRITICAL."
  }
}

# ------------------------------------------------------------------------------
# NOTIFICATIONS
# ------------------------------------------------------------------------------

variable "notification_email" {
  description = "Email address for pipeline failure notifications"
  type        = string
  default     = ""
}

variable "enable_slack_notifications" {
  description = "Enable Slack notifications for pipeline events"
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "Slack webhook URL (stored in Secrets Manager)"
  type        = string
  default     = ""
  sensitive   = true
}
