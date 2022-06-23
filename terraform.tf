terraform {
  required_version = ">=1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=3.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">=3.0.0"
    }

  }
  backend "s3" {
    bucket         = "terraform-stlck"
    key            = "remote/states"
    region         = "ap-southeast-1"
    dynamodb_table = "demo"
    encrypt        = true
  }
}