module "iam_policy_lambda_execution" {

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.52"

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
  }

  name        = "aws-${var.service_short_code}-${each.value.name}-execution-policy"
  path        = "/aws/${var.service_short_code}/"
  description = "SQS consume policy for the ${each.value.name} Lambda function"

  policy = data.aws_iam_policy_document.lambda_execution[each.key].json

  tags = merge(local.repo_default_tags, each.value.tags)
}
