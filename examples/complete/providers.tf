provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Environment = "prod"
      ManagedBy   = "terraform"
      Repo        = "ipp"
    }
  }
}
