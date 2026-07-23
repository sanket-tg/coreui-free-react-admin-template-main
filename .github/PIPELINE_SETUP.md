# Pipeline Setup - GitHub Configuration

## Secrets (Settings → Secrets → Actions)

| Secret | Value |
|--------|-------|
| `AWS_ROLE_ARN` | `arn:aws:iam::573723531348:role/myapp-dev-github-actions` |
| `SNYK_TOKEN` | *(from snyk.io dashboard, optional)* |

## Variables (Settings → Variables → Actions)

| Variable | Value |
|----------|-------|
| `AWS_REGION` | `us-east-1` |
| `ECR_REPOSITORY` | `ecs-demo` |
| `DEPLOY_TARGET` | `ecs` |
| `ENABLE_SNYK` | `true` |
| `ECS_CLUSTER` | `myapp-dev-cluster` |
| `ECS_SERVICE` | `myapp-dev-service` |
| `ECS_TASK_DEFINITION` | `myapp-dev-task` |
| `ECS_CONTAINER_NAME` | `ecs-demo` |
| `ECS_DEPLOYMENT_TYPE` | `blue-green` |
| `CODEDEPLOY_APPLICATION` | `myapp-dev-app` |
| `CODEDEPLOY_DEPLOYMENT_GROUP` | `myapp-dev-dg` |

## Pipeline Trigger
Push to `main` branch or use **Actions → Run workflow** for manual dispatch.
