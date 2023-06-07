terraform {
    required_version = "~> 1.4.0"
  
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = ">= 4.21"
      }
    utils = {
      source = "cloudposse/utils"
      version = "1.8.0"
    }
  }
}