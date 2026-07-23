# ==============================================================================
# CI/CD Pipeline - Main Terraform Configuration
# Dynamic deployment: EC2 / ECS / EKS
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = merge(var.tags, {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Pipeline    = "cicd"
    })
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  partition    = data.aws_partition.current.partition
  ecr_repo     = var.ecr_repository_name != "" ? var.ecr_repository_name : "${var.project_name}-${var.environment}"
  cd_app_name  = var.codedeploy_app_name != "" ? var.codedeploy_app_name : "${var.project_name}-${var.environment}-app"
  cd_dg_name   = var.codedeploy_deployment_group != "" ? var.codedeploy_deployment_group : "${var.project_name}-${var.environment}-dg"
}

# ==============================================================================
# ECR REPOSITORY
# ==============================================================================

resource "aws_ecr_repository" "this" {
  name                 = local.ecr_repo
  image_tag_mutability = var.ecr_image_tag_mutability
  force_delete         = var.environment != "prod"

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.ecr_lifecycle_max_images} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_lifecycle_max_images
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ==============================================================================
# IAM - GITHUB ACTIONS OIDC
# ==============================================================================

data "aws_iam_openid_connect_provider" "github" {
  count = 1
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:${local.partition}:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# IAM Policy - ECR Access (push/pull)
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "ecr_access" {
  name = "ecr-access"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
        Resource = aws_ecr_repository.this.arn
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# IAM Policy - ECS Deploy (conditional)
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "ecs_deploy" {
  count = var.deploy_target == "ecs" ? 1 : 0
  name  = "ecs-deploy"
  role  = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECSTaskDefinition"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECSService"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ecs:cluster" = "arn:${local.partition}:ecs:${var.aws_region}:${local.account_id}:cluster/${var.ecs_cluster_name}"
          }
        }
      },
      {
        Sid    = "PassRole"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringLike = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# IAM Policy - EKS Deploy (conditional)
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "eks_deploy" {
  count = var.deploy_target == "eks" ? 1 : 0
  name  = "eks-deploy"
  role  = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "arn:${local.partition}:eks:${var.aws_region}:${local.account_id}:cluster/${var.eks_cluster_name}"
      },
      {
        Sid    = "STSGetCallerIdentity"
        Effect = "Allow"
        Action = "sts:GetCallerIdentity"
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# IAM Policy - EC2 CodeDeploy (conditional)
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "ec2_deploy" {
  count = var.deploy_target == "ec2" ? 1 : 0
  name  = "ec2-codedeploy"
  role  = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CodeDeployAccess"
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetApplicationRevision",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetApplication",
          "codedeploy:ListDeployments"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3ArtifactAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.artifacts[0].arn,
          "${aws_s3_bucket.artifacts[0].arn}/*"
        ]
      }
    ]
  })
}

# ==============================================================================
# S3 BUCKET - Artifacts (EC2 CodeDeploy)
# ==============================================================================

resource "aws_s3_bucket" "artifacts" {
  count         = var.deploy_target == "ec2" ? 1 : 0
  bucket        = "${var.project_name}-${var.environment}-deploy-artifacts-${local.account_id}"
  force_destroy = var.environment != "prod"
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count  = var.deploy_target == "ec2" ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count  = var.deploy_target == "ec2" ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  count                   = var.deploy_target == "ec2" ? 1 : 0
  bucket                  = aws_s3_bucket.artifacts[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==============================================================================
# CODEDEPLOY - EC2
# ==============================================================================

resource "aws_codedeploy_app" "ec2" {
  count            = var.deploy_target == "ec2" ? 1 : 0
  name             = local.cd_app_name
  compute_platform = "Server"
}

resource "aws_iam_role" "codedeploy_ec2" {
  count = var.deploy_target == "ec2" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "codedeploy.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_ec2" {
  count      = var.deploy_target == "ec2" ? 1 : 0
  role       = aws_iam_role.codedeploy_ec2[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_codedeploy_deployment_group" "ec2" {
  count                  = var.deploy_target == "ec2" ? 1 : 0
  app_name               = aws_codedeploy_app.ec2[0].name
  deployment_group_name  = local.cd_dg_name
  service_role_arn       = aws_iam_role.codedeploy_ec2[0].arn
  deployment_config_name = var.ec2_deployment_config

  dynamic "ec2_tag_filter" {
    for_each = var.ec2_tag_filters
    content {
      key   = ec2_tag_filter.value.key
      value = ec2_tag_filter.value.value
      type  = ec2_tag_filter.value.type
    }
  }

  dynamic "auto_rollback_configuration" {
    for_each = [1]
    content {
      enabled = true
      events  = ["DEPLOYMENT_FAILURE"]
    }
  }
}

# ==============================================================================
# CODEDEPLOY - ECS Blue-Green
# ==============================================================================

resource "aws_codedeploy_app" "ecs" {
  count            = var.deploy_target == "ecs" && var.ecs_deployment_type == "blue-green" ? 1 : 0
  name             = local.cd_app_name
  compute_platform = "ECS"
}

# ==============================================================================
# SNS - Pipeline Notifications
# ==============================================================================

resource "aws_sns_topic" "pipeline_notifications" {
  count = var.notification_email != "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-pipeline-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.pipeline_notifications[0].arn
  protocol  = "email"
  endpoint  = var.notification_email
}
