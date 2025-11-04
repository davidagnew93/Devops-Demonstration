resource "aws_security_group" "ec2" {
  name = "${var.project}-ec2-sg-${var.environment}"
  vpc_id = var.vpc_id
  description = "Allow outbound and ALB inbound"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [var.alb_sg_id]
    description = "Allow HTTP from ALB"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "${var.project}-ec2-sg" })
}

data "aws_ami" "amzn2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "template_file" "user_data" {
  template = <<-EOF
#!/bin/bash
yum update -y
yum install -y nginx
cat > /usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html>
  <head><title>Hello</title></head>
  <body><h1>Hello from Terraform (HTTPS if enabled)</h1></body>
</html>
HTML
systemctl enable nginx
systemctl start nginx
EOF
}

resource "aws_launch_template" "lt" {
  name_prefix = "${var.project}-lt-"
  image_id = data.aws_ami.amzn2.id
  instance_type = var.instance_type
  user_data = base64encode(data.template_file.user_data.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, { Name = "${var.project}-instance" })
  }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "${var.project}-asg-${var.environment}"
  max_size             = var.asg_max_size
  min_size             = var.asg_min_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.private_subnets

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [var.alb_target_group_arn]

  # Static tag
  tag {
    key                 = "Name"
    value               = "${var.project}-asg-instance"
    propagate_at_launch = true
  }

  # Dynamic tags from var.common_tags
  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # Ensure ASG waits for LT to be created
  depends_on = [aws_launch_template.lt]
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}

output "ec2_sg_id" {
  value = aws_security_group.ec2.id
}
