provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
      Repo        = "ipp"
    }
  }
}
