output "spark_cluster_sg_id" {
  description = "Spark Cluster Security Group Id"
  value       = "${aws_security_group.spark_cluster_sec_group.id}"
}
