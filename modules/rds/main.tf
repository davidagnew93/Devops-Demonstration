resource "aws_db_subnet_group" "default" {
  name = "${var.project}-db-subnet-group"
  subnet_ids = var.private_subnets
  tags = merge(var.common_tags, { Name = "${var.project}-db-subnet-group" })
}

resource "aws_security_group" "rds" {
  name = "${var.project}-rds-sg-${var.environment}"
  vpc_id = var.vpc_id
  tags = merge(var.common_tags, { Name = "${var.project}-rds-sg" })
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = var.allowed_security_groups
    description = "Allow MySQL from EC2"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "db" {
  identifier = "${var.project}-db-${var.environment}"
  allocated_storage = var.db_allocated_storage
  engine = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  db_name = "${var.db_name}db"
  username = var.db_username
  password = var.db_password
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot = true
  publicly_accessible = false
  tags = merge(var.common_tags, { Name = "${var.project}-rds" })
}

output "endpoint" {
  value = aws_db_instance.db.address
}

output "db_instance_id" {
  value = aws_db_instance.db.id
}
