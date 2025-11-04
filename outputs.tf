output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "cloudfront_domain_name" {
  value = module.s3_cloudfront.cloudfront_domain
}

output "asg_name" {
  value = module.compute.asg_name
}
