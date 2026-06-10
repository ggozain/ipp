variable "function_name" {
  type        = string
  description = "Name of the Lambda function. Must be unique within the account/region."
  nullable    = false
}

variable "description" {
  type        = string
  description = "Free-text description of the function."
  default     = null
}

variable "role_arn" {
  type        = string
  description = "ARN of the IAM execution role the function assumes. Created outside this module."
  nullable    = false
}

variable "image_uri" {
  type        = string
  description = "Full ECR URI of the container image, including tag or digest."
  nullable    = false
}

variable "architectures" {
  type        = list(string)
  description = "CPU architectures the function runs on. Single-element list of `arm64` or `x86_64`."
  default     = ["arm64"]
}

variable "memory_size" {
  type        = number
  description = "Memory in MB allocated to the function."
  default     = 512
}

variable "timeout" {
  type        = number
  description = "Function timeout in seconds."
  default     = 30
}

variable "reserved_concurrent_executions" {
  type        = number
  description = "Reserved concurrency for the function. `-1` disables reservation (the AWS default)."
  default     = -1
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables passed to the container. Empty map disables the environment block."
  default     = {}
}

variable "image_command" {
  type        = list(string)
  description = "Override the container image CMD. `null` keeps the image's default."
  default     = null
}

variable "image_entry_point" {
  type        = list(string)
  description = "Override the container image ENTRYPOINT. `null` keeps the image's default."
  default     = null
}

variable "image_working_directory" {
  type        = string
  description = "Override the container image working directory. `null` keeps the image's default."
  default     = null
}

variable "vpc_config" {
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  description = "VPC attachment for the function. `null` leaves the function unattached (default Lambda networking with internet egress via the AWS-managed path)."
  default     = null
}

variable "log_group_name" {
  type        = string
  description = "Name of the CloudWatch log group the function writes to. Created outside this module so retention is enforced from invocation #1."
  nullable    = false
}

variable "event_source_arn" {
  type        = string
  description = "ARN of the SQS source queue that triggers the function."
  nullable    = false
}

variable "sqs_batch_size" {
  type        = number
  description = "Maximum number of messages delivered to the function per invocation. 1-10 for standard queues."
  default     = 10
}

variable "sqs_maximum_batching_window_in_seconds" {
  type        = number
  description = "Maximum time the event source waits to gather a batch before invoking the function. 0 disables batching window."
  default     = 0
}

variable "sqs_scaling_config_maximum_concurrency" {
  type        = number
  description = "Per-event-source maximum Lambda concurrency (2-1000). `null` removes the scaling_config block (no per-source cap)."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the function and event source mapping."
  default     = {}
}
