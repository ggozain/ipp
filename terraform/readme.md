# aws-lambda-sqs

Reusable Terraform module for an SQS-triggered container Lambda function, watered down from the `Platform.Terraform.AWS.Batch` repo layout so it can be consumed outside the e-star platform (no Vault, no Harbor, no TFC backend; only `hashicorp/aws` and public `terraform-aws-modules/*`).

## What it creates per function

- AWS Lambda function in `Image` package mode pointing at an ECR image you already pushed.
- SQS source queue + SQS DLQ, both KMS-encrypted, redrive policy wired.
- Lambda event source mapping (SQS -> Lambda) with `ReportBatchItemFailures` partial-batch handling.
- IAM execution role with `AWSLambdaBasicExecutionRole`, SQS consume policy, optional `AWSLambdaVPCAccessExecutionRole`, plus any extra policy ARNs or inline statements you pass.
- CloudWatch log group pre-created with retention (so retention applies from the first invocation).
- Optional VPC attachment with a default egress-443 security group (the function "sends outgoing requests to the internet", so this is the easy thing to forget when adopters move into a VPC).

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
| `vpc_config` | no | `null` | Object `{ vpc_id, subnet_ids, security_group_ids }`. Triggers VPC attachment + `AWSLambdaVPCAccessExecutionRole` + the egress-443 helper SG. |
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

## Verification

```bash
cd terraform && terraform init -backend=false && terraform validate
terraform fmt -check -recursive
cd examples/minimal && terraform init && terraform plan
```

Then a manual smoke test against a sandbox: `aws sqs send-message ...`, follow the CloudWatch log group, force a failure to confirm the message lands in the DLQ after `max_receive_count` attempts.

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
