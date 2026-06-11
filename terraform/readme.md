# aws-lambda-sqs

Reusable Terraform module for an SQS-triggered container Lambda function.

## What it creates per function

- AWS Lambda function in `Image` package mode pointing at an ECR image you already pushed.
- SQS source queue + SQS DLQ, both KMS-encrypted, redrive policy wired.
- Lambda event source mapping (SQS -> Lambda) with `ReportBatchItemFailures` partial-batch handling.
- IAM execution role with `AWSLambdaBasicExecutionRole`, SQS consume policy, optional `AWSLambdaVPCAccessExecutionRole`, plus any extra policy ARNs or inline statements you pass.
- CloudWatch log group pre-created with retention (so retention applies from the first invocation).
- Optional VPC attachment with a default egress-443 security group (the function "sends outgoing requests to the internet", so this is the easy thing to forget when adopters move into a VPC).

## Preconditions and assumptions

This module provisions the Lambda and its immediate dependencies only. It assumes the surrounding account, VPC and application are already shaped as below. Only the private-subnet assumption is checked at plan time; the rest fail at apply or, worse, silently at runtime, so confirm them before adopting.

General:

- **The ECR image already exists and is pullable.** `image_uri` must point at an image pushed to ECR in this account and region. The module neither builds nor pushes, and adds no cross-account ECR repository policy, so cross-account pulls need that arranged separately.
- **One region, caller-owned provider.** Every resource lands in `aws_region`. The caller configures the `aws` provider, credentials and state backend.
- **Standard SQS queues, not FIFO.** Queue names carry no `.fifo` suffix and `sqs_batch_size` assumes the standard-queue ceiling of 10. FIFO is out of scope.

Logging (this is what the ERROR alarm depends on):

- **The function logs to stdout/stderr.** CloudWatch only captures what the runtime writes to stdout/stderr. The "log file" described in the brief must be redirected to stdout inside the container; if the image writes to a file on the ephemeral filesystem, the log group stays empty and none of the log-based alarming fires.
- **Log lines match the documented level format.** The ERROR alarm keys off the substring `" : ERROR : "` (the level field of `2026-05-11 15:09:09,394 : ERROR : ...`). If the application changes its log format, override `alarm_error_log_pattern` to match, or the alarm goes silent without erroring.

VPC (only when `vpc_name` is set):

- **The named VPC exists and is unique.** Exactly one VPC must carry `tag:Name = <vpc_name>` in this region. Zero or multiple matches fail the `aws_vpc` lookup at plan time.
- **At least one private subnet is tagged.** Subnets to attach to must carry `tag:SubnetType = private` inside that VPC. Enforced by a `postcondition`, so a missing tag fails the plan with a clear message rather than producing a subnet-less function.
- **Those subnets can actually egress.** The module opens 443 egress on the helper SG but creates no routing. The private subnets must already route `0.0.0.0/0` to a NAT gateway (or provide the relevant VPC endpoints) for outbound requests to leave.

Alarms and encryption:

- **The SNS topic exists and accepts CloudWatch.** When `alarm_sns_topic_arn` is set, the topic must already exist and its access policy must allow `cloudwatch.amazonaws.com` to publish. The module wires the action but does not create the topic or its policy.
- **A custom KMS key must permit both the role and SQS.** If you pass a CMK via `sqs_kms_master_key_id`, the IAM side is handled (the execution role gets `kms:Decrypt`/`kms:GenerateDataKey`), but the key's own policy must also allow that role and the `sqs.amazonaws.com` service principal. KMS requires both the IAM grant and the key policy.

## Usage

```hcl
module "lambda_sqs" {
  source = "github.com/<owner>/ipp//terraform"

  aws_region         = "eu-central-1"
  service_short_code = "ipp"
  tag_environment    = "prod"
  tag_cost_center    = "trading"

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
    }
  }
}
```

See `examples/minimal/` for the smallest possible call and `examples/with-vpc/` for a function inside a VPC with extra IAM.

## Per-function inputs

`lambda_functions` is a `map(any)`. Each value supports the following keys.

