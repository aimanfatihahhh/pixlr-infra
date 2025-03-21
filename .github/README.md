# CI/CD Pipeline for Pixlr Kubernetes Deployment

## Overview
This document describes the **CI/CD pipeline** for deploying the **Pixlr** web application using **GitHub Actions, Docker Hub, AWS EKS, and Helm**. The pipeline automates the build, test, security scan, and deployment processes, ensuring a streamlined and secure workflow.

## Tools Selection

| Stage               | Tool                     | Justification |
|---------------------|-------------------------|--------------|
| **Version Control** | GitHub                   | Centralized repository for code and CI/CD workflows. |
| **CI/CD Automation** | GitHub Actions          | Native GitHub integration with built-in automation capabilities. |
| **Containerization** | Docker                  | Ensures consistency across development and production. |
| **Container Registry** | Docker Hub           | Public/private repository for storing container images. |
| **Security Scanning** | Trivy                  | Identifies vulnerabilities in Docker images. |
| **Kubernetes Cluster** | Amazon EKS           | Managed Kubernetes service for scalable application deployment. |
| **Deployment Management** | Helm              | Simplifies Kubernetes application management with version control. |

## Pipeline Stages

### 1. **Trigger**
- The pipeline is triggered on **push** and **pull request** events to the `main` and `develop` branches.

### 2. **Build and Push Docker Image**
- Uses **Docker Buildx** for multi-platform builds.
- Logs into **Docker Hub** and pushes the Docker image with a commit-based tag.

### 3. **Run Tests**
- Runs application tests inside a **Docker container** to verify functionality.

### 4. **Security Scan**
- Uses **Trivy** to scan the built Docker image for vulnerabilities.

### 5. **Deploy to Kubernetes (AWS EKS)**
- Configures **kubectl** for EKS access.
- Installs **Helm** for Kubernetes deployment management.
- Deploys the application to EKS using Helm.

### 6. **Rollback on Failure**
- If the deployment fails, Helm rolls back the application to the previous successful version.

## GitHub Actions Workflow

```yaml
name: CI/CD Pipeline for Pixlr Kubernetes Deployment

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop

jobs:
  build:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_ACCESS_TOKEN }}

      - name: Build and Push Docker Image
        run: |
          IMAGE_TAG=$(git rev-parse --short HEAD)
          docker build -t ${{ secrets.DOCKER_HUB_USERNAME }}/pixlr-app:$IMAGE_TAG . 
          docker push ${{ secrets.DOCKER_HUB_USERNAME }}/pixlr-app:$IMAGE_TAG
          echo "IMAGE_TAG=$IMAGE_TAG" >> $GITHUB_ENV

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: build

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Run Tests
        run: |
          docker run --rm ${{ secrets.DOCKER_HUB_USERNAME }}/pixlr-app:${{ env.IMAGE_TAG }} npm test  

  security_scan:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: build

    steps:
      - name: Install Trivy
        run: |
          sudo apt-get install wget -y
          wget https://github.com/aquasecurity/trivy/releases/latest/download/trivy-linux-amd64 -O trivy
          chmod +x trivy
          sudo mv trivy /usr/local/bin/

      - name: Run Security Scan
        run: |
          trivy image --exit-code 1 --severity HIGH,CRITICAL ${{ secrets.DOCKER_HUB_USERNAME }}/pixlr-app:${{ env.IMAGE_TAG }} 

  deploy:
    name: Deploy to Kubernetes
    runs-on: ubuntu-latest
    needs: [test, security_scan]

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Setup Kubectl
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1 

      - name: Setup Helm
        run: |
          curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

      - name: Configure Kubeconfig
        run: |
          aws eks update-kubeconfig --region us-east-1 --name pixlr-cluster

      - name: Deploy to Kubernetes
        run: |
          IMAGE_TAG=${{ env.IMAGE_TAG }}
          helm upgrade --install pixlr-app ./helm-chart \
            --set image.repository=${{ secrets.DOCKER_HUB_USERNAME }}/pixlr-app \
            --set image.tag=$IMAGE_TAG

  rollback:
    name: Rollback on Failure
    runs-on: ubuntu-latest
    if: failure()
    needs: deploy

    steps:
      - name: Configure Kubeconfig
        run: |
          aws eks update-kubeconfig --region us-east-1 --name pixlr-cluster

      - name: Rollback Deployment
        run: |
          helm rollback pixlr-app --wait  