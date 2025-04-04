terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 1.11.0"
  backend "s3" {
    bucket       = "s3-terraform-state-y-mitsuyama"
    region       = "ap-northeast-1"
    key          = "answer-user-query.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
