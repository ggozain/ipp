# Convenience SG attached only when the function is configured for VPC (vpc_name set).
# Adds egress to 0.0.0.0/0 on 443 so a VPC-attached Lambda can still reach the public
# internet through a NAT gateway. The VPC is the one discovered by tag:Name = vpc_name.
module "security_group_egress_https" {

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"

  for_each = {
    for function in local.lambda_functions : "${local.current_region}.${function.name}" => function
    if function.vpc_name != null
  }

  name            = "${var.service_short_code}-${each.value.name}-egress-https"
  use_name_prefix = false
  description     = "Egress 443 to the internet for the ${each.value.name} Lambda function"
  vpc_id          = data.aws_vpc.this["${local.current_region}.${each.value.name}"].id

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["https-443-tcp"]

  tags = merge(local.repo_default_tags, each.value.tags)
}
