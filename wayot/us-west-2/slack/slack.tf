variable "tags" {
  type = "map"

  default = {
    Environment = "aws"
    Application = "slack"
    CostCenter  = "ryan_fackett@yahoo.com"
    Terraform   = true
  }
}

module "notify_slack" {
  source = "terraform-aws-modules/notify-slack/aws"

  sns_topic_name = "slack"

  slack_webhook_url = "https://hooks.slack.com/services/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"
  slack_channel     = "aws"
  slack_username    = "aws"
}
