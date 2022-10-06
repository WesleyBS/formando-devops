terraform {
  required_providers {
    kind = {
      source = "kyma-incubator/kind"
      version = "0.0.11"
    }
  }
}

provider "kind" {
  # Configuration options
}
/*
terraform {
  backend "s3" {
    bucket = "desafio-terraform-wesley"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
*/