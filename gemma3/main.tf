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

# GKE Cluster 
resource "google_container_cluster" "gke_cluster" {
  project            = var.project_id
  name               = var.cluster_name
  location           = var.zone
  remove_default_node_pool = true
  initial_node_count = 1
  
  # Use the VPC and subnet created above
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # Enable VPC-native cluster (using alias IPs)
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = "service-range"
  }

  # Release channel for automatic upgrades
  release_channel {
    channel = var.release_channel
  }

  # Private cluster settings if desired
  dynamic "private_cluster_config" {
    for_each = var.private_cluster ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = false
      master_ipv4_cidr_block  = var.master_ipv4_cidr
    }
  }
}

# Node pool for Gemma 3 - using ARM processors for cost efficiency
resource "google_container_node_pool" "gemma3_node_pool" {
  project    = var.project_id
  name       = "${var.cluster_name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.gke_cluster.name
  
  # Autoscaling for cost optimization
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  
  # Initial size of node pool
  initial_node_count = var.initial_node_count

  # Node management settings
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Node configuration
  node_config {
    # Use preemptible VMs for cost savings
    spot          = var.use_spot_vms    # spot VMs (newer than preemptible)
    preemptible   = !var.use_spot_vms   # preemptible if not using spot
    
    # ARM-based machine type for cost efficiency
    machine_type = var.machine_type
    
    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    
    # Labels for node selection in k8s
    labels = {
      "model" = "gemma3"
    }
    
    # Taints to ensure only Gemma 3 pods are scheduled on these nodes
    taint {
      key    = "dedicated"
      value  = "gemma3"
      effect = "NO_SCHEDULE"
    }
    
    # Using COS_CONTAINERD for optimized container runtime
    image_type = "COS_CONTAINERD"
    
    # Disk size for model data
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    
    # Local SSD if needed for model caching
    local_ssd_count = var.local_ssd_count
  }
}
