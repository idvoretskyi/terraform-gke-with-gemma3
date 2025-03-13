# ---------------------------------------------------------------------------------------------------------------------
# Required Variables
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
}

# ---------------------------------------------------------------------------------------------------------------------
# Location Variables
# ---------------------------------------------------------------------------------------------------------------------

variable "region" {
  type        = string
  description = "The region to deploy the GKE cluster"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "The zone to deploy the GKE cluster"
  default     = "us-central1-a"
}

# ---------------------------------------------------------------------------------------------------------------------
# Cluster Configuration
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  type        = string
  description = "The name of the GKE cluster"
  default     = "gemma3-cluster"
}

variable "release_channel" {
  type        = string
  description = "The release channel for the GKE cluster"
  default     = "RAPID"
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "The release_channel must be one of RAPID, REGULAR, or STABLE."
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Network Configuration
# ---------------------------------------------------------------------------------------------------------------------

variable "subnet_cidr" {
  type        = string
  description = "The CIDR range for the subnet"
  default     = "10.0.0.0/24"
}

variable "pod_cidr" {
  type        = string
  description = "The CIDR range for pods"
  default     = "10.1.0.0/16"
}

variable "service_cidr" {
  type        = string
  description = "The CIDR range for services"
  default     = "10.2.0.0/16"
}

variable "private_cluster" {
  type        = bool
  description = "Whether to create a private cluster"
  default     = false
}

variable "master_ipv4_cidr" {
  type        = string
  description = "The CIDR range for the master network"
  default     = "172.16.0.0/28"
}

# ---------------------------------------------------------------------------------------------------------------------
# Node Pool Configuration
# ---------------------------------------------------------------------------------------------------------------------

variable "min_node_count" {
  type        = number
  description = "The minimum number of nodes in the node pool"
  default     = 1
}

variable "max_node_count" {
  type        = number
  description = "The maximum number of nodes in the node pool"
  default     = 3
}

variable "initial_node_count" {
  type        = number
  description = "The initial number of nodes in the node pool"
  default     = 1
}

variable "machine_type" {
  type        = string
  description = "The machine type for the nodes (t2a for ARM-based instances)"
  default     = "t2a.medium"
}

variable "disk_size_gb" {
  type        = number
  description = "The disk size for the nodes in GB"
  default     = 100
}

variable "disk_type" {
  type        = string
  description = "The disk type for the nodes"
  default     = "pd-standard"
}

variable "local_ssd_count" {
  type        = number
  description = "The number of local SSDs to attach to each node"
  default     = 0
}

variable "use_spot_vms" {
  type        = bool
  description = "Whether to use spot VMs (cheaper but can be terminated anytime)"
  default     = true
}

variable "enable_gvisor" {
  type        = bool
  description = "Whether to enable gVisor for better security isolation"
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# Kubernetes Deployment Configuration
# ---------------------------------------------------------------------------------------------------------------------

variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace for Gemma 3 deployment"
  default     = "gemma3"
}

variable "gemma3_replicas" {
  type        = number
  description = "Number of Gemma 3 replicas to deploy"
  default     = 1
}

variable "gemma3_image" {
  type        = string
  description = "Container image for Gemma 3"
  default     = "ghcr.io/google-deepmind/gemma:latest"
}

variable "gemma3_cpu_limit" {
  type        = string
  description = "CPU limit for Gemma 3 container"
  default     = "4"
}

variable "gemma3_memory_limit" {
  type        = string
  description = "Memory limit for Gemma 3 container"
  default     = "16Gi"
}

variable "gemma3_cpu_request" {
  type        = string
  description = "CPU request for Gemma 3 container"
  default     = "2"
}

variable "gemma3_memory_request" {
  type        = string
  description = "Memory request for Gemma 3 container"
  default     = "8Gi"
}
