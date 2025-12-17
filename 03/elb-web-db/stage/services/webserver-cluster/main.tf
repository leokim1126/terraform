terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

data "terraform_remote_state" "myremotestate" {
    backend = "s3"

    config = {
      bucket = "myysk-0215"
      key = "global/s3/terraform.tfstate"
      region = "us-east-2"
      dynamodb_table = "mylocktable"
    }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "myLTSG" {
  name        = "myLTSG"
  description = "Allow TLS inbound 80/tcp traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myLTSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myLTSG-in-80" {
  security_group_id = aws_security_group.myLTSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "myLTSG-out-all" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

data "aws_ami" "amazon2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.9.*.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

resource "aws_launch_template" "myLT" {
  name = "myLT"
  image_id = data.aws_ami.amazon2023.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.myLTSG.id]
  user_data = base64encode(templatefile("./user_data.sh", {
    dbaddress = data.terraform_remote_state.myremotestate.outputs.dbaddress,
    dbport = data.terraform_remote_state.myremotestate.outputs.dbport,
    dbname = data.terraform_remote_state.myremotestate.outputs.dbname
  }))
}

resource "aws_lb_target_group" "myALBTG" {
  name     = "myALBTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_autoscaling_group" "myASG" {
  name                      = "myASG"
  desired_capacity_type     = 2
  max_size                  = 2
  min_size                  = 2

  target_group_arns = [aws_lb_target_group.myALBTG.arn]
  depends_on = [ aws_lb_target_group.myALBTG ]

  health_check_grace_period = 300
  health_check_type         = "ELB"

  force_delete              = true
  vpc_zone_identifier       = data.aws_subnets.default.ids

    launch_template {
    id      = aws_launch_template.myLT.id
    version = "$Latest"
  }

  tag {
    key                 = "name"
    value               = "myASG"
    propagate_at_launch = false
  }
}

resource "aws_lb" "myALB" {
  name               = "myALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = true
}

resource "aws_lb_listener" "myALB-listener" {
  load_balancer_arn = aws_lb.myALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

resource "aws_lb_listener_rule" "myALB-listener-rule" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.static.arn
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }

  condition {
    host_header {
      values = ["example.com"]
    }
  }
}