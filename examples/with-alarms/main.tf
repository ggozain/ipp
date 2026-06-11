module "ipp" {
  source = "github.com/ggozain/ipp?ref=v1.0.0"

  aws_region         = var.aws_region
  service_short_code = "ipp"
  tag_environment    = var.tag_environment
  tag_cost_center    = var.tag_cost_center

  lambda_functions = var.lambda_functions
}
