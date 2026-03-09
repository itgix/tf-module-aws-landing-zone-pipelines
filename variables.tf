# Source provider / CodeConnections
variable "codestar_provider_type" {
  description = "Source repository provider used by AWS CodeConnections."
  type        = string
  default     = "GitLabSelfManaged"

  validation {
    condition = contains(
      [
        "GitLabSelfManaged",
        "GitLab",
        "GitHub",
        "Bitbucket",
        "GitHubEnterpriseServer"
      ],
      var.codestar_provider_type
    )
    error_message = "codestar_provider_type must be one of: GitLabSelfManaged, GitLab, GitHub, Bitbucket, GitHubEnterpriseServer."
  }
}

variable "create_codestar_host" {
  description = "If true, create aws_codestarconnections_host. This is typically required only for self-managed providers such as GitLabSelfManaged and GitHubEnterpriseServer."
  type        = bool
  default     = true
}

variable "create_codestar_connection" {
  description = "If true, create aws_codestarconnections_connection. If false, codestar_connection_arn must be provided."
  type        = bool
  default     = true
}

variable "codestar_connection_arn" {
  description = "Existing CodeConnections connection ARN to use when create_codestar_connection is false."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.create_codestar_connection || var.codestar_connection_arn != null
    error_message = "When create_codestar_connection is false, codestar_connection_arn must be provided."
  }
}

variable "codestar_host_name" {
  description = "Host name for aws_codestarconnections_host. Required for self-managed providers when create_codestar_host is true."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
    !var.create_codestar_host
    || !contains(["GitLabSelfManaged", "GitHubEnterpriseServer"], var.codestar_provider_type)
    || var.codestar_host_name != null
    )
    error_message = "When create_codestar_host is true for GitLabSelfManaged or GitHubEnterpriseServer, codestar_host_name must be provided."
  }
}

variable "codestar_provider_endpoint" {
  description = "Endpoint URL for the source provider. Required for self-managed providers such as GitLabSelfManaged and GitHubEnterpriseServer."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
    !contains(["GitLabSelfManaged", "GitHubEnterpriseServer"], var.codestar_provider_type)
    || var.codestar_provider_endpoint != null
    )
    error_message = "For GitLabSelfManaged or GitHubEnterpriseServer you must set codestar_provider_endpoint."
  }
}

variable "codestar_connection_name" {
  description = "Name of the CodeConnections connection. Required when create_codestar_connection is true."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = !var.create_codestar_connection || var.codestar_connection_name != null
    error_message = "When create_codestar_connection is true, codestar_connection_name must be provided."
  }
}

# Repository settings
variable "vcs_repository_id" {
  description = "Repository identifier in provider format, for example <group>/<repo> or <org>/<repo>."
  type        = string
}

variable "vcs_branch" {
  description = "Branch to track in the source repository."
  type        = string
  default     = "main"
}

# General
variable "tags" {
  description = "Additional tags to apply to resources created by this module."
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "Base project identifier used in resource naming."
  type        = string
  default     = "itgix"
}

variable "policy_name_prefix" {
  description = "Optional prefix for IAM policy names. If not set, project_name can be used instead."
  type        = string
  default     = null
  nullable    = true
}

# Regions / profiles
variable "account_primary_region" {
  description = "Primary AWS region where the main resources for the account are deployed."
  type        = string
  default     = "eu-central-1"
}

variable "replica_region" {
  description = "Secondary AWS region used for cross-region replication."
  type        = string
  default     = ""
}

variable "pipelines_management_profile" {
  description = "Optional explicit AWS CLI profile. If empty, rely on AWS_PROFILE from the environment."
  type        = string
  default     = ""
}

# Account IDs
variable "management_account_id" {
  description = "AWS account ID for the management account."
  type        = string
}

variable "logging_and_audit_account_id" {
  description = "AWS account ID for the logging-and-audit account."
  type        = string
}

variable "security_account_id" {
  description = "AWS account ID for the security account."
  type        = string
}

variable "shared_services_account_id" {
  description = "AWS account ID for the shared-services account."
  type        = string
}

variable "dev_account_id" {
  description = "AWS account ID for the development account."
  type        = string
}

variable "stage_account_id" {
  description = "AWS account ID for the stage account."
  type        = string
}

variable "prod_account_id" {
  description = "AWS account ID for the production account."
  type        = string
}

# Pipeline execution
variable "mode" {
  description = "CodePipeline execution mode."
  type        = string
  default     = "SUPERSEDED"

  validation {
    condition     = contains(["SUPERSEDED", "PARALLEL", "QUEUED"], var.mode)
    error_message = "mode must be one of: SUPERSEDED, PARALLEL, QUEUED."
  }
}

variable "terraform_image" {
  description = "Container image used by CodeBuild jobs."
  type        = string
  default     = "hashicorp/terraform:1.14.5"
}

variable "build_timeout" {
  description = "CodeBuild timeout in minutes."
  type        = number
  default     = 10

  validation {
    condition     = var.build_timeout >= 5 && var.build_timeout <= 2160
    error_message = "build_timeout must be between 5 and 2160 minutes."
  }
}

# KMS / artefacts
variable "kms_key_administrator_arns" {
  description = "List of IAM principal ARNs allowed to administer the KMS keys."
  type        = list(string)
  default     = []
}

variable "pipeline_artefacts_kms_alias" {
  description = "Alias name for the KMS key used to encrypt pipeline artefacts."
  type        = string
  default     = "itgix-lz-pl-artefacts"
}

# Paths / files
variable "shared_vars_path" {
  description = "Path to the shared Terraform variables file."
  type        = string
  default     = "../shared-vars/shared.tfvars"
}

# IAM role names / AssumeRole behaviour
variable "deploy_role_name" {
  description = "Name of the IAM role used for cross-account deployment (pivot role)."
  type        = string
  default     = "itgix-lz-deployer"
}

variable "execution_role_name" {
  description = "Name of the IAM role assumed by Terraform providers inside target accounts."
  type        = string
  default     = "itgix-landing-zones"
}

variable "codepipeline_role_name" {
  description = "Name of the IAM role used by CodePipeline."
  type        = string
  default     = "itgix_lz_codepipeline_role"
}

variable "codebuild_role_name" {
  description = "Name of the IAM role used by CodeBuild."
  type        = string
  default     = "itgix-lz-codebuild-role"
}

variable "allow_assume_deploy_role" {
  description = "Whether the CodeBuild role is allowed to assume the deploy role in target accounts."
  type        = bool
  default     = true
}

variable "allow_assume_execution_role" {
  description = "Whether the CodeBuild role is allowed to assume the execution role in target accounts."
  type        = bool
  default     = true
}

# Pipeline definitions / Terraform state buckets
variable "pipelines" {
  description = "Definitions for each pipeline. The map key is the pipeline identifier."
  type = map(object({
    pipeline_key    = string
    tf_dir          = string
    backend_file    = string
    tfvars_file     = string
    shared_vars     = string
    target_role_arn = string
    primary_region  = optional(string)
    enabled         = optional(bool, true)
  }))
  default = {}
}

variable "tf_state_buckets" {
  description = "List of Terraform state bucket names that CodeBuild is allowed to access."
  type        = list(string)
}