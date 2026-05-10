terraform {
  backend "s3" {
    bucket       = "rizal-tfstate-devsecops"
    key          = "dev/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}
