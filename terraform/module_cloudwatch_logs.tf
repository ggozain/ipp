# Pre-created so retention is enforced on the very first invocation and the resource is
# managed by terraform rather than created implicitly by Lambda. The lambda module
# below is told not to create one (`use_existing_cloudwatch_log_group = true`).
resource "aws_cloudwatch_log_group" "lambda" {

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
  }

  name              = "/aws/lambda/aws-${var.service_short_code}-${each.value.name}"
  retention_in_days = each.value.cloudwatch_retention_in_days
  skip_destroy      = each.value.cloudwatch_skip_destroy

  tags = merge(local.repo_default_tags, each.value.tags)
}

# Surfaces application-level ERROR log lines (per the documented log format,
# e.g. "... : ERROR : Error with AWS SQS request") as a custom metric, so they can be
# alarmed on even when the handler logs the error without throwing. The pattern is a
# substring match on the level field and is overridable via alarm_error_log_pattern.
resource "aws_cloudwatch_log_metric_filter" "errors" {

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
  }

  name           = "aws-${var.service_short_code}-${each.value.name}-error-log-lines"
  log_group_name = aws_cloudwatch_log_group.lambda[each.key].name
  pattern        = each.value.alarm_error_log_pattern

  metric_transformation {
    name          = "aws-${var.service_short_code}-${each.value.name}-error-log-lines"
    namespace     = local.cloudwatch_metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}
