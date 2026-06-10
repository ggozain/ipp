output "lambda_functions" {
  description = "Map of function_key => attributes for every Lambda function created. Use this to wire producers, observability, or further IAM policy from a consumer stack."
  value = {
    for function in local.lambda_functions : function.function_key => {
      function_arn        = module.lambda_function["${local.current_region}.${function.name}"].function_arn
      function_name       = module.lambda_function["${local.current_region}.${function.name}"].function_name
      function_version    = module.lambda_function["${local.current_region}.${function.name}"].function_version
      function_invoke_arn = module.lambda_function["${local.current_region}.${function.name}"].function_invoke_arn

      execution_role_arn  = module.iam_role_lambda_execution["${local.current_region}.${function.name}"].iam_role_arn
      execution_role_name = module.iam_role_lambda_execution["${local.current_region}.${function.name}"].iam_role_name

      source_queue_arn  = aws_sqs_queue.source["${local.current_region}.${function.name}"].arn
      source_queue_url  = aws_sqs_queue.source["${local.current_region}.${function.name}"].url
      source_queue_name = aws_sqs_queue.source["${local.current_region}.${function.name}"].name

      dlq_arn  = aws_sqs_queue.dlq["${local.current_region}.${function.name}"].arn
      dlq_url  = aws_sqs_queue.dlq["${local.current_region}.${function.name}"].url
      dlq_name = aws_sqs_queue.dlq["${local.current_region}.${function.name}"].name

      log_group_name = aws_cloudwatch_log_group.lambda["${local.current_region}.${function.name}"].name
      log_group_arn  = aws_cloudwatch_log_group.lambda["${local.current_region}.${function.name}"].arn
    }
  }
}
