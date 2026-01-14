########################################################
# Remote state backend
########################################################

terraform {
  backend "s3" {
    bucket         = "vllm-platform-tfstate"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "vllm-platform-tf-locks"
    encrypt        = true
  }
}
