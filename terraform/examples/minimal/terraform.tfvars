aws_region      = "eu-central-1"
tag_environment = "dev"
tag_cost_center = "platform"

lambda_functions = {
  event-processor = {
    name      = "event-processor"
    image_uri = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/ipp/event-processor:1.0.0"

    environment_variables = {
      LOG_LEVEL = "INFO"
    }
  }
}
