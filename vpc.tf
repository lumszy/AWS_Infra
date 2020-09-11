provider "aws" {
  access_key = "AKIATG6YZ72X4NJK45PO"
  secret_key = "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"
  region = "ca-central-1"
}



resource "aws_vpc" "testlab-vpc" {
  cidr_block            = "${var.vpc_cidr}"
  enable_dns_hostnames  = true
  enable_dns_support = true
  tags = {
    name = "testlab_VPC"
  }
}

resource "aws_subnet" "public-subnet-a" {
  cidr_block        = "${var.public_subnet_a_cidr}"
  vpc_id            = "${aws_vpc.testlab-vpc.id}"
  availability_zone = "ca-central-1a"
  map_public_ip_on_launch = "true"
  tags = {
    name = "public_subnet_A"
  }
 }



resource "aws_subnet" "private-subnet-a" {
  cidr_block = "${var.private_subnet_a_cidr}"
  vpc_id = "${aws_vpc.testlab-vpc.id}"
  map_public_ip_on_launch = "false"
  availability_zone = "ca-central-1a"

  tags = {
    name = "private_subnet_A"
  }
}


resource "aws_route_table" "public_route_a" {
  vpc_id = "${aws_vpc.testlab-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.testlab-igw.id}"
  }
}


resource "aws_route_table" "private_route_a" {
  vpc_id = "${aws_vpc.testlab-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.public_nat_a.id}"
  }
}

resource "aws_route_table_association" "public-subnet-A-association" {
  route_table_id = "${aws_route_table.public_route_a.id}"
  subnet_id = "${aws_subnet.public-subnet-a.id}"
}


resource "aws_route_table_association" "private-subnet-A-association" {
  route_table_id = "${aws_route_table.private_route_a.id}"
  subnet_id = "${aws_subnet.private-subnet-a.id}"
}


resource "aws_eip" "natgw_a" {
  vpc      = true
}


resource "aws_nat_gateway" "public_nat_a" {
  allocation_id = "${aws_eip.natgw_a.id}"
  subnet_id = "${aws_subnet.public-subnet-a.id}"
  depends_on = ["aws_internet_gateway.testlab-igw"]
}


