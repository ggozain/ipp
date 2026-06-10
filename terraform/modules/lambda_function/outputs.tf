output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_version" {
  description = "Latest published version of the Lambda function."
  value       = aws_lambda_function.this.version
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function. Used by API Gateway or similar synchronous callers."
  value       = aws_lambda_function.this.invoke_arn
}

output "event_source_mapping_uuid" {
  description = "UUID of the SQS event source mapping."
  value       = aws_lambda_event_source_mapping.sqs.uuid
}
