terraform {
  backend "s3" {
    bucket       = "task-03-sai-terraform-state-20261019"
    key          = "terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}