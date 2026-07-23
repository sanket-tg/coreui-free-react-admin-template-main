# ==============================================================================
# RESOURCE DISCOVERY
# Scans the current AWS environment and determines what already exists.
# Resources are only created if they are NOT found.
# ==============================================================================

# ── Check if ECR repository already exists ──
data "external" "ecr_exists" {
  program = ["bash", "-c", <<-EOF
    REPO=$(aws ecr describe-repositories \
      --repository-names "${local.ecr_repo}" \
      --region "${var.aws_region}" \
      --query 'repositories[0].repositoryUri' \
      --output text 2>/dev/null)
    if [ "$REPO" != "None" ] && [ -n "$REPO" ]; then
      echo "{\"exists\": \"true\", \"arn\": \"$(aws ecr describe-repositories --repository-names "${local.ecr_repo}" --region "${var.aws_region}" --query 'repositories[0].repositoryArn' --output text 2>/dev/null)\", \"url\": \"$REPO\"}"
    else
      echo "{\"exists\": \"false\", \"arn\": \"\", \"url\": \"\"}"
    fi
  EOF
  ]
}

# ── Check if GitHub Actions IAM role already exists ──
data "external" "iam_role_exists" {
  program = ["bash", "-c", <<-EOF
    ROLE_ARN=$(aws iam get-role \
      --role-name "${var.project_name}-${var.environment}-github-actions" \
      --query 'Role.Arn' \
      --output text 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$ROLE_ARN" ] && [ "$ROLE_ARN" != "None" ]; then
      echo "{\"exists\": \"true\", \"arn\": \"$ROLE_ARN\"}"
    else
      echo "{\"exists\": \"false\", \"arn\": \"\"}"
    fi
  EOF
  ]
}

# ── Check if OIDC provider exists ──
data "external" "oidc_exists" {
  program = ["bash", "-c", <<-EOF
    OIDC_ARN=$(aws iam list-open-id-connect-providers \
      --query "OpenIDConnectProviderList[?ends_with(Arn, 'token.actions.githubusercontent.com')].Arn | [0]" \
      --output text 2>/dev/null)
    if [ -n "$OIDC_ARN" ] && [ "$OIDC_ARN" != "None" ]; then
      echo "{\"exists\": \"true\", \"arn\": \"$OIDC_ARN\"}"
    else
      echo "{\"exists\": \"false\", \"arn\": \"\"}"
    fi
  EOF
  ]
}

# ── Check if CodeDeploy app exists (ECS blue-green) ──
data "external" "codedeploy_app_exists" {
  count = var.deploy_target == "ecs" || var.deploy_target == "ec2" ? 1 : 0
  program = ["bash", "-c", <<-EOF
    APP=$(aws deploy get-application \
      --application-name "${local.cd_app_name}" \
      --query 'application.applicationName' \
      --output text 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$APP" ] && [ "$APP" != "None" ]; then
      echo "{\"exists\": \"true\", \"name\": \"$APP\"}"
    else
      echo "{\"exists\": \"false\", \"name\": \"\"}"
    fi
  EOF
  ]
}

# ── Check if CodeDeploy deployment group exists ──
data "external" "codedeploy_dg_exists" {
  count = var.deploy_target == "ec2" ? 1 : 0
  program = ["bash", "-c", <<-EOF
    DG=$(aws deploy get-deployment-group \
      --application-name "${local.cd_app_name}" \
      --deployment-group-name "${local.cd_dg_name}" \
      --query 'deploymentGroupInfo.deploymentGroupName' \
      --output text 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$DG" ] && [ "$DG" != "None" ]; then
      echo "{\"exists\": \"true\", \"name\": \"$DG\"}"
    else
      echo "{\"exists\": \"false\", \"name\": \"\"}"
    fi
  EOF
  ]
}

# ── Check if S3 artifacts bucket exists (EC2) ──
data "external" "s3_bucket_exists" {
  count = var.deploy_target == "ec2" ? 1 : 0
  program = ["bash", "-c", <<-EOF
    BUCKET="${var.project_name}-${var.environment}-deploy-artifacts-${data.aws_caller_identity.current.account_id}"
    aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "{\"exists\": \"true\", \"name\": \"$BUCKET\"}"
    else
      echo "{\"exists\": \"false\", \"name\": \"\"}"
    fi
  EOF
  ]
}

# ==============================================================================
# LOCALS - Derived from discovery
# ==============================================================================

locals {
  ecr_exists          = data.external.ecr_exists.result.exists == "true"
  ecr_arn             = local.ecr_exists ? data.external.ecr_exists.result.arn : try(aws_ecr_repository.this[0].arn, "")
  ecr_url             = local.ecr_exists ? data.external.ecr_exists.result.url : try(aws_ecr_repository.this[0].repository_url, "")
  iam_role_exists     = data.external.iam_role_exists.result.exists == "true"
  iam_role_arn        = local.iam_role_exists ? data.external.iam_role_exists.result.arn : try(aws_iam_role.github_actions[0].arn, "")
  oidc_exists         = data.external.oidc_exists.result.exists == "true"
  codedeploy_exists   = length(data.external.codedeploy_app_exists) > 0 ? data.external.codedeploy_app_exists[0].result.exists == "true" : false
  codedeploy_dg_exists = length(data.external.codedeploy_dg_exists) > 0 ? data.external.codedeploy_dg_exists[0].result.exists == "true" : false
  s3_bucket_exists    = length(data.external.s3_bucket_exists) > 0 ? data.external.s3_bucket_exists[0].result.exists == "true" : false
}
