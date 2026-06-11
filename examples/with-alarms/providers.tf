provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = lower(var.tag_environment)
      ManagedBy   = "terraform"
      Repo        = "ipp"
    }
  }
}
