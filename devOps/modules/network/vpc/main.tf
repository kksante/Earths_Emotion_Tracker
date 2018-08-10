resource "aws_vpc" "project_vpc" {
  cidr_block = "${lookup(var.vpc_cidr_prefix, terraform.workspace)}.${lookup(var.vpc_cidr_suffix, terraform.workspace)}"
  instance_tenancy = "default"   # Instance runs on shared hardware
  enable_dns_support = "true"    # Amazon-provided DNS server enabled (default=true)
  enable_dns_hostnames = "true"  # Amazon-provided DNS hostnames enabled (default=false)
  enable_classiclink = "false"   # Do not allow EC2-classic instances (default=false)
  

  tags {
    Name = "${terraform.workspace}-vpc"
    Environment = "${terraform.workspace}"
  }
}
