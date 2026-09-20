# Jenkins Java Maven Pipeline

## CI/CD Pipeline

This project uses Jenkins to build and deploy the Java Maven application.

### Pipeline Stages

1. **Checkout**
   - Checks out the application source code from GitLab.

2. **Build**
   - Builds the Java Maven application.

3. **Docker Build**
   - Builds the Docker image for the application.

4. **Docker Push**
   - Pushes the Docker image to the container registry.

5. **Deploy**
   - Updates the kubeconfig for the AWS EKS cluster.
   - Deploys the Kubernetes Deployment.
   - Deploys the Kubernetes Service.

6. **Commit Version Update**
   - Updates the application version and pushes the change back to GitLab.

## Kubernetes Verification

After deployment, verify the application with:

```bash
kubectl get pods
kubectl get svc
