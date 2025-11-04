# Terraform — Scalable Web Stack on AWS

## Overview

This Terraform configuration deploys a **scalable, secure, and modular web application stack on AWS**.  
It provisions infrastructure that is highly available, cost-effective, and aligned with AWS best practices.

### Stack Components
- **VPC** with isolated public and private subnets across Availability Zones  
- **Application Load Balancer (ALB)** with optional HTTPS (ACM certificate)  
- **Auto Scaling Group (ASG)** of EC2 instances serving an Nginx-based web app  
- **RDS MySQL** instance deployed in private subnets  
- **S3 bucket** for static assets served via **CloudFront CDN**  
- **CloudWatch alarms** for monitoring EC2 CPU and RDS storage  

All resources are tagged consistently and follow the principle of least privilege.

**Region:** `eu-west-1`  
**Database Engine:** MySQL  
**Terraform Version:** >= 1.0

---

## High-Level Architecture

### Diagram

![Architecture Diagram](architecture_diagram_monochrome.png)

### Description

#### 1. Networking (VPC)
- CIDR block: `10.0.0.0/16`
- **2 public subnets**: For the ALB and NAT Gateway
- **2 private subnets**: For EC2 instances and RDS
- **Routing**:  
  - Public subnets route to Internet Gateway (IGW)  
  - Private subnets route through NAT Gateway for outbound internet access
- **High availability**: Subnets distributed across Availability Zones  

#### 2. Compute (Auto Scaling Group)
- EC2 instances (Amazon Linux 2) in private subnets
- Uses a Launch Template and an ASG for scalability
- User data installs and runs Nginx:
  ```bash
  yum install -y nginx
  echo "<h1>Hello from Terraform</h1>" > /usr/share/nginx/html/index.html
  systemctl enable nginx && systemctl start nginx
  ```
- Configurable instance type (default `t3.micro`)
- Scaling parameters:
  - `asg_min_size` = 1  
  - `asg_max_size` = 3  
  - `desired_capacity` = 1  

#### 3. Load Balancing (ALB)
- Public Application Load Balancer  
- Listens on **port 80** (HTTP)  
- Optionally listens on **port 443 (HTTPS)** if `acm_certificate_arn` is provided  
- Health check: `/`
- Redirects HTTP → HTTPS when a certificate ARN is present  
- ALB Security Group allows only inbound 80/443 from the internet  

#### 4. Database (RDS)
- MySQL 8.0 database in private subnets  
- Security Group allows connections only from EC2 SG  
- Not publicly accessible  
- Configurable parameters:
  - Engine version, instance class, allocated storage, username/password  
- Default instance class: `db.t3.micro`  
- Skips final snapshot for simplicity (change for production)

#### 5. Static Assets (S3 + CloudFront)
- Private S3 bucket (`scalable-web-stack-assets-dev`)
- CloudFront CDN distributes static assets globally
- Origin Access Identity (OAI) ensures CloudFront-only access to S3
- Default viewer protocol policy: `allow-all` (can be adjusted)

#### 6. Monitoring (CloudWatch)
- `ec2-high-cpu`: CPU > 70% across ASG
- `rds-low-free-storage`: free storage < 10 GiB

---

## Project Structure

```
terraform_devops_full/
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
├── terraform.tfvars
├── modules/
│   ├── vpc/
│   ├── alb/
│   ├── compute/
│   ├── rds/
│   └── s3_cloudfront/
└── architecture_diagram_monochrome.png
```

Each module is standalone and reusable.

---

## Deployment Instructions

### 1. Prerequisites

- **Terraform >= 1.0**
- **AWS CLI** configured with credentials that can create:
  - VPC, EC2, RDS, ALB, IAM, CloudFront, and S3 resources
- **Backend** for Terraform state:
  - S3 bucket (for storing state, currently disabled)
  - DynamoDB table (for state locking. currently disabled)

To create these:

