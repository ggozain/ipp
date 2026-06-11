module "iam_role_lambda_execution" {

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.52"

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
  }

  role_name        = "aws-${var.service_short_code}-${each.value.name}-execution-role"
  role_path        = "/aws/${var.service_short_code}/"
  role_description = "Execution role for the ${each.value.name} Lambda function"
  create_role      = true

  trusted_role_services = ["lambda.amazonaws.com"]
  role_requires_mfa     = false # service to service

  custom_role_policy_arns = concat(
    [
      "arn:${local.current_partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
      module.iam_policy_lambda_execution[each.key].arn,
    ],
    each.value.vpc_name != null ? [
      "arn:${local.current_partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    ] : [],
    each.value.iam_additional_policy_arns,
  )

  inline_policy_statements = each.value.iam_additional_policy_statements

  tags = merge(local.repo_default_tags, each.value.tags)
}
