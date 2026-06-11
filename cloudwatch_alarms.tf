# Application ERROR log lines, via the custom metric from the log metric filter.
# Catches handled errors that are logged but never thrown (so AWS/Lambda Errors stays at 0).
resource "aws_cloudwatch_metric_alarm" "log_errors" {

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
  }

  alarm_name        = "aws-${var.service_short_code}-${each.value.name}-log-errors"
  alarm_description = "ERROR lines detected in the ${each.value.name} Lambda log group."

  namespace           = local.cloudwatch_metric_namespace
  metric_name         = aws_cloudwatch_log_metric_filter.errors[each.key].metric_transformation[0].name
  statistic           = "Sum"
  period              = each.value.alarm_period_seconds
  evaluation_periods  = each.value.alarm_evaluation_periods
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = each.value.alarm_error_log_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions[each.key]
  ok_actions    = local.alarm_actions[each.key]

  tags = merge(local.repo_default_tags, each.value.tags)
}

# Lambda invocation errors (thrown exceptions) via the native AWS/Lambda metric.
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
  }

  alarm_name        = "aws-${var.service_short_code}-${each.value.name}-lambda-errors"
  alarm_description = "Invocation errors (thrown exceptions) on the ${each.value.name} Lambda function."

  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = module.lambda_function[each.key].function_name }
  statistic           = "Sum"
  period              = each.value.alarm_period_seconds
  evaluation_periods  = each.value.alarm_evaluation_periods
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = each.value.alarm_lambda_errors_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions[each.key]
  ok_actions    = local.alarm_actions[each.key]

  tags = merge(local.repo_default_tags, each.value.tags)
}

# Messages that exhausted max_receive_count and landed in the dead letter queue.
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
  }

  alarm_name        = "aws-${var.service_short_code}-${each.value.name}-dlq-messages"
  alarm_description = "Messages present in the ${each.value.name} dead letter queue."

  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = aws_sqs_queue.dlq[each.key].name }
  statistic           = "Maximum"
  period              = each.value.alarm_period_seconds
  evaluation_periods  = each.value.alarm_evaluation_periods
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = each.value.alarm_dlq_messages_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions[each.key]
  ok_actions    = local.alarm_actions[each.key]

  tags = merge(local.repo_default_tags, each.value.tags)
}
