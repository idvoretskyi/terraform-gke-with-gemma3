# Configure the Kubernetes provider to use the GKE cluster
provider "kubernetes" {
  host                   = "https://${google_container_cluster.gke_cluster.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate)
}

# Get current Google client configuration
data "google_client_config" "current" {}

# Create namespace for Gemma 3
resource "kubernetes_namespace" "gemma3" {
  depends_on = [google_container_node_pool.gemma3_node_pool]
  
  metadata {
    name = var.k8s_namespace
  }
}

# Create Gemma 3 deployment
resource "kubernetes_deployment" "gemma3" {
  depends_on = [kubernetes_namespace.gemma3]
  
  metadata {
    name      = "gemma3"
    namespace = kubernetes_namespace.gemma3.metadata[0].name
    labels = {
      app = "gemma3"
    }
  }

  spec {
    replicas = var.gemma3_replicas

    selector {
      match_labels = {
        app = "gemma3"
      }
    }

    template {
      metadata {
        labels = {
          app = "gemma3"
        }
      }

      spec {
        node_selector = {
          "model" = "gemma3"
        }
        
        # Add tolerance for the taint on the node pool
        toleration {
          key      = "dedicated"
          operator = "Equal"
          value    = "gemma3"
          effect   = "NoSchedule"
        }
        
        container {
          name  = "gemma3"
          image = var.gemma3_image
          
          resources {
            limits = {
              cpu    = var.gemma3_cpu_limit
              memory = var.gemma3_memory_limit
            }
            requests = {
              cpu    = var.gemma3_cpu_request
              memory = var.gemma3_memory_request
            }
          }
          
          port {
            container_port = 8080
            name           = "http"
          }
          
          env {
            name  = "MODEL_PATH"
            value = "/models/gemma-3"
          }
          
          volume_mount {
            name       = "model-storage"
            mount_path = "/models"
          }
        }
        
        volume {
          name = "model-storage"
          empty_dir {}
        }
      }
    }
  }
}

# Create Gemma 3 service
resource "kubernetes_service" "gemma3" {
  depends_on = [kubernetes_deployment.gemma3]
  
  metadata {
    name      = "gemma3"
    namespace = kubernetes_namespace.gemma3.metadata[0].name
  }
  
  spec {
    selector = {
      app = "gemma3"
    }
    
    port {
      port        = 80
      target_port = 8080
    }
    
    type = "LoadBalancer"
  }
}

# Output the LoadBalancer IP when available
resource "null_resource" "wait_for_service" {
  depends_on = [kubernetes_service.gemma3]

  provisioner "local-exec" {
    command = "kubectl -n ${var.k8s_namespace} get service gemma3 -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
  }
}
