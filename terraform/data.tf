data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "this" {

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
    if function.vpc_name != null
  }

  filter {
    name   = "tag:Name"
    values = [each.value.vpc_name]
  }
}


data "aws_subnets" "private" {

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
    if function.vpc_name != null
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this["${local.current_region}.${each.value.name}"].id]
  }

  tags = {
    SubnetType = "private"
  }

  lifecycle {
    postcondition {
      condition     = length(self.ids) > 0
      error_message = "No subnets tagged SubnetType = private were found in VPC '${each.value.vpc_name}'. A VPC-attached Lambda function needs at least one private subnet."
    }
  }
}


# Execution role policy: SQS consume on source queue.
# DLQ redrive is performed by SQS itself (driven by the redrive policy on the source queue),
# not by the Lambda execution role, so no SendMessage statement is needed here.
# `kms:Decrypt` is added only when the consumer overrides the default AWS-managed key.
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

  dynamic "statement" {

    for_each = each.value.sqs_kms_master_key_id != "alias/aws/sqs" ? [each.value.sqs_kms_master_key_id] : []

    content {
      sid    = "KMSDecryptForSQS"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
      ]
      resources = [
        # Accept either an alias or a full key ARN. If consumers pass a bare key id, they should
        # supply a full ARN instead; constraining to ARN/alias keeps the policy auditable.
        statement.value,
      ]
    }
  }
}
