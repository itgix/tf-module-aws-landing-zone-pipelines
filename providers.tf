terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.00"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }
  }
  required_version = "~> 1.7"
}


provider "aws" {
  profile = var.pipelines_management_profile != "" ? var.pipelines_management_profile : null
  region  = var.account_primary_region
}

provider "aws" {
  alias   = "replica"
  profile = var.pipelines_management_profile != "" ? var.pipelines_management_profile : null
  region  = var.replica_region != "" ? var.replica_region : var.account_primary_region
}
