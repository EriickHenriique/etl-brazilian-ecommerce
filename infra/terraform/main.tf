#Configuração Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
}

# Configuração da Região
provider "aws" {
  region = "us-east-1"
}

#Bucket
resource "aws_s3_bucket" "example" {
  bucket = "orders-ecommerce"

  tags = {
    Name        = "Ecommerce"
    Environment = "Dev"
  }
}