resource "aws_network_acl" "all" {
  vpc_id = "${aws_vpc.testlab-vpc.id}"
  egress {
    protocol = "-1"
    rule_no = 2
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
  ingress {
    protocol = "-1"
    rule_no = 1
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
}


resource "aws_internet_gateway" "testlab-igw" {
  vpc_id = "${aws_vpc.testlab-vpc.id}"
}


resource "aws_security_group" "ec2_public_SG" {
  name = "EC2-Public-SG"
  description = "Security_group_for_web_server"
  vpc_id = "${aws_vpc.testlab-vpc.id}"

  ingress {
    from_port = 80
    protocol = "TCP"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    protocol = "TCP"
    to_port = 22
    cidr_blocks = [
      "0.0.0.0/0"]
    # put own ip here when demonstrating
  }


  //  ingress {
  //    from_port   = 0
  //    protocol    = "-1"
  //    to_port     = 0
  //    cidr_blocks = ["0.0.0.0/0"]
  //  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group" "ec2_private_SG" {
  name = "EC2-Private-SG"
  description = "Only allow public EC2 instances to access these instances"
  vpc_id = "${aws_vpc.testlab-vpc.id}"

  ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    security_groups = [
      "${aws_security_group.ec2_public_SG.id}"]
  }

  ingress {
    from_port = 80
    protocol = "TCP"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "Allow traffic for health checking, remember this doesnt allow public internet!"
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group" "elb_SG" {
    name = "ELB-SG"
    description = "ELB Security Group"

    vpc_id = "${aws_vpc.testlab-vpc.id}"

    ingress {
      from_port = 0
      protocol = "-1"
      to_port = 0
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow web traffic to Load balancer"
    }

    egress {
      from_port = 0
      protocol = "-1"
      to_port = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

resource "aws_iam_role" "ec2_iam_roles" {
    name               = "EC2-IAM-Role"
    assume_role_policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement":
  [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["ec2.amazonaws.com", "application-autoscaling.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  }

resource "aws_iam_role_policy" "ec2_iam_role_py" {
    name = "EC2-IAM-Role-Policy"
    role = "${aws_iam_role.ec2_iam_roles.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "cloudwatch:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
  }

resource "aws_iam_instance_profile" "ec2_instance-profile" {
    name = "EC2-IAM-Instance_profile"
    role = "${aws_iam_role.ec2_iam_roles.name}"
  }

resource "aws_launch_configuration" "ec2-private_launch_config" {
    image_id = "${lookup(var.amis, var.region)}"
    instance_type = "${var.ec2_instance_type}"
    key_name = "${var.key_pair_name}"
    associate_public_ip_address = true
    iam_instance_profile = "${aws_iam_instance_profile.ec2_instance-profile.name}"
    security_groups = ["${aws_security_group.elb_SG.id}"]

  user_data = "${file("userdata.sh")}"

  }

resource "aws_elb" "webapp_load_balancer" {
    name = "Webserver-load-balancer"
    security_groups = ["${aws_security_group.ec2_public_SG.id}"]
    subnets = [
      "${aws_subnet.public-subnet-a.id}",
      ]

    listener {
      instance_port      = 80
      instance_protocol  = "http"
      lb_port            = 80
      lb_protocol        = "http"
    }

    health_check {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 3
      target              = "HTTP:80/index.html"
      interval            = 30
    }

    cross_zone_load_balancing = true
    idle_timeout = 400
    connection_draining = true
    connection_draining_timeout = 400

    tags = {
      Name = "Webserver-elb"
    }
  }

resource "aws_autoscaling_group" "ec2_private_autoscale_group" {
    name = "backend_autoscalingGroup"
    vpc_zone_identifier =  ["${aws_subnet.private-subnet-a.id}"]
    max_size = "${var.max_instance_size}"
    min_size = "${var.min_instance_size}"
    launch_configuration = "${aws_launch_configuration.ec2-private_launch_config.name}"
    health_check_type = "ELB"
    load_balancers = ["${aws_elb.webapp_load_balancer.name}"]

    tag {
      key = "Name"
      value = "backend-EC2_Instance"
      propagate_at_launch = false
    }
    tag {
      key = "Type"
      value = "Backend"
      propagate_at_launch = false
    }
  }


  resource "aws_autoscaling_policy" "webserver_autoscaling_policy" {
    name                   = "Webserver-autoscaling-Policy"
    policy_type            = "TargetTrackingScaling"
    autoscaling_group_name = "${aws_autoscaling_group.ec2_private_autoscale_group.name}"
    min_adjustment_magnitude = 1

    target_tracking_configuration {
      predefined_metric_specification{
        predefined_metric_type = "ASGAverageCPUUtilization"
      }
      target_value = 80.0
    }
  }


resource "aws_lb" "alb" {
  name            = "alb"
  subnets         = "${aws_subnet.public-subnet-a.*.id}"
  security_groups = ["${aws_security_group.ec2_public_SG.id}"]
  internal        = false
  idle_timeout    = 60

}

resource "aws_lb" "network_lb" {
  name               = "nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = "${aws_subnet.public-subnet-a.*.id}"
  enable_cross_zone_load_balancing  = true
}


resource "aws_lb_target_group" "alb_target_group" {
  name     = "alb-target-group"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.testlab-vpc.id}"

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 1800
    enabled         = true
  }
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = 80
  }
}

resource "aws_lb_target_group" "nlb_target_group" {
  name     = "nlb-target-group"
  port     = "80"
  protocol = "TCP"
  vpc_id   = "${aws_vpc.testlab-vpc.id}"
  target_type = "instance"

}


resource "aws_autoscaling_attachment" "alb_public_autoscale" {
  alb_target_group_arn   = "${aws_lb_target_group.alb_target_group.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.ec2_private_autoscale_group.id}"
}

resource "aws_autoscaling_attachment" "nlb_autoscale" {
  alb_target_group_arn   = "${aws_lb_target_group.nlb_target_group.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.ec2_private_autoscale_group.id}"
}
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.alb_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = "${aws_lb.network_lb.arn}"
  port              = 80
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.nlb_target_group.arn}"
    type             = "forward"
  }
}


