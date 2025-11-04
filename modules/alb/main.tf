resource "aws_security_group" "alb_sg" {
  name = "${var.project}-alb-sg-${var.environment}"
  vpc_id = var.vpc_id
  description = "Allow HTTP/HTTPS from internet"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "${var.project}-alb-sg" })
}

resource "aws_lb" "alb" {
  name = "${var.project}-alb-${var.environment}"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets = var.public_subnets
  tags = merge(var.common_tags, { Name = "${var.project}-alb" })
}

resource "aws_lb_target_group" "tg" {
  name = "${var.project}-tg-${var.environment}"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
  health_check {
    path = "/"
    protocol = "HTTP"
  }
  tags = var.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Optional HTTPS listener (created only if an ACM cert ARN is provided)
resource "aws_lb_listener" "https" {
  count = var.acm_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.acm_certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# If HTTPS exists, redirect HTTP to HTTPS instead of forwarding
resource "aws_lb_listener_rule" "http_redirect" {
  count = var.acm_certificate_arn != "" ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}