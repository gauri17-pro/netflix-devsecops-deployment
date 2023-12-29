terraform {
  backend "s3" {
    bucket = "myeksbucket01"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}