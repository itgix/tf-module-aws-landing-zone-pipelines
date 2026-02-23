locals {
  # Naming (from variables)
  pipeline_artefacts_kms_alias = var.pipeline_artefacts_kms_alias
  shared_vars_path             = var.shared_vars_path

  deploy_role_name       = var.deploy_role_name
  codepipeline_role_name = var.codepipeline_role_name
  codebuild_role_name    = var.codebuild_role_name

  policy_name_prefix = coalesce(var.policy_name_prefix, var.project_name)

  # CodeStar Connection
  codestar_connection_arn_effective = (
    var.create_codestar_connection
    ? aws_codestarconnections_connection.source_connection[0].arn
    : var.codestar_connection_arn
  )

  # IAM Role ARNs (Shared Services account context)
  codepipeline_role_arn = "arn:aws:iam::${var.shared_services_account_id}:role/${local.codepipeline_role_name}"
  codebuild_role_arn    = "arn:aws:iam::${var.shared_services_account_id}:role/${local.codebuild_role_name}"

  # Accounts mapping
  account_ids = {
    management        = var.management_account_id
    logging_and_audit = var.logging_and_audit_account_id
    security          = var.security_account_id
    shared_services   = var.shared_services_account_id
    dev               = var.dev_account_id
    stage             = var.stage_account_id
    prod              = var.prod_account_id
  }

  # Cross-account role ARNs
  deploy_role_arns = {
    for account_key, account_id in local.account_ids :
    account_key => "arn:aws:iam::${account_id}:role/${local.deploy_role_name}"
  }

  execution_role_arns = {
    for account_key, account_id in local.account_ids :
    account_key => "arn:aws:iam::${account_id}:role/${var.execution_role_name}"
  }

  # Convenient list forms (useful for IAM policies)
  deploy_role_arn_list    = [for _, arn in local.deploy_role_arns : arn]
  execution_role_arn_list = [for _, arn in local.execution_role_arns : arn]

  # Pipelines inputs
  pipelines = {
    for pipeline_id, p in var.pipelines :
    pipeline_id => merge(
      p,
      { primary_region = coalesce(p.primary_region, var.account_primary_region) }
    )
  }

  enabled_pipelines = {
    for pipeline_id, p in local.pipelines : pipeline_id => p
    if try(p.enabled, true)
  }

  # Terraform state buckets
  tf_state_buckets = var.tf_state_buckets

  # Common tags
  tags = merge(
    {
      managedby = "terraform"
    },
    var.tags
  )
}