resource "aws_lambda_function" "this" {

  function_name = var.function_name
  description   = var.description
  role          = var.role_arn

  package_type  = "Image"
  image_uri     = var.image_uri
  architectures = var.architectures

  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [var.environment_variables] : []
    content {
      variables = environment.value
    }
  }

  dynamic "image_config" {
    for_each = (
      var.image_command != null ||
      var.image_entry_point != null ||
      var.image_working_directory != null
    ) ? [1] : []

    content {
      command           = var.image_command
      entry_point       = var.image_entry_point
      working_directory = var.image_working_directory
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = var.log_group_name
  }

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "sqs" {

  event_source_arn = var.event_source_arn
  function_name    = aws_lambda_function.this.arn
  enabled          = true

  batch_size                         = var.sqs_batch_size
  maximum_batching_window_in_seconds = var.sqs_maximum_batching_window_in_seconds
  function_response_types            = ["ReportBatchItemFailures"]

  dynamic "scaling_config" {
    for_each = var.sqs_scaling_config_maximum_concurrency != null ? [var.sqs_scaling_config_maximum_concurrency] : []
    content {
      maximum_concurrency = scaling_config.value
    }
  }

  tags = var.tags
}
