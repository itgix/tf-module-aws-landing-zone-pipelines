module "kms" {
  source = "git::https://github.com/itgix/tf-module-aws-kms.git?ref=v1.0.0"

  tags                      = local.tags
  enable_automatic_rotation = true

  keys = {
    pipeline_artefacts = {
      description   = "KMS key for CodePipeline artifacts"
      primary_alias = local.pipeline_artefacts_kms_alias

      #  admins only (human/admin roles), no pipeline roles
      kms_key_administrators = var.kms_key_administrator_arns

      # users can be empty or omitted; access is granted via IAM policies
      kms_key_users = []

      allowed_via_services = ["s3", "codepipeline", "codebuild"]
    }
  }
}
