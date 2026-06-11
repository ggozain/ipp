module "lambda_function" {

  source = "./modules/lambda_function"

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
  }

  function_name = "aws-${var.service_short_code}-${each.value.name}"
  description   = "Container Lambda function ${each.value.name}, triggered by SQS"
  role_arn      = module.iam_role_lambda_execution[each.key].iam_role_arn

  image_uri               = each.value.image_uri
  image_command           = each.value.image_command
  image_entry_point       = each.value.image_entry_point
  image_working_directory = each.value.image_working_directory
  architectures           = each.value.architectures

  memory_size                    = each.value.memory_size
  timeout                        = each.value.timeout
  reserved_concurrent_executions = each.value.reserved_concurrency != null ? each.value.reserved_concurrency : -1
  environment_variables          = each.value.environment_variables

  log_group_name = aws_cloudwatch_log_group.lambda[each.key].name

  event_source_arn                       = aws_sqs_queue.source[each.key].arn
  sqs_batch_size                         = each.value.sqs_batch_size
  sqs_maximum_batching_window_in_seconds = each.value.sqs_maximum_batching_window_in_seconds
  sqs_scaling_config_maximum_concurrency = each.value.sqs_scaling_config_maximum_concurrency

  tags = merge(local.repo_default_tags, each.value.tags)
}
