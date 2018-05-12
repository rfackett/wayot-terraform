variable "tags" {
  type = "map"

  default = {
    Environment = "wayot"
    Application = "search"
    CostCenter  = "ryan_fackett@yahoo.com"
    Terraform   = true
  }
}

variable "whitelist" {
  type = "list"

  default = [
    "69.222.185.243/32",
    "66.175.217.148/32",
    "198.27.103.16/32",
    "76.80.9.214/32"
  ]
}

data "aws_vpc" "default" {
  filter {
    name   = "tag:Name"
    values = ["default"]
  }
}

data "aws_subnet_ids" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_sns_topic" "slack" {
  name = "slack"
}

data "aws_ami" "wayot" {
  most_recent      = true
  owners     = ["835387872147"]

  filter {
    name   = "name"
    values = ["wayot_*"]
  }
}

module "alb" {
  source                   = "terraform-aws-modules/alb/aws"
  load_balancer_name       = "search"
  security_groups          = ["${aws_security_group.search_alb.id}"]
  log_bucket_name          = "wayot-backups"
  log_location_prefix      = "alb/search"
  subnets                  = "${data.aws_subnet_ids.default.ids}"
  tags                     = "${merge(var.tags, map("Name", "search"), map("Function", "alb"))}"
  vpc_id                   = "${data.aws_vpc.default.id}"
  https_listeners          = "${list(map("certificate_arn", "arn:aws:acm:us-west-2:835387872147:certificate/cfe3929a-ea07-4569-b232-fc9e66e2eff3", "port", 443))}"
  listener_ssl_policy_default               = "ELBSecurityPolicy-TLS-1-2-2017-01"
  https_listeners_count    = "1"
  http_tcp_listeners       = "${list(map("port", "80", "protocol", "HTTP"))}"
  http_tcp_listeners_count = "1"
  target_groups            = "${list(map("name", "search", "backend_protocol", "HTTP", "backend_port", "80", "health_check_path", "/search/"))}"
  target_groups_count      = "1"
}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"
  name = "search"
  asg_name = "search"

  # Launch configuration
  lc_name = "search"

  image_id        = "${data.aws_ami.wayot.id}"
  instance_type   = "t2.small"
  security_groups = ["${aws_security_group.search_lc.id}"]

  root_block_device = [
    {
      volume_size = "100"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                    = "search"
  vpc_zone_identifier         = "${data.aws_subnet_ids.default.ids}"
  health_check_type           = "EC2"
  min_size                    = 0
  max_size                    = 2
  desired_capacity            = 1
  wait_for_capacity_timeout   = 0
  associate_public_ip_address = true
  key_name                    = "search"
  # load_balancers              = ["${module.alb.load_balancer_id}"] --> ELB Classic
  target_group_arns           = ["${module.alb.target_group_arns}"]

  tags = [
    {
      key                 = "Environment"
      value               = "${var.tags["Environment"]}"
      propagate_at_launch = true
    },
    {
      key                 = "Application"
      value               = "${var.tags["Application"]}"
      propagate_at_launch = true
    },
    {
      key                 = "CostCenter"
      value               = "${var.tags["CostCenter"]}"
      propagate_at_launch = true
    },
    {
      key                 = "Function"
      value               = "ec2"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "search"
      propagate_at_launch = true
    },
  ]
}

resource "aws_security_group" "search_alb" {
  name        = "search-alb"
  description = "search alb"
  vpc_id      = "${data.aws_vpc.default.id}"
  tags        = "${merge(var.tags, map("Name", "search-alb"), map("Function", "alb"))}"
}

resource "aws_security_group_rule" "search_alb_80" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.search_alb.id}"
}

resource "aws_security_group_rule" "search_alb_443" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.search_alb.id}"
}

resource "aws_security_group_rule" "search_alb_80_app" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.search_lc.id}"

  security_group_id = "${aws_security_group.search_alb.id}"
}

resource "aws_security_group_rule" "search_alb_443_app" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.search_lc.id}"

  security_group_id = "${aws_security_group.search_alb.id}"
}

resource "aws_security_group" "search_lc" {
  name        = "search-ec2"
  description = "search launch configuration"
  vpc_id      = "${data.aws_vpc.default.id}"
  tags        = "${merge(var.tags, map("Name", "search-lc"), map("Function", "ec2"))}"
}

resource "aws_security_group_rule" "search_lc_80" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.search_alb.id}"

  security_group_id = "${aws_security_group.search_lc.id}"
}

resource "aws_security_group_rule" "search_lc_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.search_alb.id}"

  security_group_id = "${aws_security_group.search_lc.id}"
}

resource "aws_security_group_rule" "search_lc_22" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = "${var.whitelist}"

  security_group_id = "${aws_security_group.search_lc.id}"
}

resource "aws_security_group_rule" "search_lc_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.search_lc.id}"
}

resource "aws_security_group" "search_db" {
  name        = "search-db"
  description = "search database"
  vpc_id      = "${data.aws_vpc.default.id}"
  tags        = "${merge(var.tags, map("Name", "search-db"), map("Function", "rds"))}"
}

resource "aws_security_group_rule" "search_db_3306" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.search_lc.id}"

  security_group_id = "${aws_security_group.search_db.id}"
}

resource "aws_security_group_rule" "search_db_whitelist" {
  type        = "ingress"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = "${var.whitelist}"

  security_group_id = "${aws_security_group.search_db.id}"
}

resource "aws_autoscaling_notification" "asg_slack" {
  group_names = [
    "${module.asg.this_autoscaling_group_name}"
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
  ]

  topic_arn = "${data.aws_sns_topic.slack.arn}"
}

resource "aws_cloudwatch_metric_alarm" "alb_healthyhosts" {
  alarm_name  = "search-alb-healthy-hosts"
  alarm_actions     = [
    "${data.aws_sns_topic.slack.arn}"
  ]
  namespace   = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"

  dimensions = {
    LoadBalancer = "${module.alb.load_balancer_arn_suffix}"
  }

  statistic           = "Average"
  period              = 60
  comparison_operator = "LessThanThreshold"
  threshold           = "1"
  evaluation_periods  = 2
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name  = "search-alb-5xx"
  alarm_actions     = [
    "${data.aws_sns_topic.slack.arn}"
  ]
  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = "${module.alb.load_balancer_arn_suffix}"
  }

  statistic           = "Sum"
  period              = 60
  comparison_operator = "GreaterThanThreshold"
  threshold           = "10"
  evaluation_periods  = 2
}

resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  alarm_name  = "search-alb-target-5xx"
  alarm_actions     = [
    "${data.aws_sns_topic.slack.arn}"
  ]
  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"

  dimensions = {
    LoadBalancer = "${module.alb.load_balancer_arn_suffix}"
  }

  statistic           = "Sum"
  period              = 60
  comparison_operator = "GreaterThanThreshold"
  threshold           = "10"
  evaluation_periods  = 2
}

resource "aws_cloudwatch_metric_alarm" "alb_target_response" {
  alarm_name  = "search-alb-target-response"
  alarm_actions     = [
    "${data.aws_sns_topic.slack.arn}"
  ]
  namespace   = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"

  dimensions = {
    LoadBalancer = "${module.alb.load_balancer_arn_suffix}"
  }

  statistic           = "Average"
  period              = 60
  comparison_operator = "GreaterThanThreshold"
  threshold           = "10"
  evaluation_periods  = 2
}
