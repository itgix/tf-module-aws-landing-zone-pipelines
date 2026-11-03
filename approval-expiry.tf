################################################################################
# Stop executions whose manual approval expired
#
# CodePipeline marks an execution as Failed when nobody approves or rejects the
# manual approval within its timeout. Plans are meant to be applied shortly after
# review only, so an expired approval is expected and should not show up as a
# failure. When an execution reaches the Approval stage, EventBridge starts a
# Step Functions workflow that waits var.approval_timeout minutes and, if that
# same execution is still waiting for approval, stops it (status "Stopped").
#
# The native approval timeout is set var.approval_timeout + a buffer, so it only
# fires (and fails the execution) if the stopper itself did not run.
################################################################################

locals {
  approval_expiry_enabled = var.stop_expired_approvals && length(local.enabled_pipelines) > 0

  approval_stage_name = "Approval"

  # Buffer between the stopper and the native approval timeout (minutes).
  approval_expiry_buffer_minutes = 10

  approval_action_timeout = (
    var.stop_expired_approvals
    ? min(var.approval_timeout + local.approval_expiry_buffer_minutes, 86400)
    : var.approval_timeout
  )

  approval_expiry_name = "${var.project_name}-lz-pipelines-approval-expiry"

  approval_expiry_pipeline_arns = [for p in aws_codepipeline.lz : p.arn]
}

################################################################################
# Step Functions workflow
################################################################################

resource "aws_iam_role" "approval_expiry_sfn" {
  count = local.approval_expiry_enabled ? 1 : 0

  name = "${local.approval_expiry_name}-sfn"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "states.amazonaws.com" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "approval_expiry_sfn" {
  count = local.approval_expiry_enabled ? 1 : 0

  name = "${local.policy_name_prefix}_ApprovalExpiry_StepFunctions"
  role = aws_iam_role.approval_expiry_sfn[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StopExpiredApprovals"
        Effect = "Allow"
        Action = [
          "codepipeline:GetPipelineState",
          "codepipeline:StopPipelineExecution",
        ]
        Resource = local.approval_expiry_pipeline_arns
      }
    ]
  })
}

resource "aws_sfn_state_machine" "approval_expiry" {
  count = local.approval_expiry_enabled ? 1 : 0

  name     = local.approval_expiry_name
  type     = "STANDARD"
  role_arn = aws_iam_role.approval_expiry_sfn[0].arn
  tags     = local.tags

  definition = jsonencode({
    Comment       = "Stops a pipeline execution whose manual approval was not decided within ${var.approval_timeout} minutes."
    QueryLanguage = "JSONata"
    StartAt       = "WaitForApprovalWindow"
    States = {
      WaitForApprovalWindow = {
        Type    = "Wait"
        Seconds = var.approval_timeout * 60
        Assign = {
          pipeline    = "{% $states.input.pipeline %}"
          executionId = "{% $states.input.executionId %}"
          stage       = "{% $states.input.stage %}"
        }
        Next = "GetPipelineState"
      }

      GetPipelineState = {
        Type      = "Task"
        Resource  = "arn:aws:states:::aws-sdk:codepipeline:getPipelineState"
        Arguments = { Name = "{% $pipeline %}" }
        Retry = [
          {
            ErrorEquals     = ["States.ALL"]
            IntervalSeconds = 5
            MaxAttempts     = 3
            BackoffRate     = 2
          }
        ]
        # Still pending only if the approval stage is in progress for this very execution
        # (not approved/rejected, and not superseded by a newer execution).
        Output = {
          approvalPending = "{% $exists($states.result.StageStates[StageName = $stage and LatestExecution.PipelineExecutionId = $executionId and LatestExecution.Status = 'InProgress']) %}"
        }
        Next = "IsApprovalPending"
      }

      IsApprovalPending = {
        Type = "Choice"
        Choices = [
          {
            Condition = "{% $states.input.approvalPending %}"
            Next      = "StopPipelineExecution"
          }
        ]
        Default = "ApprovalAlreadyHandled"
      }

      StopPipelineExecution = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:codepipeline:stopPipelineExecution"
        Arguments = {
          PipelineName        = "{% $pipeline %}"
          PipelineExecutionId = "{% $executionId %}"
          Abandon             = true
          Reason              = "Approval window of ${var.approval_timeout} minutes expired without a decision. Re-run the pipeline to get a fresh plan."
        }
        # The execution finished or was stopped in the meantime - nothing left to do.
        Catch = [
          {
            ErrorEquals = [
              "CodePipeline.PipelineExecutionNotStoppableException",
              "CodePipeline.DuplicatedStopRequestException",
            ]
            Next = "ApprovalAlreadyHandled"
          }
        ]
        Next = "ExecutionStopped"
      }

      ExecutionStopped = {
        Type = "Succeed"
      }

      ApprovalAlreadyHandled = {
        Type = "Succeed"
      }
    }
  })
}

################################################################################
# EventBridge trigger: approval action started
################################################################################

resource "aws_cloudwatch_event_rule" "approval_expiry" {
  count = local.approval_expiry_enabled ? 1 : 0

  name        = local.approval_expiry_name
  description = "Starts the approval expiry workflow when a landing zone pipeline reaches its manual approval."
  tags        = local.tags

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Action Execution State Change"]
    detail = {
      pipeline = [for p in aws_codepipeline.lz : p.name]
      stage    = [local.approval_stage_name]
      state    = ["STARTED"]
      type = {
        category = ["Approval"]
      }
    }
  })
}

resource "aws_iam_role" "approval_expiry_events" {
  count = local.approval_expiry_enabled ? 1 : 0

  name = "${local.approval_expiry_name}-events"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "approval_expiry_events" {
  count = local.approval_expiry_enabled ? 1 : 0

  name = "${local.policy_name_prefix}_ApprovalExpiry_Events"
  role = aws_iam_role.approval_expiry_events[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StartApprovalExpiryWorkflow"
        Effect   = "Allow"
        Action   = ["states:StartExecution"]
        Resource = [aws_sfn_state_machine.approval_expiry[0].arn]
      }
    ]
  })
}

resource "aws_cloudwatch_event_target" "approval_expiry" {
  count = local.approval_expiry_enabled ? 1 : 0

  rule     = aws_cloudwatch_event_rule.approval_expiry[0].name
  arn      = aws_sfn_state_machine.approval_expiry[0].arn
  role_arn = aws_iam_role.approval_expiry_events[0].arn

  input_transformer {
    input_paths = {
      pipeline    = "$.detail.pipeline"
      executionId = "$.detail.execution-id"
      stage       = "$.detail.stage"
    }
    input_template = <<-EOT
      {"pipeline": <pipeline>, "executionId": <executionId>, "stage": <stage>}
    EOT
  }
}
