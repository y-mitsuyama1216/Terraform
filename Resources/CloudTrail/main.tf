provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  required_version = ">= 0.13.0"
  backend "s3" {
    bucket         = "s3-terraform-state-ym"
    region         = "ap-northeast-1"
    key            = "CloudTrail.tfstate"
    encrypt        = true
    dynamodb_table = "terrform-state"
  }
}

data "aws_caller_identity" "current" {}

data "template_file" "policy" {
  template = file("./Policy.json.tpl")

  vars = {
    account_id = data.aws_caller_identity.current.account_id
  }
}

module "CloudTrail" {
  source = "../../modules/Trail"
  # trail
  cloudtrailname                = "Main-Trail"
  is_multi_region_trail         = "true"
  include_global_service_events = "true"
  read_write_type               = "All"
  include_management_events     = "true"

  # s3
  bucketname      = "cloudtrail-bucket-ym"
  policy          = data.template_file.policy.rendered
  id              = "cloudtrail-lifecycle"
  expiration_days = 31
  status          = "Enabled"
}

