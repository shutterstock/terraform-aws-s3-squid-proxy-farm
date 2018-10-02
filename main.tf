data "template_file" "user_data" {
  template = "${file(join("/", list(path.module, "user_data.sh")))}"

  vars {
    proxy_port         = "${var.proxy_port}"
    proxy_allowed_cidr = "${var.proxy_allowed_cidr}"
  }
}

resource "tls_private_key" "squid" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "squid" {
  key_name   = "squid-s3-proxy-${var.environment}"
  public_key = "${tls_private_key.squid.public_key_openssh}"
}

resource "aws_security_group" "instance" {
  name   = "squid-s3-proxy-instance-${var.environment}"
  vpc_id = "${var.vpc_id}"

  # ping
  ingress {
    from_port   = 0
    to_port     = 8
    protocol    = "icmp"
    cidr_blocks = ["${var.ssh_allowed_cidr}"]
  }

  # ssh
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = ["${var.ssh_allowed_cidr}"]
  }

  # squid
  ingress {
    from_port   = "${var.proxy_port}"
    to_port     = "${var.proxy_port}"
    protocol    = "TCP"
    cidr_blocks = ["${var.proxy_allowed_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${var.egress_allowed_cidr}"]
  }
}

resource "aws_launch_configuration" "squid" {
  name_prefix                 = "squid-s3-proxy-${var.environment}-"
  image_id                    = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  associate_public_ip_address = false
  key_name                    = "${aws_key_pair.squid.key_name}"
  security_groups             = ["${aws_security_group.instance.id}"]

  user_data = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "squid" {
  name                 = "squid-s3-proxy-${var.environment}"
  launch_configuration = "${aws_launch_configuration.squid.name}"
  vpc_zone_identifier  = ["${var.subnet_ids}"]

  health_check_type = "ELB"

  target_group_arns = [
    "${aws_lb_target_group.http.arn}",
  ]

  lifecycle {
    create_before_destroy = true
  }

  min_size = "${var.min_size}"
  max_size = "${var.max_size}"

  enabled_metrics = ["${list("GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances")}"]

  tags = ["${data.null_data_source.squid_tag_list.*.outputs}"]
}

# auto scale up policy
resource "aws_autoscaling_policy" "squid_up" {
  name                   = "squid-s3-proxy-${var.environment}-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.squid.name}"
}

# auto scale down policy
resource "aws_autoscaling_policy" "squid_down" {
  name                   = "squid-s3-proxy-${var.environment}-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.squid.name}"
}

resource "aws_cloudwatch_metric_alarm" "squid_up" {
  alarm_name          = "squid-s3-proxy-${var.environment}-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Check whether EC2 instance CPU utilisation is over 80% on average"
  alarm_actions       = ["${aws_autoscaling_policy.squid_up.arn}"]

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.squid.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "squid_down" {
  alarm_name          = "squid-s3-proxy-${var.environment}-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "Check whether EC2 instance CPU utilisation is under 20% on average"
  alarm_actions       = ["${aws_autoscaling_policy.squid_down.arn}"]

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.squid.name}"
  }
}

resource "aws_lb" "squid" {
  name                             = "squid-s3-proxy-${var.environment}"
  internal                         = true
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  subnets                          = ["${var.subnet_ids}"]
}

resource "aws_lb_target_group" "http" {
  name     = "squid-s3-proxy-${var.environment}-http"
  protocol = "TCP"
  port     = 3128
  vpc_id   = "${var.vpc_id}"
  tags     = "${data.null_data_source.squid_merged_tags.outputs}"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.squid.arn}"
  protocol          = "TCP"
  port              = 80

  default_action {
    target_group_arn = "${aws_lb_target_group.http.arn}"
    type             = "forward"
  }
}
