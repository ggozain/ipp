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

    # Wire alarm + OK actions to a paging topic. Omit to create the alarms
    # without notifications (still visible in the console).
    alarm_sns_topic_arn = "arn:aws:sns:eu-central-1:111122223333:ipp-alerts"

    # VPC attachment is driven by vpc_name. The module discovers the VPC by
    # tag:Name and attaches to the subnets tagged SubnetType = private within it.
    vpc_name = "ipp-prod-vpc"

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
