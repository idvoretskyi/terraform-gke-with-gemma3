# GKE Terraform Configuration for Gemma 3

This Terraform configuration provides a cost-effective GKE cluster optimized for running Google's Gemma 3 model.

## Features

- Cost-optimized GKE cluster using ARM-based nodes (t2a machine type)
- Spot/Preemptible VM instances for additional cost savings
- Node taints to ensure Gemma 3 pods are properly scheduled
- Auto-scaling node pool to adjust to demand
- Automated deployment script for Gemma 3

## Prerequisites

- Google Cloud SDK installed and configured
- Terraform v1.0+ installed
- kubectl installed
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

2. Clone this repository:

```bash
git clone https://github.com/idvoretskyi/terraform-gke-with-gemma3.git
cd terraform-gke-with-gemma3/gemma3
```

3. Create a `terraform.tfvars` file based on the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

4. Edit `terraform.tfvars` to customize your deployment (region, zone, etc.)

5. Initialize and apply the Terraform configuration:

```bash
terraform init
terraform plan
terraform apply
```

6. Configure kubectl to connect to your new cluster:

```bash
$(terraform output -raw kubectl_configure_command)
```

7. Deploy Gemma 3 to your cluster:

```bash
python3 gemma3.py
```

## Advanced Configuration

For advanced scenarios, the following configuration options are available:

- `private_cluster`: Set to `true` to create a private GKE cluster
- `enable_gvisor`: Set to `true` to enable gVisor container sandbox for enhanced security
- `local_ssd_count`: Set to a non-zero value to attach local SSDs for faster model loading

Refer to `variables.tf` for all available configuration options.

## Accessing Gemma 3

After running the deployment script, Gemma 3 will be accessible via a LoadBalancer service.
The script will output the external IP address when available.

## Cleaning Up

To delete all resources created by this configuration:

```bash
terraform destroy
```

## Notes

- This configuration uses your default GCP project as configured in the gcloud CLI
- Spot/Preemptible VMs can be terminated at any time. Consider using a managed instance group for more resilience.
- ARM compatibility: Ensure that the Gemma 3 image is built for the ARM architecture.
- This configuration uses COS_CONTAINERD as the node image type, which is optimized for running containers.
# terraform-gke-with-gemma3
