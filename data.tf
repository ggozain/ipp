data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# Execution role policy: SQS consume on source queue.
# DLQ redrive is performed by SQS itself (driven by the redrive policy on the source queue),
# not by the Lambda execution role, so no SendMessage statement is needed here.
# Queues use SSE-SQS (an SQS-owned key), so no kms:Decrypt grant is required.
data "aws_iam_policy_document" "lambda_execution" {

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
  }

  statement {
    sid    = "SQSConsume"
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]

    resources = [
      local.function_arns[each.key].source_queue_arn,
    ]
  }
}
