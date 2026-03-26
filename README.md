The Terraform module is used by the ITGix AWS Landing Zone - https://itgix.com/itgix-landing-zone/

# AWS Landing Zone Pipelines Terraform Module

This module creates CI/CD pipelines using AWS CodePipeline and CodeBuild for deploying Terraform-based landing zone configurations across multiple AWS accounts.

Part of the [ITGix AWS Landing Zone](https://itgix.com/itgix-landing-zone/).

## Resources Created

- AWS CodePipeline pipelines
- AWS CodeBuild projects
- CodeConnections host and connection (for Git providers)
- KMS key for pipeline artifact encryption
- S3 bucket for pipeline artifacts
- IAM roles and policies for CodePipeline and CodeBuild

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `codestar_provider_type` | Source repository provider (GitLabSelfManaged, GitLab, GitHub, Bitbucket, GitHubEnterpriseServer) | `string` | `"GitLabSelfManaged"` | no |
| `create_codestar_host` | Whether to create a CodeConnections host | `bool` | `true` | no |
| `create_codestar_connection` | Whether to create a CodeConnections connection | `bool` | `true` | no |
| `codestar_connection_arn` | Existing CodeConnections connection ARN (when create_codestar_connection is false) | `string` | `null` | no |
| `codestar_host_name` | Host name for CodeConnections host | `string` | `null` | no |
| `codestar_provider_endpoint` | Endpoint URL for self-managed providers | `string` | `null` | no |
| `codestar_connection_name` | Name of the CodeConnections connection | `string` | `null` | no |
| `vcs_repository_id` | Repository identifier (e.g. `<group>/<repo>`) | `string` | — | yes |
| `vcs_branch` | Branch to track | `string` | `"main"` | no |
| `tags` | Additional tags for resources | `map(string)` | `{}` | no |
| `project_name` | Base project identifier for resource naming | `string` | `"itgix"` | no |
| `policy_name_prefix` | Optional prefix for IAM policy names | `string` | `null` | no |
| `account_primary_region` | Primary AWS region for the account | `string` | `"eu-central-1"` | no |
| `replica_region` | Secondary AWS region for cross-region replication | `string` | `""` | no |
| `pipelines_management_profile` | Optional AWS CLI profile | `string` | `""` | no |
| `management_account_id` | AWS account ID for the management account | `string` | — | yes |
| `logging_and_audit_account_id` | AWS account ID for the logging-and-audit account | `string` | — | yes |
| `security_account_id` | AWS account ID for the security account | `string` | — | yes |
| `shared_services_account_id` | AWS account ID for the shared-services account | `string` | — | yes |
| `dev_account_id` | AWS account ID for the development account | `string` | — | yes |
| `stage_account_id` | AWS account ID for the stage account | `string` | — | yes |
| `prod_account_id` | AWS account ID for the production account | `string` | — | yes |
| `mode` | CodePipeline execution mode (SUPERSEDED, PARALLEL, QUEUED) | `string` | `"SUPERSEDED"` | no |
| `terraform_image` | Container image used by CodeBuild jobs | `string` | `"hashicorp/terraform:1.14.5"` | no |
| `build_timeout` | CodeBuild timeout in minutes (5-2160) | `number` | `10` | no |
| `kms_key_administrator_arns` | IAM principal ARNs allowed to administer KMS keys | `list(string)` | `[]` | no |
| `pipeline_artefacts_kms_alias` | Alias for the KMS key used for pipeline artifacts | `string` | `"itgix-lz-pl-artefacts"` | no |
| `shared_vars_path` | Path to the shared Terraform variables file | `string` | `"../shared-vars/shared.tfvars"` | no |
| `deploy_role_name` | IAM role name for cross-account deployment | `string` | `"itgix-lz-deployer"` | no |
| `execution_role_name` | IAM role name assumed by Terraform providers in target accounts | `string` | `"itgix-landing-zones"` | no |
| `codepipeline_role_name` | IAM role name used by CodePipeline | `string` | `"itgix_lz_codepipeline_role"` | no |
| `codebuild_role_name` | IAM role name used by CodeBuild | `string` | `"itgix-lz-codebuild-role"` | no |
| `allow_assume_deploy_role` | Whether CodeBuild can assume the deploy role | `bool` | `true` | no |
| `allow_assume_execution_role` | Whether CodeBuild can assume the execution role | `bool` | `true` | no |
| `pipelines` | Map of pipeline definitions | `map(object({pipeline_key, tf_dir, backend_file, tfvars_file, shared_vars, target_role_arn, primary_region, enabled}))` | `{}` | no |
| `tf_state_buckets` | List of Terraform state bucket names that CodeBuild can access | `list(string)` | — | yes |

## Usage Example

```hcl
module "pipelines" {
  source = "path/to/tf-module-aws-landing-zone-pipelines"

  vcs_repository_id      = "my-org/landing-zone"
  vcs_branch             = "main"
  codestar_provider_type = "GitHub"
  create_codestar_host   = false

  management_account_id        = "111111111111"
  logging_and_audit_account_id = "222222222222"
  security_account_id          = "333333333333"
  shared_services_account_id   = "444444444444"
  dev_account_id               = "555555555555"
  stage_account_id             = "666666666666"
  prod_account_id              = "777777777777"

  tf_state_buckets = ["my-org-tf-state"]

  pipelines = {
    networking = {
      pipeline_key    = "networking"
      tf_dir          = "terraform/networking"
      backend_file    = "backend.hcl"
      tfvars_file     = "networking.tfvars"
      shared_vars     = "../shared-vars/shared.tfvars"
      target_role_arn = "arn:aws:iam::444444444444:role/itgix-lz-deployer"
    }
  }
}
```
