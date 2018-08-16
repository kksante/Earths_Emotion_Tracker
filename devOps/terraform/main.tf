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


##############################################
# Cassandra
##############################################

resource "aws_instance" "cassandra_master" {
  ami = "${lookup(var.amis, "cassandra")}"
  instance_type = "m4.large"
  key_name = "${aws_key_pair.mykeypair.key_name}"
  count = 1
  vpc_security_group_ids = ["${module.security_group_network.spark_cluster_sg_id}"]
  subnet_id = "${module.subnet_network.public_subnet_id}"
  associate_public_ip_address = true
  root_block_device {
    volume_size = 100
    volume_type = "standard"
  }
  tags {
    Name        = "cassandra-master-${count.index}"
    Owner       = "${var.fellow_name}"
    Environment = "dev"
    Terraform   = "true"
    Cluster     = "cassandra"
    ClusterRole = "master"
  }
}

resource "aws_instance" "cassandra_worker" {
  ami = "${lookup(var.amis, "cassandra")}"
  instance_type = "m4.large"
  key_name = "${aws_key_pair.mykeypair.key_name}"
  count = "${var.cassandra_NUM_WORKERS}"
  vpc_security_group_ids = ["${module.security_group_network.spark_cluster_sg_id}"]
  subnet_id = "${module.subnet_network.public_subnet_id}"
  associate_public_ip_address = true
  root_block_device {
    volume_size = 100
    volume_type = "standard"
  }
  tags {
    Name        = "cassandra-worker-${count.index}"
    Owner       = "${var.fellow_name}"
    Environment = "dev"
    Terraform   = "true"
    Cluster     = "cassandra"
    ClusterRole = "worker"
  }
}


