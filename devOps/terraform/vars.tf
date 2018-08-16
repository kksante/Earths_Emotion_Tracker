/*
var.tf

This file initializes Terraform variables.

Please specify the following environment variables:
TF_VAR_AWS_ACCESS_KEY = <your-access-key>
TF_VAR_AWS_SECRET_KEY = <your-secret-key>
*/

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

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
    spark = "ami-a4cdebdc"
    cassandra = "ami-a4cdebdc"
    flask = "ami-70c9ef08"
  }
}

variable "cluster_name" {
	description = "The name for your instances in your cluster"
	default 	= "spark_cluster"
}

# Overwritten by build.sh
variable "NUM_WORKERS" { default = 3 }
variable "cassandra_NUM_WORKERS" { default = 3 }

# Overwritten by build.sh
variable "PATH_TO_PUBLIC_KEY" { default = "~/Documents/Earths_Emotion_Tracker/devOps/terraform/mykeypair.pub" }

# Overwritten by build.sh
variable "PATH_TO_PRIVATE_KEY" { default = "~/Documents/Earths_Emotion_Tracker/devOps/terraform/mykeypair" }
