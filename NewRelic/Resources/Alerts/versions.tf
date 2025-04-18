terraform {
  required_version = ">= 1.9.0"
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = ">= 3.45.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.68.0"
    }
  }

  backend "s3" {
    bucket       = "s3-terraform-state-y-mitsuyama"
    region       = "ap-northeast-1"
    key          = "newrelic-alerts.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
