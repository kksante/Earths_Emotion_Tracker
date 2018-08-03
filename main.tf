provider "aws" {
  region = "${var.aws_region}"
}

module "vpc_network" {
  source = "./modules/network/vpc/"
}

module "igw_network" {
  source = "./modules/network/igw/"
  vpc_id = "${module.vpc_network.vpc_id}"
}

module "route_table_network" {
  source = "./modules/network/route_table/"

  vpc_id = "${module.vpc_network.vpc_id}"
  igw_id = "${module.igw_network.igw_id}"
}

module "subnet_network" {
  source = "./modules/network/subnet/"

  vpc_id = "${module.vpc_network.vpc_id}"
  vpc_cidr_prefix = "${module.vpc_network.vpc_cidr_prefix}"
  aws_region = "${var.aws_region}"

  public_rt_id = "${module.route_table_network.public_rt_id}"
  private_rt_id = "${module.route_table_network.private_rt_id}"
}

module "security_group_network" {
  source = "./modules/network/security_group"

  vpc_id = "${module.vpc_network.vpc_id}"
}

#Configuration for a master cluster
resource "aws_instance" "spark_cluster_master"{
  ami = "${lookup(var.amis, var.aws_region)}"
  instance_type = "m4.large"
  key_name = "${var.keypair_name}"
  count = 1

  vpc_security_group_ids = ["${module.security_group_network.spark_cluster_sg_id}"]
  subnet_id = "${module.subnet_network.public_subnet_id}"

  root_block_device {
        volume_size = 100
        volume_type = "standard"
    }

    tags {
      Name        = "${var.cluster_name}-master-${count.index}"
      Owner       = "${var.fellow_name}"
      Environment = "dev"
      Terraform   = "true"
      Cluster     = "spark"
      ClusterRole = "master"
    }

  }

 #Configuration for 3 worker instances

 resource "aws_instance" "spark_cluster_worker"{
   ami = "${lookup(var.amis, var.aws_region)}"
   instance_type = "m4.large"
   key_name = "${var.keypair_name}"
   count = 3

   vpc_security_group_ids = ["${module.security_group_network.spark_cluster_sg_id}"]
   subnet_id = "${module.subnet_network.public_subnet_id}"

   root_block_device {
         volume_size = 100
         volume_type = "standard"
     }

     tags {
      Name        = "${var.cluster_name}-worker-${count.index}"
      Owner       = "${var.fellow_name}"
      Environment = "dev"
      Terraform   = "true"
      Cluster     = "spark"
      ClusterRole = "worker"
    }

   }

   # Configuration for Elastic IP. Needed to ssh into instances

   resource "aws_eip" "elastic_ips_for_instances" {
     vpc     = true
     instance = "${element(concat(aws_instance.spark_cluster_master.*.id, aws_instance.spark_cluster_worker.*.id), count.index)}"
     count   = "${aws_instance.spark_cluster_master.count + aws_instance.spark_cluster_worker.count}"
   }
