#!/usr/bin/env python3

import subprocess
import time
import sys
import os

def run_command(command):
    """Run a shell command and return the result"""
    try:
        result = subprocess.run(command, shell=True, check=True, 
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE, 
                               universal_newlines=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {command}")
        print(f"Error message: {e.stderr}")
        return None

def check_kubectl():
    """Check if kubectl is properly configured"""
    print("Checking kubectl configuration...")
    result = run_command("kubectl get nodes")
    if result is None:
        print("Error: kubectl not configured correctly. Please run the kubectl configure command from Terraform outputs.")
        sys.exit(1)
    return True

def create_namespace():
    """Create namespace for Gemma 3"""
    print("Creating namespace for Gemma 3...")
    run_command("kubectl create namespace gemma3 --dry-run=client -o yaml | kubectl apply -f -")

def deploy_gemma3():
    """Deploy Gemma 3 to the cluster"""
    print("Deploying Gemma 3...")
    
    # Create deployment YAML
    deployment_yaml = """apiVersion: apps/v1
kind: Deployment
metadata:
  name: gemma3
  namespace: gemma3
  labels:
    app: gemma3
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gemma3
  template:
    metadata:
      labels:
        app: gemma3
    spec:
      nodeSelector:
        model: gemma3
      tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "gemma3"
        effect: "NoSchedule"
      containers:
      - name: gemma3
        image: ghcr.io/google-deepmind/gemma:latest  # Replace with actual Gemma 3 image
        resources:
          limits:
            cpu: "4"
            memory: "16Gi"
          requests:
            cpu: "2"
            memory: "8Gi"
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: MODEL_PATH
          value: "/models/gemma-3"
        volumeMounts:
        - name: model-storage
          mountPath: /models
      volumes:
      - name: model-storage
        emptyDir: {}
"""

    # Create service YAML
    service_yaml = """apiVersion: v1
kind: Service
metadata:
  name: gemma3
  namespace: gemma3
spec:
  selector:
    app: gemma3
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
"""

    # Apply deployment and service
    with open("/tmp/gemma3-deployment.yaml", "w") as f:
        f.write(deployment_yaml)
    
    with open("/tmp/gemma3-service.yaml", "w") as f:
        f.write(service_yaml)
    
    run_command("kubectl apply -f /tmp/gemma3-deployment.yaml")
    run_command("kubectl apply -f /tmp/gemma3-service.yaml")

def wait_for_deployment():
    """Wait for the Gemma 3 deployment to be ready"""
    print("Waiting for Gemma 3 deployment to be ready...")
    run_command("kubectl -n gemma3 rollout status deployment/gemma3")

def get_external_ip():
    """Get the external IP address of the Gemma 3 service"""
    print("Getting external IP address...")
    
    external_ip = None
    for i in range(1, 31):
        external_ip = run_command("kubectl -n gemma3 get service gemma3 -o jsonpath='{.status.loadBalancer.ingress[0].ip}'")
        if external_ip:
            break
        print(f"Waiting for external IP... ({i}/30)")
        time.sleep(5)
    
    if external_ip:
        print("\nGemma 3 has been deployed successfully!")
        print(f"You can access the API at: http://{external_ip}")
        print("")
    else:
        print("\nGemma 3 deployment is in progress, but the external IP is not yet available.")
        print("You can check its status with: kubectl -n gemma3 get service gemma3")
        print("")

def show_summary():
    """Show deployment summary"""
    print("Deployment summary:")
    run_command("kubectl -n gemma3 get deployments,pods,services")

def main():
    """Main function to deploy Gemma 3"""
    print("Deploying Gemma 3 to GKE cluster...")
    
    # Run deployment steps
    check_kubectl()
    create_namespace()
    deploy_gemma3()
    wait_for_deployment()
    get_external_ip()
    show_summary()

if __name__ == "__main__":
    main()
