# global
locals {
  repo_default_tags = {
    CostCenter = lower(var.tag_cost_center)
  }
  current_account_id = data.aws_caller_identity.current.account_id
  current_region     = data.aws_region.current.region
  current_partition  = data.aws_partition.current.partition
}

# lambda functions: flatten + defaults
locals {
  lambda_functions = flatten([
    for function_key, function in var.lambda_functions : {
      function_key            = function_key
      name                    = function.name
      image_uri               = function.image_uri
      image_command           = contains(keys(function), "image_command") ? function.image_command : null
      image_entry_point       = contains(keys(function), "image_entry_point") ? function.image_entry_point : null
      image_working_directory = contains(keys(function), "image_working_directory") ? function.image_working_directory : null
      architectures           = contains(keys(function), "architectures") ? function.architectures : ["arm64"]
      memory_size             = contains(keys(function), "memory_size") ? function.memory_size : 512
      timeout                 = contains(keys(function), "timeout") ? function.timeout : 30
      reserved_concurrency    = contains(keys(function), "reserved_concurrency") ? function.reserved_concurrency : null
      environment_variables   = contains(keys(function), "environment_variables") ? function.environment_variables : {}
      vpc_config              = contains(keys(function), "vpc_config") ? function.vpc_config : null

      sqs_visibility_timeout_seconds = contains(keys(function), "sqs_visibility_timeout_seconds") ? (
        function.sqs_visibility_timeout_seconds
        ) : (
        6 * (contains(keys(function), "timeout") ? function.timeout : 30)
      )
      sqs_message_retention_seconds          = contains(keys(function), "sqs_message_retention_seconds") ? function.sqs_message_retention_seconds : 1209600
      sqs_max_receive_count                  = contains(keys(function), "sqs_max_receive_count") ? function.sqs_max_receive_count : 5
      sqs_batch_size                         = contains(keys(function), "sqs_batch_size") ? function.sqs_batch_size : 10
      sqs_maximum_batching_window_in_seconds = contains(keys(function), "sqs_maximum_batching_window_in_seconds") ? function.sqs_maximum_batching_window_in_seconds : 0
      sqs_scaling_config_maximum_concurrency = contains(keys(function), "sqs_scaling_config_maximum_concurrency") ? function.sqs_scaling_config_maximum_concurrency : null
      sqs_kms_master_key_id                  = contains(keys(function), "sqs_kms_master_key_id") ? function.sqs_kms_master_key_id : "alias/aws/sqs"

      dlq_message_retention_seconds = contains(keys(function), "dlq_message_retention_seconds") ? function.dlq_message_retention_seconds : 1209600

      cloudwatch_retention_in_days = contains(keys(function), "cloudwatch_retention_in_days") ? function.cloudwatch_retention_in_days : 30
      cloudwatch_skip_destroy      = contains(keys(function), "cloudwatch_skip_destroy") ? function.cloudwatch_skip_destroy : false

      iam_additional_policy_arns       = contains(keys(function), "iam_additional_policy_arns") ? function.iam_additional_policy_arns : []
      iam_additional_policy_statements = contains(keys(function), "iam_additional_policy_statements") ? function.iam_additional_policy_statements : []

      tags = contains(keys(function), "tags") ? function.tags : {}
    }
  ])
}

# pre-computed ARNs so the policy document can reference the source queue and DLQ
# without creating a cycle between module.iam_policy -> module.sqs_source -> module.iam_role.
locals {
  function_arns = {
    for function in local.lambda_functions :
    "${local.current_region}.${function.name}" => {
      source_queue_arn = "arn:${local.current_partition}:sqs:${local.current_region}:${local.current_account_id}:aws-${var.service_short_code}-${function.name}"
      dlq_arn          = "arn:${local.current_partition}:sqs:${local.current_region}:${local.current_account_id}:aws-${var.service_short_code}-${function.name}-dlq"
    }
  }
}
