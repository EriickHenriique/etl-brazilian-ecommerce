#Configuração Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Variáveis
variable "aws_region" { type = string }
variable "db_name" { type = string }
variable "db_user" { type = string }
variable "allowed_cidr" { type = string }
variable "allowed_ssh_cidr" { type = string }
variable "key_pair_name" { type = string }


# Configuração da Região
provider "aws" {
  region = var.aws_region
}

# Sufixo aleatório para o nome do bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Bucket
resource "aws_s3_bucket" "example" {
  bucket        = "orders-ecommerce-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "Ecommerce"
    Environment = "Dev"
  }
}

# VPC com subnets públicas
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "rds-public-vpc"
  cidr = "10.10.0.0/16"

  azs            = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets = ["10.10.101.0/24", "10.10.102.0/24"]


  private_subnets    = []
  enable_nat_gateway = false
  single_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true
}

# RDS 
resource "aws_security_group" "rds" {
  name        = "rds-postgres-public-sg"
  description = "Public Postgres (0.0.0.0/0)"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Subnet group usando subnets públicas
resource "aws_db_subnet_group" "this" {
  name       = "rds-public-subnet-group"
  subnet_ids = module.vpc.public_subnets
}

# Senha forte aleatória
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&'()*+,-.:;<=>?[]^_{|}~"
}

# RDS PostgreSQL público 
resource "aws_db_instance" "postgres" {
  identifier = "rds-public-postgres"

  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_user
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = true
  multi_az            = false


  backup_retention_period  = 0
  delete_automated_backups = true
  deletion_protection      = false
  skip_final_snapshot      = true


  storage_encrypted = true

  apply_immediately = true
}

resource "aws_security_group" "ec2" {
  name        = "ec2-airflow-sg"
  description = "EC2 Airflow"
  vpc_id      = module.vpc.vpc_id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Airflow Webserver
  ingress {
    description = "Airflow Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


resource "aws_instance" "airflow" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.key_pair_name

  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2.id]

  associate_public_ip_address = true

  user_data = file("user_data.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "airflow-ec2"
    Env  = "dev"
  }
}



output "bucket_name" {
  value = aws_s3_bucket.example.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "rds_port" {
  value = aws_db_instance.postgres.port
}

output "db_name" {
  value = aws_db_instance.postgres.db_name
}

output "db_user" {
  value = aws_db_instance.postgres.username
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}

output "ec2_public_ip" {
  value = aws_instance.airflow.public_ip
}

output "ec2_ssh" {
  value = "ssh ubuntu@${aws_instance.airflow.public_ip}"
}
