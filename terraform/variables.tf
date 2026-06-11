# global
variable "aws_region" {
  type        = string
  description = "The AWS region the consuming provider is configured for. Used in IAM ARN construction; not used to configure a provider inside the module."
  default     = null
}

variable "service_short_code" {
  type        = string
  description = "Short code used as a prefix for resource names and an IAM path segment (eg `ipp` produces `aws-ipp-<function>-execution-role`)."
  nullable    = false
}

# tags
variable "tag_environment" {
  type        = string
  description = "The environment the resource is contained within. Lower-cased and applied as the `Environment` tag."
  default     = null
}

variable "tag_cost_center" {
  type        = string
  description = "The cost center that the resource is attributed to. Lower-cased and applied as the `CostCenter` tag."
  default     = "platform"
}

# functions
variable "lambda_functions" {
  type        = any
  description = "A map of Lambda functions to create. Each entry creates a Lambda (container image), a source SQS queue with an event source mapping, a redrive DLQ, a CloudWatch log group with an ERROR-line metric filter, three CloudWatch alarms (log errors, Lambda invocation errors, DLQ depth), an execution role, and an optional VPC attachment with an egress-443 security group. See readme.md for the full per-function schema and defaults."
  default     = {}
}
