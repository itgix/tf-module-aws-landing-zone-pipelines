resource "aws_codebuild_project" "tf_validate" {
  name         = "${var.project_name}-landing-zone-tf-validate"
  service_role = local.codebuild_role_arn
  build_timeout = var.build_timeout

  artifacts { type = "CODEPIPELINE" }

  source {
    type                = "CODEPIPELINE"
    buildspec           = file("${path.module}/buildspecs/validate.yml")
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${var.terraform_image}"
    type         = "LINUX_CONTAINER"
  }

}

resource "aws_codebuild_project" "tf_plan" {
  name         = "${var.project_name}-landing-zone-tf-plan"
  service_role = local.codebuild_role_arn
  build_timeout = var.build_timeout

  artifacts { type = "CODEPIPELINE" }
  source {
    type                = "CODEPIPELINE"
    buildspec           = file("${path.module}/buildspecs/plan.yml")
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${var.terraform_image}"
    type         = "LINUX_CONTAINER"
  }
}

resource "aws_codebuild_project" "tf_apply" {
  name         = "${var.project_name}-landing-zone-tf-apply"
  service_role = local.codebuild_role_arn
  build_timeout = var.build_timeout

  artifacts { type = "CODEPIPELINE" }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspecs/apply.yml")
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${var.terraform_image}"
    type         = "LINUX_CONTAINER"
  }
}
