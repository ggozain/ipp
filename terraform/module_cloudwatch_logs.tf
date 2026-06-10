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
