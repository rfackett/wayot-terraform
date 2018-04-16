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
    "69.222.185.243/32"
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

module "alb" {
  source                        = "terraform-aws-modules/alb/aws"
  load_balancer_name            = "search"
  security_groups               = ["${var.aws_security_group.search_alb.id}"]
  log_bucket_name               = "wayot-backups"
  log_location_prefix           = "alb/search"
  subnets                       = "${data.aws_subnet_ids.default.ids}"
  tags                          = "${merge(var.tags, map("Name", "search"), map("Function", "alb"))}"
  vpc_id                        = "${data.aws_vpc.default.id}"
  https_listeners               = "${list(map("certificate_arn", "arn:aws:acm:us-west-2:835387872147:certificate/cfe3929a-ea07-4569-b232-fc9e66e2eff3", "port", 443))}"
  https_listeners_count         = "1"
  http_tcp_listeners            = "${list(map("port", "80", "protocol", "HTTP"))}"
  http_tcp_listeners_count      = "1"
  target_groups                 = "${list(map("name", "search", "backend_protocol", "HTTP", "backend_port", "80"))}"
  target_groups_count           = "1"
}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  asg_name = "search"

  # Launch configuration
  lc_name = "search"

  image_id        = "ami-4e79ed36"
  instance_type   = "t2.medium"
  security_groups = ["${var.aws_security_group.search_lc}"]

  root_block_device = [
    {
      volume_size = "100"
      volume_type = "gp2"
    }
  ]

  # Auto scaling group
  asg_name                  = "search"
  vpc_zone_identifier       = "${data.aws_subnet_ids.default.ids}"
  health_check_type         = "ELB"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  associate_public_ip_address = true
  key_name = "search"
  load_balancers = ["${module.alb.load_balancer_id}"]

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
    }
  ]
}

resource "aws_security_group" "search_alb" {
  name        = "search"
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
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  source_security_group_id  = "${aws_security_group.search_lc.id}"

  security_group_id = "${aws_security_group.search_alb.id}"
}

resource "aws_security_group_rule" "search_alb_443_app" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  source_security_group_id  = "${aws_security_group.search_lc.id}"

  security_group_id = "${aws_security_group.search_alb.id}"
}

resource "aws_security_group" "search_lc" {
  name        = "search"
  description = "search launch configuration"
  vpc_id      = "${data.aws_vpc.default.id}"
  tags        = "${merge(var.tags, map("Name", "search-lc"), map("Function", "ec2"))}"
}

resource "aws_security_group_rule" "search_lc_80" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  source_security_group_id  = "${aws_security_group.search_alb.id}"

  security_group_id = "${aws_security_group.search_lc.id}"
}

resource "aws_security_group_rule" "search_lc_443" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  source_security_group_id  = "${aws_security_group.search_alb.id}"

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
  name        = "search"
  description = "search database"
  vpc_id      = "${data.aws_vpc.default.id}"
  tags        = "${merge(var.tags, map("Name", "search-db"), map("Function", "rds"))}"
}

resource "aws_security_group_rule" "search_db_3306" {
  type        = "ingress"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  source_security_group_id  = "${aws_security_group.search_lc.id}"

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
