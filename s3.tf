module "pipeline_artefacts_bucket" {
  source = "git::https://github.com/itgix/tf-module-aws-s3-bucket.git?ref=v1.0.0"

  providers = {
    aws         = aws
    aws.replica = aws.replica
  }

  account_name        = "shared-services"
  account_environment = "lz-development"

  bucket_purpose        = "pl-artefacts"
  force_destroy         = false
  enable_versioning     = true
  bucket_owner_enforced = true

  # Encryption
  use_sse_s3_encryption = false
  primary_kms_key_arn   = module.kms.keys["pipeline_artefacts"].arn

  # Lifecycle (matches legacy behaviour as closely as the shared module supports)
  # NOTE: The shared module currently manages current-object expiration and aborting multipart uploads.
  # NOTE: If noncurrent-version expiration is needed, we should extend the shared module.
  enable_lifecycle_expiration                        = true
  lifecycle_expiration_days                          = 90
  enable_lifecycle_abort_incomplete_multipart_upload = true
  lifecycle_abort_incomplete_multipart_upload_days   = 90

  manage_bucket_policy    = true
  deny_insecure_transport = true

  tags = local.tags
}
