# ---------------------------------------------------------------------------------------------------------------------
# Cluster Information
# ---------------------------------------------------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------------------------------------------------
# Network Information
# ---------------------------------------------------------------------------------------------------------------------

output "network_name" {
  value       = google_compute_network.vpc.name
  description = "The name of the VPC network"
}

output "subnet_name" {
  value       = google_compute_subnetwork.subnet.name
  description = "The name of the subnet"
}

# ---------------------------------------------------------------------------------------------------------------------
# Node Pool Information
# ---------------------------------------------------------------------------------------------------------------------

output "node_pool_name" {
  value       = google_container_node_pool.gemma3_node_pool.name
  description = "The name of the GKE node pool"
}

# ---------------------------------------------------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------------------------------------------------

output "kubectl_configure_command" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --zone ${var.zone} --project ${var.project_id}"
  description = "Command to configure kubectl"
}

# ---------------------------------------------------------------------------------------------------------------------
# Gemma 3 Deployment Information
# ---------------------------------------------------------------------------------------------------------------------

output "gemma3_namespace" {
  value       = kubernetes_namespace.gemma3.metadata[0].name
  description = "The namespace where Gemma 3 is deployed"
}

output "gemma3_deployment" {
  value       = kubernetes_deployment.gemma3.metadata[0].name
  description = "The name of the Gemma 3 deployment"
}

output "gemma3_service" {
  value       = kubernetes_service.gemma3.metadata[0].name
  description = "The name of the Gemma 3 service"
}

output "gemma3_check_status_command" {
  value       = "kubectl -n ${kubernetes_namespace.gemma3.metadata[0].name} get deployments,pods,services"
  description = "Command to check the status of the Gemma 3 deployment"
}

output "gemma3_get_ip_command" {
  value       = "kubectl -n ${kubernetes_namespace.gemma3.metadata[0].name} get service gemma3 -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
  description = "Command to get the external IP of the Gemma 3 service"
}
