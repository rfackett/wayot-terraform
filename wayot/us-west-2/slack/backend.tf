terraform {
  backend "s3" {
    bucket  = "wayot-resources"
    key     = "terraform/slack.terraform"
    region  = "us-west-2"
    profile = "wayot"
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "wayot"
}
