terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 1.9.5"
  backend "s3" {
    bucket       = "s3-terraform-state-y-mitsuyama"
    region       = "ap-northeast-1"
    key          = "EKS.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