#Configuration for a master cluster
resource "aws_instance" "spark_master"{
  ami = "${lookup(var.amis, "spark")}"
  instance_type = "m4.large"
  key_name = "${aws_key_pair.mykeypair.key_name}"
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

 resource "aws_instance" "spark_worker"{
   ami = "${lookup(var.amis, "spark")}"
   instance_type = "m4.large"
   key_name = "${aws_key_pair.mykeypair.key_name}"
   count = "${var.NUM_WORKERS}"

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

# Configure workers
resource "null_resource" "spark_worker" {

  count = "${var.NUM_WORKERS}"

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${element(aws_instance.spark_worker.*.public_ip, "${count.index}")}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  # We need the slaves spun up first and then the master
  depends_on = [ "aws_instance.spark_master", "aws_instance.spark_worker" ]

  # Provision the Hadoop configuration script
  provisioner "file" {
    source = "scripts/hadoop_setup_single.sh"
    destination = "/tmp/hadoop_setup_single.sh"
  }

  # Provision the Hadoop configuration script
  provisioner "file" {
    source = "scripts/hadoop_config_datanode.sh"
    destination = "/tmp/hadoop_config_datanode.sh"
  }

  # Provision the Spark setup script
  provisioner "file" {
    source = "scripts/spark_setup_single.sh"
    destination = "/tmp/spark_setup_single.sh"
  }

  # Execute spark configuration script remotely
  provisioner "remote-exec" {
    inline = [
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.aws_region}'\" >> ~/.profile",
      "chmod +x /tmp/hadoop_setup_single.sh",
      "bash /tmp/hadoop_setup_single.sh '${aws_instance.spark_master.public_dns}' '${var.AWS_ACCESS_KEY}' '${var.AWS_SECRET_KEY}'",
      "chmod +x /tmp/hadoop_config_datanode.sh",
      "bash /tmp/hadoop_config_datanode.sh",
      "chmod +x /tmp/spark_setup_single.sh",
      "bash /tmp/spark_setup_single.sh '${element(aws_instance.spark_worker.*.public_dns, "${count.index}")}'",
    ]
  }
}

# Configure master
resource "null_resource" "spark_master" {

  # Establish connection to master
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${aws_instance.spark_master.public_ip}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  # We need the slaves configured first
  depends_on = [ "null_resource.spark_worker" ]

  # Provision the SSH configuration script
  provisioner "file" {
    source = "scripts/setup_ssh.sh"
    destination = "/tmp/setup_ssh.sh"
  }

  # Provision the Host configuration script
  provisioner "file" {
    source = "scripts/add_to_known_hosts.sh"
    destination = "/tmp/add_to_known_hosts.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "scripts/hadoop_setup_single.sh"
    destination = "/tmp/hadoop_setup_single.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "scripts/hadoop_config_hosts.sh"
    destination = "/tmp/hadoop_config_hosts.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "scripts/hadoop_config_namenode.sh"
    destination = "/tmp/hadoop_config_namenode.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "scripts/hadoop_format_hdfs.sh"
    destination = "/tmp/hadoop_format_hdfs.sh"
  }

  # Provision the Spark setup script
  provisioner "file" {
    source = "scripts/spark_setup_single.sh"
    destination = "/tmp/spark_setup_single.sh"
  }

  # Provision the Spark setup script
  provisioner "file" {
    source = "scripts/spark_configure_worker.sh"
    destination = "/tmp/spark_configure_worker.sh"
  }

  # Provision the Hadoop start script
  provisioner "file" {
    source = "scripts/hadoop_start.sh"
    destination = "/tmp/hadoop_start.sh"
  }

  # Provision the Spark start script
  provisioner "file" {
    source = "scripts/spark_start.sh"
    destination = "/tmp/spark_start.sh"
  }

  provisioner "file" {
    source = "${var.PATH_TO_PRIVATE_KEY}"
    destination = "/tmp/${aws_key_pair.mykeypair.key_name}"
  }

  # Provision
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_ssh.sh",
      "bash /tmp/setup_ssh.sh '${aws_key_pair.mykeypair.key_name}' '${join("' '", "${aws_instance.spark_worker.*.public_dns}")}'",
      "chmod +x /tmp/add_to_known_hosts.sh",
      "bash /tmp/add_to_known_hosts.sh '${aws_instance.spark_master.public_dns}' '${aws_instance.spark_master.private_dns}' '${join("' '", "${aws_instance.spark_worker.*.private_dns}")}'",
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.aws_region}'\" >> ~/.profile",
      "chmod +x /tmp/hadoop_setup_single.sh",
      "bash /tmp/hadoop_setup_single.sh '${aws_instance.spark_master.public_dns}' '${var.AWS_ACCESS_KEY}' '${var.AWS_SECRET_KEY}'",
      "chmod +x /tmp/hadoop_config_hosts.sh",
      "bash /tmp/hadoop_config_hosts.sh '${aws_instance.spark_master.public_dns}' '${aws_instance.spark_master.private_dns}' '${join("' '", "${aws_instance.spark_worker.*.public_dns}")}' '${join("' '", "${aws_instance.spark_worker.*.private_dns}")}'",
      "chmod +x /tmp/hadoop_config_namenode.sh",
      "bash /tmp/hadoop_config_namenode.sh '${aws_instance.spark_master.private_dns}' '${join("' '", "${aws_instance.spark_worker.*.private_dns}")}'",
      "chmod +x /tmp/hadoop_format_hdfs.sh",
      "bash /tmp/hadoop_format_hdfs.sh",
      "chmod +x /tmp/spark_setup_single.sh",
      "bash /tmp/spark_setup_single.sh '${aws_instance.spark_master.public_dns}'",
      "chmod +x /tmp/spark_configure_worker.sh",
      "bash /tmp/spark_configure_worker.sh '${join("' '", "${aws_instance.spark_worker.*.public_dns}")}'",
      "chmod +x /tmp/hadoop_start.sh",
      "bash /tmp/hadoop_start.sh",
      "chmod +x /tmp/spark_start.sh",
      "bash /tmp/spark_start.sh",
    ]
  }
}

# Controller
resource "aws_instance" "spark_controller" {
  ami = "${lookup(var.amis, "spark")}"
  instance_type = "m4.large"
  key_name = "${aws_key_pair.mykeypair.key_name}"
  count = 1
  vpc_security_group_ids = ["${module.security_group_network.spark_cluster_sg_id}"]
  subnet_id = "${module.subnet_network.public_subnet_id}"
  associate_public_ip_address = true
  root_block_device {
    volume_size = 100
    volume_type = "standard"
  }
  tags {
    Name = "spark_controller"
    Environment = "dev"
    Terraform = "true"
  }
}

