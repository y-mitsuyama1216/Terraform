module "Budget" {
  source                    = "../../modules/Budget"
  dudget_name               = "Budget Usage"
  budget_type               = "COST"
  limit_amount              = "82"
  time_unit                 = "MONTHLY"
  threshold                 = "100"
  subscriber_sns_topic_arns = [module.SNS.topic_arn]

  depends_on = [module.SNS]
}

module "SNS" {
  source = "../../modules/SNS"
  # SNS_topic
  topic_name   = "Budget_SNS_topic"
  display_name = "Budget_SNS_topic"

  # SNS_topic_policy
  policy = data.template_file.policy.rendered

  #SNS_subscription_email
  endpoint = var.endpoint
}