```bash
aws s3api create-bucket   --bucket <your-terraform-state-bucket>   --region eu-west-1   --create-bucket-configuration LocationConstraint=eu-west-1

aws dynamodb create-table   --table-name <your-dynamodb-lock-table>   --attribute-definitions AttributeName=LockID,AttributeType=S   --key-schema AttributeName=LockID,KeyType=HASH   --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### 2. Configure Variables

Copy and edit the example variable file:

```bash
cp terraform.tfvars terraform.tfvars.backup
```

Edit `terraform.tfvars` to use any variables required


### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan -out plan.tfplan
```

### 5. Apply the Configuration

```bash
terraform apply "plan.tfplan"
```

### 6. Destroy Resources (Cleanup)

```bash
terraform destroy
```

---

## Design Decisions

### Modular Architecture
Each major infrastructure component resides in its own module:
- `vpc` → Networking, subnets, gateways, routes  
- `alb` → Load balancer and listeners  
- `compute` → EC2 ASG, Launch Template, user data  
- `rds` → MySQL instance, subnet group, security group  
- `s3_cloudfront` → Static assets and CDN  

This makes the project scalable, maintainable, and easier to test or reuse.

### Security
- **Private subnets:** EC2 and RDS not publicly accessible  
- **Security Groups:**  
  - ALB → EC2: port 80/443 only  
  - EC2 → RDS: port 3306 only  
- **IAM & least privilege:** minimal access defined per resource  
- **Terraform state:** stored securely in S3 with DynamoDB state locking  
- **HTTPS-ready:** enable by providing `acm_certificate_arn`  

### Scaling
- Horizontal scaling via ASG configuration (min/max/desired)
- Load balancing distributes incoming traffic
- CloudWatch metrics enable autoscaling triggers (extendable)

### Observability
- CloudWatch alarms monitor critical metrics:
  - High CPU usage on EC2
  - Low storage on RDS
- Outputs surface critical endpoints (ALB, RDS, CloudFront)

### Reliability
- Multi-AZ design for redundancy
- NAT Gateway ensures private subnet internet access
- Default configuration is lightweight for testing; scalable for production

---

## Outputs

| Output Name             | Description                                         |
|--------------------------|-----------------------------------------------------|
| `alb_dns_name`           | Public DNS name of the Application Load Balancer    |
| `rds_endpoint`           | Endpoint address of the RDS instance                |
| `cloudfront_domain_name` | CloudFront CDN domain for static assets             |
| `asg_name`               | Name of the Auto Scaling Group                      |

Example after deployment:
```bash
alb_dns_name           = scalable-web-stack-alb-dev-123456.eu-west-1.elb.amazonaws.com
rds_endpoint           = scalable-web-stack-db-dev.xxxxxx.eu-west-1.rds.amazonaws.com
cloudfront_domain_name = d12345abcdef.cloudfront.net
asg_name               = scalable-web-stack-asg-dev
```

---

## Notes

- **HTTPS:** To enable HTTPS, request or import an ACM certificate in `eu-west-1` and set its ARN in `terraform.tfvars`.
- **Database security:** Never commit plaintext passwords. Use environment variables or a secrets manager.
- **RDS Snapshots:** Disabled for simplicity — enable `final_snapshot_identifier` for production.
- **Cost Warning:** This infrastructure creates billable AWS resources (EC2, RDS, NAT Gateway, CloudFront, etc.).  
  Run `terraform destroy` after testing to avoid ongoing charges.
- **Custom Scaling:** Add scaling policies triggered by CloudWatch alarms for true elasticity.

---

## Example Commands

```bash
# Initialize project
terraform init

# Check what will be created
terraform plan

# Deploy
terraform apply -auto-approve

# Retrieve key outputs
terraform output

# Destroy everything
terraform destroy
```

---

**Author:** David Agnew — Scalable AWS Infrastructure  
**Region:** eu-west-1  
**Maintainer:** David Agnew 
