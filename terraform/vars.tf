# AWS Region
variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}

variable "keypair_name" {
	description = "The name of your pre-made key-pair in Amazon (e.g. kksante-IAM-keypair )"
  default = "kksante-IAM-keypair"
}

variable "fellow_name" {
  description = "The name that will be tagged on your resources."
  default = "kksante"
}

variable "amis" {
  type = "map"
  default = {
    "us-east-1" = "ami-0e32dc18"
    "us-west-2" = "ami-833e60fb"
  }
}

variable "cluster_name" {
	description = "The name for your instances in your cluster"
	default 	= "spark_cluster"
}
