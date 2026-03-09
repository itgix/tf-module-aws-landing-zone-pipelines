resource "aws_codepipeline" "lz" {
  for_each = local.enabled_pipelines

  name           = "${var.project_name}-landing-zone-${each.key}"
  role_arn       = local.codepipeline_role_arn
  pipeline_type  = "V2"
  execution_mode = var.mode


  artifact_store {
    location = module.pipeline_artefacts_bucket.primary_bucket_name
    type     = "S3"

    encryption_key {
      id   = module.kms.keys["pipeline_artefacts"].arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn    = local.codestar_connection_arn_effective
        FullRepositoryId = var.vcs_repository_id
        BranchName       = var.vcs_branch
        DetectChanges    = "true"
      }
    }
  }

  stage {
    name = "Validate"
    action {
      name            = "Validate"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.tf_validate.name
        EnvironmentVariables = jsonencode([
          { name = "PIPELINE_KEY", value = each.key, type = "PLAINTEXT" },
          { name = "TF_DIR", value = each.value.tf_dir, type = "PLAINTEXT" },
          { name = "BACKEND_FILE", value = each.value.backend_file, type = "PLAINTEXT" },
          { name = "TFVARS_FILE", value = each.value.tfvars_file, type = "PLAINTEXT" },
          { name = "SHARED_VARS", value = each.value.shared_vars, type = "PLAINTEXT" },
          { name = "TARGET_ROLE_ARN", value = each.value.target_role_arn, type = "PLAINTEXT" }
        ])
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name             = "Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["PlanArtifact"]

      configuration = {
        ProjectName   = aws_codebuild_project.tf_plan.name
        PrimarySource = "SourceArtifact"
        EnvironmentVariables = jsonencode([
          {
            name  = "ACCOUNT_ID"
            value = regex("\\d{12}", each.value.target_role_arn)
            type  = "PLAINTEXT"
          },
          {
            name  = "AWS_REGION"
            value = each.value.primary_region
            type  = "PLAINTEXT"
          },
          {
            name  = "WORKSPACE"
            value = "${each.key}-${each.value.primary_region}"
            type  = "PLAINTEXT"
          },
          {
            name  = "TF_DIR"
            value = each.value.tf_dir
            type  = "PLAINTEXT"
          },
          {
            name  = "BACKEND_FILE"
            value = each.value.backend_file
            type  = "PLAINTEXT"
          },
          {
            name  = "TFVARS_FILE"
            value = each.value.tfvars_file
            type  = "PLAINTEXT"
          },
          {
            name  = "SHARED_VARS"
            value = each.value.shared_vars
            type  = "PLAINTEXT"
          },
          {
            name  = "TF_VAR_deployment_role"
            value = each.value.target_role_arn
            type  = "PLAINTEXT"
          },
          {
            name  = "TF_VAR_region"
            value = each.value.primary_region
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "Approval"
    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Apply"

    action {
      name      = "Apply"
      category  = "Build"
      owner     = "AWS"
      provider  = "CodeBuild"
      version   = "1"
      run_order = 1

      # IMPORTANT: must include BOTH artifacts
      input_artifacts = [
        "SourceArtifact",
        "PlanArtifact"
      ]

      configuration = {
        ProjectName   = aws_codebuild_project.tf_apply.name
        PrimarySource = "SourceArtifact"

        EnvironmentVariables = jsonencode([
          {
            name  = "PIPELINE_KEY"
            value = each.key
            type  = "PLAINTEXT"
          },
          {
            name  = "ACCOUNT_ID"
            value = regex("\\d{12}", each.value.target_role_arn)
            type  = "PLAINTEXT"
          },
          {
            name  = "TF_DIR"
            value = each.value.tf_dir
            type  = "PLAINTEXT"
          },
          {
            name  = "BACKEND_FILE"
            value = each.value.backend_file
            type  = "PLAINTEXT"
          },
          {
            name  = "TFVARS_FILE"
            value = each.value.tfvars_file
            type  = "PLAINTEXT"
          },
          {
            name  = "SHARED_VARS"
            value = each.value.shared_vars
            type  = "PLAINTEXT"
          },
          {
            name  = "TF_VAR_deployment_role"
            value = each.value.target_role_arn
            type  = "PLAINTEXT"
          },
          {
            name  = "TF_VAR_region"
            value = each.value.primary_region
            type  = "PLAINTEXT"
          },

          {
            name  = "AWS_REGION"
            value = each.value.primary_region
            type  = "PLAINTEXT"
          },
          {
            name  = "AWS_DEFAULT_REGION"
            value = each.value.primary_region
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }
}