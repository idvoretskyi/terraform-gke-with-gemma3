terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Set a variable for project_id that must be provided by the user
variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
  # No default - user must specify
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# ---------------------------------------------------------------------------------------------------------------------
# Networking Resources
# ---------------------------------------------------------------------------------------------------------------------

# VPC Network for GKE
resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

# Subnet for GKE nodes
resource "google_compute_subnetwork" "subnet" {
  project       = var.project_id
  name          = "${var.cluster_name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr
  
  # Secondary ranges for pods and services
  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = var.pod_cidr
  }
  
  secondary_ip_range {
    range_name    = "service-range"
    ip_cidr_range = var.service_cidr
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GKE Cluster
# ---------------------------------------------------------------------------------------------------------------------

resource "google_container_cluster" "gke_cluster" {
  project            = var.project_id
  name               = var.cluster_name
  location           = var.zone
  remove_default_node_pool = true
  initial_node_count = 1
  
  # Network configuration
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
  networking_mode = "VPC_NATIVE"
  
  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = "service-range"
  }

  # Release channel configuration
  release_channel {
    channel = var.release_channel
  }

  # Private cluster configuration (optional)
  dynamic "private_cluster_config" {
    for_each = var.private_cluster ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = false
      master_ipv4_cidr_block  = var.master_ipv4_cidr
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Node Pool for Gemma 3
# ---------------------------------------------------------------------------------------------------------------------

resource "google_container_node_pool" "gemma3_node_pool" {
  project    = var.project_id
  name       = "${var.cluster_name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.gke_cluster.name
  
  # Auto-scaling configuration
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  
  initial_node_count = var.initial_node_count

  # Node management settings
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Node configuration
  node_config {
    # Cost optimization settings
    spot          = var.use_spot_vms
    preemptible   = !var.use_spot_vms
    machine_type  = var.machine_type
    disk_size_gb  = var.disk_size_gb
    disk_type     = var.disk_type
    local_ssd_count = var.local_ssd_count
    image_type    = "COS_CONTAINERD"
    
    # Access scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    
    # Kubernetes node configuration
    labels = {
      "model" = "gemma3"
    }
    
    # Ensure only Gemma 3 pods are scheduled on these nodes
    taint {
      key    = "dedicated"
      value  = "gemma3"
      effect = "NO_SCHEDULE"
    }
  }
}
