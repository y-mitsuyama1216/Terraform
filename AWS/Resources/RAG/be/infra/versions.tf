terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    opensearch = {
      source = "opensearch-project/opensearch"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 1.11.0"
  backend "s3" {
    bucket       = "s3-terraform-state-y-mitsuyama"
    region       = "ap-northeast-1"
    key          = "rag-be.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
