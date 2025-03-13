output "cluster_name" {
  value       = google_container_cluster.gke_cluster.name
  description = "The name of the GKE cluster"
}

output "cluster_endpoint" {
  value       = google_container_cluster.gke_cluster.endpoint
  description = "The endpoint of the GKE cluster"
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate
  description = "The public certificate authority of the cluster"
  sensitive   = true
}

output "network_name" {
  value       = google_compute_network.vpc.name
  description = "The name of the VPC network"
}

output "subnet_name" {
  value       = google_compute_subnetwork.subnet.name
  description = "The name of the subnet"
}

output "node_pool_name" {
  value       = google_container_node_pool.gemma3_node_pool.name
  description = "The name of the GKE node pool"
}

output "kubectl_configure_command" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --zone ${var.zone} --project ${var.project_id}"
  description = "Command to configure kubectl"
}

output "deployment_command" {
  value       = "cd ${path.module} && chmod +x gemma3.py && python3 gemma3.py"
  description = "Command to deploy Gemma 3 to the cluster"
}
