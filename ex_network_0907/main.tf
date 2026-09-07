resource "aws_vpc" "std09-lab-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "std09-lab-vpc"
  }
}
