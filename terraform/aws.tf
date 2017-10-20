provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us-east"
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "dan.carley.co-tf"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
