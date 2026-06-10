aws_region      = "eu-central-1"
tag_environment = "prod"
tag_cost_center = "trading"

lambda_functions = {
  event-processor = {
    name      = "event-processor"
    image_uri = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/ipp/event-processor:1.4.0"

    memory_size = 1024
    timeout     = 30

    environment_variables = {
      LOG_LEVEL          = "INFO"
      DOWNSTREAM_API_URL = "https://api.example.com"
    }

    vpc_config = {
      vpc_id             = "vpc-0123456789abcdef0"
      subnet_ids         = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1", "subnet-0123456789abcdef2"]
      security_group_ids = []
    }

    iam_additional_policy_statements = [
      {
        sid    = "ReadDownstreamSecrets"
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        resources = ["arn:aws:secretsmanager:eu-central-1:111122223333:secret:ipp/event-processor/*"]
      }
    ]

    sqs_scaling_config_maximum_concurrency = 50
  }
}
