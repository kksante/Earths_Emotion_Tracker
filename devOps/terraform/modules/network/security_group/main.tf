## Security group for Spark Cluster
resource "aws_security_group" "spark_cluster_sec_group" {
  vpc_id = "${var.vpc_id}"
  name = "${terraform.workspace}-spark-cluster-sec-group"

  tags {
    Name = "${terraform.workspace}-spark-sec-group"
    Environment = "${terraform.workspace}"
    Type = "public"
  }
}

# Open up port 22 for SSH into each machine
# The allowed locations are chosen by the user in the SSHLocation parameter
resource "aws_security_group_rule" "allow_ssh" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.spark_cluster_sec_group.id}"
}

resource "aws_security_group_rule" "allow_egress"{
  type              = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.spark_cluster_sec_group.id}"
}
