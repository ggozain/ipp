variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "tag_environment" {
  type    = string
  default = "dev"
}

variable "tag_cost_center" {
  type    = string
  default = "platform"
}

variable "lambda_functions" {
  type        = any
  description = "Map of Lambda functions to create. Full schema documented in ../../readme.md."
  default     = {}
}