| Key | Required | Default | Notes |
|---|:-:|---|---|
| `name` | yes | - | Suffix used in every resource name. Kebab-case. |
| `image_uri` | yes | - | Full ECR image URI including tag or digest. Module does not build or push. |
| `image_command` / `image_entry_point` / `image_working_directory` | no | `null` | Container image overrides. |
| `architectures` | no | `["arm64"]` | Use `["x86_64"]` if your image is x86. |
| `memory_size` | no | `512` | MB. |
| `timeout` | no | `30` | Seconds. SQS visibility timeout defaults to `6 * timeout` per AWS guidance, so retries do not double-fire. |
| `reserved_concurrency` | no | `null` | Pass an integer to reserve concurrency. |
| `environment_variables` | no | `{}` | `map(string)`. |
| `vpc_name` | no | `null` | `tag:Name` of the target VPC. Set to attach the function to that VPC: the module discovers it and selects the subnets tagged `SubnetType = private`, then adds `AWSLambdaVPCAccessExecutionRole` and the egress-443 helper SG. |
| `sqs_visibility_timeout_seconds` | no | `6 * timeout` | Override only if your handler has long async tails. |
| `sqs_message_retention_seconds` | no | `1209600` (14d) | |
| `sqs_max_receive_count` | no | `5` | Redrive threshold; after this many failed receives, SQS moves the message to the DLQ. |
| `sqs_batch_size` | no | `10` | Lambda event source mapping batch size. Up to 10 for standard queues. |
| `sqs_maximum_batching_window_in_seconds` | no | `0` | Set to batch under low load. |
| `sqs_scaling_config_maximum_concurrency` | no | `null` | Per-event-source max Lambda concurrency (2-1000). |
| `sqs_kms_master_key_id` | no | `alias/aws/sqs` | AWS-managed by default. Pass a CMK ARN to use your own; the execution role gets `kms:Decrypt`/`kms:GenerateDataKey` on it. |
| `dlq_message_retention_seconds` | no | `1209600` (14d) | DLQ retention - keep this high so you have time to investigate. |
| `cloudwatch_retention_in_days` | no | `30` | Log group retention. |
| `cloudwatch_skip_destroy` | no | `false` | Keep the log group on destroy. |
| `alarm_sns_topic_arn` | no | `null` | SNS topic ARN for alarm + OK actions. Alarms are always created; actions are wired only when this is set. |
| `alarm_error_log_pattern` | no | `" : ERROR : "` | CloudWatch filter pattern feeding the ERROR-line metric. Defaults to a substring match on the log level field of the documented format. |
| `alarm_error_log_threshold` | no | `1` | ERROR log lines per period that trip the log-errors alarm. |
| `alarm_lambda_errors_threshold` | no | `1` | `AWS/Lambda` `Errors` (thrown exceptions) per period that trip the Lambda-errors alarm. |
| `alarm_dlq_messages_threshold` | no | `1` | DLQ `ApproximateNumberOfMessagesVisible` that trips the DLQ alarm. |
| `alarm_period_seconds` | no | `300` | Evaluation period shared by all three alarms. |
| `alarm_evaluation_periods` | no | `1` | Number of periods shared by all three alarms. |
| `iam_additional_policy_arns` | no | `[]` | Extra managed/customer policy ARNs attached to the execution role. |
| `iam_additional_policy_statements` | no | `[]` | Inline statements (same shape as `terraform-aws-modules/iam` `inline_policy_statements`). |
| `tags` | no | `{}` | Merged with `CostCenter` repo default. |

## Production notes

- **Visibility timeout x6 the function timeout.** AWS recommends >= 6x because the SQS poller can hold a message for retries while the function is still running.
- **KMS encrypted queues by default** using the AWS-managed key. Pass a CMK via `sqs_kms_master_key_id` for stricter compliance.
- **ARM64 by default.** Cheaper and faster per memory tier; only override for images that need x86.
- **Optional VPC, no VPC by default.** Default Lambda networking already gives outbound internet via the AWS-managed path. Only attach to a VPC when the function needs to reach private resources or egress through a NAT for egress-IP allowlisting.
- **No function-level DLQ.** SQS-triggered Lambdas are polled, not invoked asynchronously, so the canonical failure path is the SQS redrive DLQ. A function-level DLQ here would never receive messages.
- **`ReportBatchItemFailures` response is enabled.** Your handler may return partial-batch failures so successful items in a batch are not retried.
- **Three alarms per function, driven by the log format and native metrics.** A log metric filter on the `ERROR` level field feeds a `log-errors` alarm (catches errors the handler logs but does not throw); an `AWS/Lambda` `Errors` alarm catches thrown exceptions; a DLQ-depth alarm catches messages that exhausted `max_receive_count`. The `failed` count in the `INFO` summary line is deliberately not turned into a metric: positional text extraction from non-JSON logs is brittle, and a reported failure that keeps failing already surfaces via `ReportBatchItemFailures` -> redrive -> the DLQ alarm. If you want first-class partial-failure metrics, emit structured (JSON) logs and add a JSON metric filter.
- **CloudWatch capture needs stdout/stderr.** Container Lambdas only ship logs the runtime writes to stdout/stderr. If the image writes to a file on the ephemeral filesystem, those lines never reach the log group and none of the log-based alarming applies.

## Verification

```bash
cd terraform && terraform init -backend=false && terraform validate
terraform fmt -check -recursive
cd examples/minimal && terraform init && terraform plan
```

Then a manual smoke test against a sandbox: `aws sqs send-message ...`, follow the CloudWatch log group, force a failure to confirm the message lands in the DLQ after `max_receive_count` attempts.
