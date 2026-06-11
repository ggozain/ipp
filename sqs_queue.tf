# dead letter queue. created first so its arn can be referenced by the source queue's redrive policy.
resource "aws_sqs_queue" "dlq" {

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
  }

  name                      = "aws-${var.service_short_code}-${each.value.name}-dlq"
  message_retention_seconds = each.value.dlq_message_retention_seconds
  sqs_managed_sse_enabled   = true

  tags = merge(local.repo_default_tags, each.value.tags)
}

# source queue. lambda event source mapping polls this.
resource "aws_sqs_queue" "source" {

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
  }

  name                       = "aws-${var.service_short_code}-${each.value.name}"
  message_retention_seconds  = each.value.sqs_message_retention_seconds
  visibility_timeout_seconds = each.value.sqs_visibility_timeout_seconds
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = each.value.sqs_max_receive_count
  })

  tags = merge(local.repo_default_tags, each.value.tags)
}
