output "spark_cluster_sg_id" {
  description = "The ID of the Kubernetes Cluster Security Group Id"
  value       = "${aws_security_group.spark_cluster_sec_group.id}"
}
