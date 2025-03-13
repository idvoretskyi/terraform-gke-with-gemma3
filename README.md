# GKE Terraform Configuration for Gemma 3

This Terraform configuration provides a cost-effective GKE cluster optimized for running Google's Gemma 3 model.

## Features

- Cost-optimized GKE cluster using ARM-based nodes (t2a machine type)
- Spot/Preemptible VM instances for additional cost savings
- Node taints to ensure Gemma 3 pods are properly scheduled
- Auto-scaling node pool to adjust to demand
- Fully automated deployment of Gemma 3 using pure Terraform (no scripts needed)

## Architecture

This configuration:
1. Creates a VPC and subnet with secondary ranges for pods and services
2. Deploys a GKE cluster with a default node pool removed
3. Creates a custom node pool with ARM-based VMs and spot pricing for cost efficiency
4. Automatically deploys Gemma 3 as a Kubernetes Deployment with a LoadBalancer Service
5. Sets up proper node selectors and taints to ensure Gemma 3 runs on the correct nodes

## Prerequisites

- Google Cloud SDK installed and configured
- Terraform v1.0+ installed
- Access to a Google Cloud Project with billing enabled
- Required APIs enabled:
  - compute.googleapis.com
  - container.googleapis.com

## Quick Start

1. **Authenticate with GCP**:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

2. **Clone this repository**:

```bash
git clone https://github.com/idvoretskyi/terraform-gke-with-gemma3.git
cd terraform-gke-with-gemma3/gemma3
```

3. **Create a terraform.tfvars file**:

```bash
cp terraform.tfvars.example terraform.tfvars
```

4. **Edit terraform.tfvars** to customize your deployment:

```bash
# Edit with your preferred text editor
vim terraform.tfvars
```

5. **Initialize and apply the Terraform configuration**:

```bash
terraform init
terraform plan
terraform apply
```

6. **Configure kubectl** to connect to your new cluster:

```bash
$(terraform output -raw kubectl_configure_command)
```

7. **Access Gemma 3** deployed to your cluster:

```bash
# Check the status of the Gemma 3 deployment
$(terraform output -raw gemma3_check_status_command)

# Get Gemma 3 external IP
$(terraform output -raw gemma3_get_ip_command)
```

Once you have the IP address, you can access the Gemma 3 API at `http://<IP_ADDRESS>`.

## Advanced Configuration

### Cluster Settings

For advanced scenarios, the following configuration options are available:

- `private_cluster`: Set to `true` to create a private GKE cluster
- `enable_gvisor`: Set to `true` to enable gVisor container sandbox for enhanced security
- `local_ssd_count`: Set to a non-zero value to attach local SSDs for faster model loading
- `use_spot_vms`: Set to `false` to use regular VMs instead of spot VMs

### Gemma 3 Customization

You can customize the Gemma 3 deployment by adjusting these variables in your `terraform.tfvars` file:

```terraform
# Gemma 3 Configuration
k8s_namespace        = "gemma3"     # Kubernetes namespace
gemma3_replicas      = 1            # Number of Gemma 3 instances
gemma3_image         = "ghcr.io/google-deepmind/gemma:latest"
gemma3_cpu_limit     = "4"          # CPU resource limit
gemma3_memory_limit  = "16Gi"       # Memory resource limit
gemma3_cpu_request   = "2"          # CPU resource request
gemma3_memory_request = "8Gi"       # Memory resource request
```

Refer to `variables.tf` for all available configuration options.

## Cleaning Up

To delete all resources created by this configuration:

```bash
terraform destroy
```

## Notes

- This configuration uses your specified GCP project
- Spot/Preemptible VMs can be terminated at any time. Consider using a managed instance group for more resilience.
- ARM compatibility: Ensure that the Gemma 3 image is built for the ARM architecture.
- This configuration uses COS_CONTAINERD as the node image type, which is optimized for running containers.
