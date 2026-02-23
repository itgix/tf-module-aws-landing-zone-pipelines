# CodeStar / CodeConnections
variable "gitlab_base_url" {
  type        = string
  description = "Base URL of self-managed GitLab (legacy)."
  default     = null
  nullable    = true
}

variable "gitlab_host_name" {
  type        = string
  description = "CodeConnections Host name (legacy)."
  default     = "itgix-gitlab-selfmanaged"
}

variable "gitlab_connection_name" {
  type        = string
  description = "CodeConnections Connection name (legacy)."
  default     = "itgix-lz-gitlab-connection"
}

variable "gitlab_full_repository_id" {
  description = "Repository in the format <group>/<repo> (legacy)."
  type        = string
  default     = "rnd/aws-landing-zones/landing-zone-deployment"
}

variable "gitlab_branch" {
  description = "Branch to track (legacy)."
  type        = string
  default     = "main"
}

# Generic provider selection
variable "codestar_provider_type" {
  description = "Source provider type for CodeStar connection."
  type        = string
  default     = "GitLabSelfManaged"

  validation {
    condition = contains(
      ["GitLabSelfManaged", "GitLab", "GitHub", "Bitbucket", "GitHubEnterpriseServer"],
      var.codestar_provider_type
    )
    error_message = "codestar_provider_type must be one of: GitLabSelfManaged, GitLab, GitHub, Bitbucket, GitHubEnterpriseServer."
  }
}

variable "create_codestar_host" {
  description = "If true, create aws_codestarconnections_host (used only for GitLabSelfManaged / GitHubEnterpriseServer)."
  type        = bool
  default     = true
}

variable "create_codestar_connection" {
  description = "If true, create aws_codestarconnections_connection; otherwise use codestar_connection_arn."
  type        = bool
  default     = true
}

variable "codestar_connection_arn" {
  description = "Existing CodeStar connection ARN. Used when create_codestar_connection = false."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.create_codestar_connection || var.codestar_connection_arn != null
    error_message = "When create_codestar_connection = false, you must set codestar_connection_arn."
  }
}

# Optional generic names/endpoints
variable "codestar_host_name" {
  description = "Generic host name override (optional)."
  type        = string
  default     = null
  nullable    = true
}

variable "codestar_provider_endpoint" {
  description = "Generic provider endpoint override (optional). Required for GitLabSelfManaged/GitHubEnterpriseServer if gitlab_base_url is not set."
  type        = string
  default     = null
  nullable    = true
}

variable "codestar_connection_name" {
  description = "Generic connection name override (optional)."
  type        = string
  default     = null
  nullable    = true
}

# General
variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}
}

variable "project_name" {
  description = "Base project identifier used in naming"
  type        = string
  default     = "itgix"
}

variable "policy_name_prefix" {
  description = "Optional prefix for IAM policy names. Defaults to project_name."
  type        = string
  default     = null
  nullable    = true
}

# Regions / profiles
variable "account_primary_region" {
  type        = string
  description = "Primary AWS region where the main resources for this account are deployed."
  default     = "eu-central-1"
}

variable "replica_region" {
  type        = string
  description = "Secondary AWS region used for cross-region replication."
  default     = ""
}

variable "pipelines_management_profile" {
  type        = string
  description = "Optional explicit AWS CLI profile. If empty, rely on env AWS_PROFILE."
  default     = ""
}

# Accounts (still required - no safe defaults)
variable "management_account_id"        { type = string }
variable "logging_and_audit_account_id" { type = string }
variable "security_account_id"          { type = string }
variable "shared_services_account_id"   { type = string }
variable "dev_account_id"               { type = string }
variable "stage_account_id"             { type = string }
variable "prod_account_id"              { type = string }

# Pipeline execution
variable "mode" {
  description = "CodePipeline execution mode"
  type        = string
  default     = "SUPERSEDED"

  validation {
    condition     = contains(["SUPERSEDED", "PARALLEL", "QUEUED"], var.mode)
    error_message = "Supported pipeline mode are SUPERSEDED, PARALLEL or QUEUED."
  }
}

variable "terraform_image" {
  description = "Container image used by CodeBuild jobs"
  type        = string
  default     = "hashicorp/terraform:1.14.5"
}

variable "build_timeout" {
  description = "Minutes for CodeBuild job timeout."
  type        = number
  default     = 10
}

# KMS / Artefacts
variable "kms_key_administrator_arns" {
  description = "List of IAM principal ARNs allowed to administer the KMS keys."
  type        = list(string)
  default     = []
}

variable "pipeline_artefacts_kms_alias" {
  description = "Alias name for the KMS key used for pipeline artefacts."
  type        = string
  default     = "itgix-lz-pl-artefacts"

}

# Paths / files
variable "shared_vars_path" {
  description = "Path to shared Terraform variables file."
  type        = string
  default     = "../shared-vars/shared.tfvars"
}

# IAM Role names + AssumeRole behavior
variable "deploy_role_name" {
  description = "Name of the IAM role used for cross-account deployment (pivot)."
  type        = string
  default     = "itgix-lz-deployer"

}

variable "execution_role_name" {
  description = "Role assumed by Terraform providers inside target accounts."
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
  description = "Whether CodeBuild role can assume the pivot deploy role in target accounts."
  type        = bool
  default     = true
}

variable "allow_assume_execution_role" {
  description = "Whether CodeBuild role can assume the execution role in target accounts."
  type        = bool
  default     = true
}

# Pipelines definitions + TF state buckets
variable "pipelines" {
  description = "Definitions for each pipeline. Key is pipeline_id."
  type = map(object({
    pipeline_key     = string
    tf_dir           = string
    backend_file     = string
    tfvars_file      = string
    shared_vars      = string
    target_role_arn  = string
    primary_region   = optional(string)
    enabled          = optional(bool, true)
  }))
  default = {}
}

variable "tf_state_buckets" {
  type        = list(string)
  description = "List of Terraform state bucket names CodeBuild can access"
}