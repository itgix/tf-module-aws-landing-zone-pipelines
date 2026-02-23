# CodePipeline role
module "codepipeline_role" {
  source  = "git::https://github.com/itgix/tf-module-aws-iam-role.git?ref=v1.1"
  enabled = true

  role_name = var.codepipeline_role_name

  principals = {
    Service = ["codepipeline.amazonaws.com"]
  }

  iam_policies = {
    codepipeline = {
      name = "${local.policy_name_prefix}_CodePipeline"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          # S3 artifacts access
          {
            Sid    = "ArtifactsBucketAccess"
            Effect = "Allow"
            Action = [
              "s3:PutObject",
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:DeleteObject",
              "s3:ListBucket",
              "s3:GetBucketLocation"
            ]
            Resource = [
              "arn:aws:s3:::${module.pipeline_artefacts_bucket.primary_bucket_name}",
              "arn:aws:s3:::${module.pipeline_artefacts_bucket.primary_bucket_name}/*"
            ]
          },

          # KMS for artifacts
          {
            Sid    = "ArtifactsKMSUsage"
            Effect = "Allow"
            Action = [
              "kms:Decrypt",
              "kms:Encrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ]
            Resource = [
              module.kms.keys["pipeline_artefacts"].arn
            ]
          },

          # Trigger CodeBuild
          {
            Sid    = "TriggerCodeBuild"
            Effect = "Allow"
            Action = [
              "codebuild:StartBuild",
              "codebuild:BatchGetBuilds"
            ]
            Resource = ["*"]
          },

          # Use CodeStar connection
          {
            Sid      = "UseCodeStarConnection"
            Effect   = "Allow"
            Action   = ["codestar-connections:UseConnection"]
            Resource = [local.codestar_connection_arn_effective]
          },

          # Pass CodeBuild role to CodeBuild service
          {
            Sid      = "PassCodeBuildRole"
            Effect   = "Allow"
            Action   = ["iam:PassRole"]
            Resource = ["arn:aws:iam::${var.shared_services_account_id}:role/${var.codebuild_role_name}"]
            Condition = {
              StringEquals = {
                "iam:PassedToService" = "codebuild.amazonaws.com"
              }
            }
          }
        ]
      })
    }
  }
}

# CodeBuild role
module "codebuild_role" {
  source  = "git::https://github.com/itgix/tf-module-aws-iam-role.git?ref=v1.1"
  enabled = true

  role_name = var.codebuild_role_name

  principals = {
    Service = ["codebuild.amazonaws.com"]
  }

  iam_policies = {
    # Base permissions (logs + sts assume roles)
    codebuild_base = {
      name = "${local.policy_name_prefix}_CodeBuild_Base"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = concat(
          [
            # CloudWatch Logs for CodeBuild
            {
              Sid    = "CodeBuildLogs"
              Effect = "Allow"
              Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
              ]
              Resource = "*"
            }
          ],

          # Optional: allow assuming pivot deploy role in all accounts
            var.allow_assume_deploy_role ? [
            {
              Sid    = "AssumeDeployRole"
              Effect = "Allow"
              Action = ["sts:AssumeRole"]
              Resource = local.deploy_role_arn_list
            }
          ] : [],

          # Optional: allow assuming execution role in all accounts
            var.allow_assume_execution_role ? [
            {
              Sid    = "AssumeExecutionRole"
              Effect = "Allow"
              Action = ["sts:AssumeRole"]
              Resource = local.execution_role_arn_list
            }
          ] : []
        )
      })
    }
    # Artifacts bucket access + KMS
    codebuild_artifacts = {
      name = "${local.policy_name_prefix}_CodeBuild_Artifacts"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "ArtifactsBucketList"
            Effect = "Allow"
            Action = [
              "s3:ListBucket",
              "s3:GetBucketLocation"
            ]
            Resource = [
              "arn:aws:s3:::${module.pipeline_artefacts_bucket.primary_bucket_name}"
            ]
          },
          {
            Sid    = "ArtifactsObjectRW"
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:PutObject",
              "s3:DeleteObject"
            ]
            Resource = [
              "arn:aws:s3:::${module.pipeline_artefacts_bucket.primary_bucket_name}/*"
            ]
          },
          {
            Sid    = "ArtifactsKMSUsage"
            Effect = "Allow"
            Action = [
              "kms:Decrypt",
              "kms:Encrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ]
            Resource = [
              module.kms.keys["pipeline_artefacts"].arn
            ]
          }
        ]
      })
    }
    # Terraform state buckets access
    codebuild_tf_state = {
      name = "${local.policy_name_prefix}_CodeBuild_TF_State"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "TFStateBucketList"
            Effect = "Allow"
            Action = [
              "s3:ListBucket",
              "s3:GetBucketLocation"
            ]
            Resource = [
              for b in var.tf_state_buckets : "arn:aws:s3:::${b}"
            ]
          },
          {
            Sid    = "TFStateObjectRW"
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:PutObject",
              "s3:DeleteObject"
            ]
            Resource = [
              for b in var.tf_state_buckets : "arn:aws:s3:::${b}/*"
            ]
          }
        ]
      })
    }
  }
}