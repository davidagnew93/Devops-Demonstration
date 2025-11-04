module "vpc" {
  source      = "./modules/vpc"
  common_tags = var.common_tags
  project     = var.project
  environment = var.environment
}

module "alb" {
  source              = "./modules/alb"
  vpc_id              = module.vpc.vpc_id
  public_subnets      = module.vpc.public_subnets
  common_tags         = var.common_tags
  project             = var.project
  environment         = var.environment
  acm_certificate_arn = var.acm_certificate_arn
}

module "compute" {
  source               = "./modules/compute"
  vpc_id               = module.vpc.vpc_id
  private_subnets      = module.vpc.private_subnets
  alb_target_group_arn = module.alb.target_group_arn
  alb_sg_id            = module.alb.alb_sg_id
  instance_type        = var.instance_type
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  desired_capacity     = var.desired_capacity
  common_tags          = var.common_tags
  project              = var.project
  environment          = var.environment
}

module "rds" {
  source                  = "./modules/rds"
  vpc_id                  = module.vpc.vpc_id
  private_subnets         = module.vpc.private_subnets
  db_username             = var.db_username
  db_password             = var.db_password
  db_engine               = var.db_engine
  db_engine_version       = var.db_engine_version
  db_instance_class       = var.db_instance_class
  db_allocated_storage    = var.db_allocated_storage
  common_tags             = var.common_tags
  project                 = var.project
  environment             = var.environment
  allowed_security_groups = [module.compute.ec2_sg_id]
}

module "s3_cloudfront" {
  source      = "./modules/s3_cloudfront"
  common_tags = var.common_tags
  project     = var.project
  environment = var.environment
}

# CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "ec2_high_cpu" {
  alarm_name          = "ec2-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  dimensions = {
    AutoScalingGroupName = module.compute.asg_name
  }
  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_low_free_storage" {
  alarm_name          = "rds-low-free-storage-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_id
  }
  tags = var.common_tags
}
