module "ipp" {
  source = "github.com/ggozain/ipp?ref=v1.0.0"

  aws_region         = "eu-central-1"
  service_short_code = "ipp"
  tag_environment    = "prod"
  tag_cost_center    = "trading"

  lambda_functions = {
    # Full-featured function: alarm notifications, extra IAM, custom sizing
    # and a per-event-source concurrency cap.
    event-processor = {
      name      = "event-processor"
      image_uri = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/ipp/event-processor:1.4.0"

      memory_size = 1024
      timeout     = 30

      environment_variables = {
        LOG_LEVEL          = "INFO"
        DOWNSTREAM_API_URL = "https://api.example.com"
      }

      # Wire alarm + OK actions to a paging topic. Alarms are always created;
      # omit this to leave them without notifications (still visible in the console).
      alarm_sns_topic_arn = "arn:aws:sns:eu-central-1:111122223333:ipp-alerts"

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

    # Second function sharing the same paging topic, tuned for higher latency
    # work: a longer timeout and a tighter DLQ alarm threshold.
    event-archiver = {
      name      = "event-archiver"
      image_uri = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/ipp/event-archiver:1.4.0"

      memory_size = 512
      timeout     = 120

      environment_variables = {
        LOG_LEVEL = "INFO"
      }

      alarm_sns_topic_arn          = "arn:aws:sns:eu-central-1:111122223333:ipp-alerts"
      alarm_dlq_messages_threshold = 5
    }
  }
}
