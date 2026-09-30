# Jenkins Java Maven Pipeline

## CI/CD Pipeline

This project uses Jenkins to build and deploy a Java Maven application.

The Jenkins pipeline automates the following stages:

### Pipeline Stages

1. **Checkout**
   - Checks out the Java Maven application source code from GitHub.

2. **Build**
   - Builds the Java Maven application using Maven.
   - Packages the application into a JAR file.

3. **Docker Build**
   - Builds a Docker image for the application.
   - Uses the application version and Jenkins build number to tag the image.

4. **Docker Push**
   - Authenticates with AWS.
   - Pushes the Docker image to an AWS ECR repository.

5. **Ansible**
   - Connects to the Ansible control server.
   - Copies the Ansible project to the control server.
   - Runs the Ansible playbook to configure the target environment.

6. **Deploy**
   - Updates the Kubernetes deployment for the application.
   - Deploys the application to an AWS EKS cluster.

7. **Commit Version Update**
   - Updates the application version.
   - Commits the version change back to the GitHub repository.

## Kubernetes Verification

After deployment, the Kubernetes resources can be verified with:

```bash
kubectl get pods
kubectl get svc   - Deploys the Kubernetes Service.

7. **Commit Version Update**
   - Updates the application version and pushes the change back to GitHub.

## Kubernetes Verification

After deployment, verify the application with:

```bash
kubectl get pods
kubectl get svc
` ``` `
The application service can then be accessed using the external endpoint provided by Kubernetes.

Technologies Used
Jenkins
Java
Maven
GitHub
Docker
AWS ECR
AWS EKS
Kubernetes
Ansible
AWS CLI

Purpose

This project demonstrates an end-to-end CI/CD pipeline using Jenkins to automate application building, containerization, image publishing, server configuration with Ansible, Kubernetes deployment, and version management.