# Configure controller
resource "null_resource" "spark_controller" {

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${aws_instance.spark_controller.public_ip}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  # We need spark cluster configured first
  depends_on = ["null_resource.spark_master", "null_resource.spark_worker" ]

  # Provision the SSH configuration script
  provisioner "file" {
    source = "scripts/setup_ssh.sh"
    destination = "/tmp/setup_ssh.sh"
  }

  # Provision the Host configuration script
  provisioner "file" {
    source = "scripts/add_to_known_hosts.sh"
    destination = "/tmp/add_to_known_hosts.sh"
  }

  # Provision the Spark setup script
  provisioner "file" {
    source = "scripts/spark_pre_config.sh"
    destination = "/tmp/spark_pre_config.sh"
  }

  # Provision the Spark setup script
  provisioner "file" {
    source = "scripts/spark_setup_single.sh"
    destination = "/tmp/spark_setup_single.sh"
  }

  # Provision the Spark start script
  provisioner "file" {
    source = "scripts/spark_start.sh"
    destination = "/tmp/spark_start.sh"
  }

  # Provision the Spark controller script
  provisioner "file" {
    source = "scripts/spark_setup_controller.sh"
    destination = "/tmp/spark_setup_controller.sh"
  }

  # Execute spark configuration commands remotely
  provisioner "remote-exec" {
    inline = [
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.aws_region}'\" >> ~/.profile",
      "chmod +x /tmp/spark_pre_config.sh",
      "bash /tmp/spark_pre_config.sh",
      "chmod +x /tmp/spark_setup_single.sh",
      "bash /tmp/spark_setup_single.sh '${aws_instance.spark_controller.public_dns}'",
      "chmod +x /tmp/spark_start.sh",
      "bash /tmp/spark_start.sh",
      "chmod +x /tmp/spark_setup_controller.sh",
      "bash /tmp/spark_setup_controller.sh '${aws_instance.spark_master.private_dns}' '${aws_instance.spark_master.private_dns}'",
    ]
  }
}

##############################################
# Flask
##############################################

resource "aws_instance" "flask" {
  ami = "${lookup(var.amis, "flask")}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.mykeypair.key_name}"
  count = 1
  vpc_security_group_ids = ["${module.security_group_network.spark_cluster_sg_id}"]
  subnet_id = "${module.subnet_network.public_subnet_id}"
  associate_public_ip_address = true
  tags {
    Name = "flask"
    Environment = "dev"
    Terraform = "true"
  }
}

##############################################
# Cassandra SetUp
##############################################

# Configure workers
resource "null_resource" "cassandra_worker" {

  count = "${var.cassandra_NUM_WORKERS}"

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${element(aws_instance.cassandra_worker.*.public_ip, "${count.index}")}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  # We need the slaves spun up first and then the master
  depends_on = [ "aws_instance.cassandra_master", "aws_instance.cassandra_worker" ]

  # Provision the Cassandra setup script
  provisioner "file" {
    source = "scripts/cassandra_setup.sh"
    destination = "/tmp/cassandra_setup.sh"
  }

  # Execute cassandra configuration script remotely
  provisioner "remote-exec" {
    inline = [
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.aws_region}'\" >> ~/.profile",
      "chmod +x /tmp/cassandra_setup.sh",
      "bash /tmp/cassandra_setup.sh 'cassandra' '${aws_instance.cassandra_master.private_dns}' ${element(aws_instance.cassandra_worker.*.private_dns, "${count.index}")}",
      "/usr/local/cassandra/bin/cassandra"
    ]
  }
}

resource "null_resource" "cassandra_master" {

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${aws_instance.cassandra_master.public_ip}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  # We need cassandra spun up first
  depends_on = [ "null_resource.cassandra_worker" ]

  # Provision the SSH configuration script
  provisioner "file" {
    source = "scripts/setup_ssh.sh"
    destination = "/tmp/setup_ssh.sh"
  }

  # Provision the Host configuration script
  provisioner "file" {
    source = "scripts/add_to_known_hosts.sh"
    destination = "/tmp/add_to_known_hosts.sh"
  }

  # Provision the Cassandra setup script
  provisioner "file" {
    source = "scripts/cassandra_setup.sh"
    destination = "/tmp/cassandra_setup.sh"
  }

  provisioner "file" {
    source = "${var.PATH_TO_PRIVATE_KEY}"
    destination = "/tmp/${aws_key_pair.mykeypair.key_name}"
  }

  # Execute cassandra configuration commands remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_ssh.sh",
      "bash /tmp/setup_ssh.sh '${aws_key_pair.mykeypair.key_name}' '${join("' '", "${aws_instance.cassandra_worker.*.public_dns}")}'",
      "chmod +x /tmp/add_to_known_hosts.sh",
      "bash /tmp/add_to_known_hosts.sh '${aws_instance.cassandra_master.public_dns}' '${aws_instance.cassandra_master.private_dns}' '${join("' '", "${aws_instance.cassandra_worker.*.private_dns}")}'",
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.aws_region}'\" >> ~/.profile",
      "chmod +x /tmp/cassandra_setup.sh",
      "bash /tmp/cassandra_setup.sh 'cassandra' '${aws_instance.cassandra_master.private_dns}' '${aws_instance.cassandra_master.private_dns}'",
      "/usr/local/cassandra/bin/cassandra"
    ]
  }
}
