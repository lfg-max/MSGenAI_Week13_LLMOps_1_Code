# 🚛 Supply Chain LLMOps - Deployment Guide

This repository contains automation scripts to provision the necessary Azure infrastructure and deploy the **Supply Chain LLMOps platform** using Azure CLI and Docker.

---

## 📋 Prerequisites

### Required Tools
- **Azure CLI**: Must be installed on your local machine or Codespace
- **Docker Desktop**: Must be installed and running (required for building and pushing Docker images)
- **Azure Subscription**: Active permissions to create resources (Storage, AI Search, ACR, App Service)
- **Local Data**: A folder containing your supply chain data (CSV files)

### Installation Commands
```bash
# Install Azure CLI (if not already installed)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Docker (if not already installed)
# Follow instructions at: https://docs.docker.com/get-docker/
```

---

## ⚠️ Critical Troubleshooting: "Unauthorized" or "Image Pull" Errors

If you deploy your app and see a `BlockedImagePullUnauthorizedFailure`, "Forbidden", or "Extraction of image failed" error in your Azure Web App logs, check your computer's architecture.

### The Apple Silicon (M1/M2/M3) Issue
If you are building the Docker image on a modern Mac (Apple Silicon) or any ARM-based machine, Docker defaults to building an `arm64` image. However, Azure App Service (B1 Linux Plan) runs on Intel (`amd64`) hardware. When Azure tries to run your ARM image, it instantly crashes, which Azure's logging system confusingly reports as an "Unauthorized" pull error.

### 🔧 The Fix
You must force Docker to build an Intel/AMD compatible image.

**Update your Dockerfile:**
```dockerfile
FROM --platform=linux/amd64 python:3.10-slim
```

**Build commands (already updated in nra_deployment_script.sh):**
```bash
docker build --platform linux/amd64 -t your-image-name .
```

---

## 🚀 Deployment Steps

### Step 1: Configure Environment Variables

**Action:** Open `nra_setup.env` and review the names and locations.

**Requirements:**
- Make sure `STORAGE_ACCOUNT_NAME`, `SEARCH_SERVICE_NAME`, `ACR_NAME`, and `WEB_APP_NAME` are globally unique
- Update `LOCAL_DATA_FOLDER` to point to the directory containing your data files (default is `./data`)

```bash
# Edit the environment configuration
nano nra_setup.env
# or
vim nra_setup.env
```

### Step 2: Prepare Local Data

**Action:** Ensure that the directory referenced in `LOCAL_DATA_FOLDER` exists and contains the data files you wish to upload to Azure Blob Storage.

```bash
# Verify your data files are in place
ls -la ./data/
```

### Step 3: Run the Deployment Script

**Action:** Make the script executable and run it. The script will prompt you to log in to Azure if you aren't already authenticated.

```bash
# Make script executable
chmod +x nra_deployment_script.sh

# Run deployment
./nra_deployment_script.sh
```

> **Note:** The script includes a necessary 60-second pause after creating the Container Registry to allow Azure's internal DNS and Admin credentials to sync before the Web App tries to pull the image.

### Step 4: Update Application Environment

**Action:** Once the script finishes successfully, it will automatically update your `.env` file with the Azure credentials. However, you will still need to manually add your OpenAI API keys.

**Environment Variables to Add Manually:**
```bash
OPENAI_API_KEY=<your-openai-key>
AZURE_OPENAI_API_KEY=<your-azure-openai-key>
AZURE_OPENAI_ENDPOINT=<your-azure-openai-endpoint>
AZURE_OPENAI_API_VERSION=2023-05-15
AZURE_DEPLOYMENT=gpt-5-mini
AZURE_JUDGE_DEPLOYMENT=gpt-5-mini
AZURE_EMBEDDING_DEPLOYMENT=text-embedding-3-small
```

**Command to add these to your .env file:**
```bash
# Add the OpenAI variables to your application's .env
echo "OPENAI_API_KEY=<your-value>" >> .env
echo "AZURE_OPENAI_API_KEY=<your-value>" >> .env
echo "AZURE_OPENAI_ENDPOINT=<your-value>" >> .env
echo "AZURE_OPENAI_API_VERSION=2023-05-15" >> .env
echo "AZURE_DEPLOYMENT=gpt-5-mini" >> .env
echo "AZURE_JUDGE_DEPLOYMENT=gpt-4.1" >> .env
echo "AZURE_EMBEDDING_DEPLOYMENT=text-embedding-3-small" >> .env
```

### Step 5: Access the Application

**Action:** Your Streamlit application is now deployed! You can access it via the URL provided at the end of the `nra_deployment_script.sh` script output.

**Example URL:** `https://<your-web-app-name>.azurewebsites.net`

---

## 🧹 Resource Cleanup

To avoid ongoing cloud charges, you should delete the resources when you are done testing. We have provided a `nra_deployment_cleanup.sh` script that safely deletes the Web App, Container Registry, AI Search, Blob Container, and Storage Account, while leaving your main Resource Group intact.

```bash
# Make cleanup script executable
chmod +x nra_deployment_cleanup.sh

# Run cleanup
./nra_deployment_cleanup.sh
```

---

## 📞 Support & Troubleshooting

### Common Issues
1. **Authentication Errors**: Run `az login` to re-authenticate
2. **Resource Naming**: Ensure all resource names are globally unique
3. **Platform Issues**: Verify Docker build platform is set to `linux/amd64`

### Useful Commands
```bash
# Check Azure CLI status
az account show

# List all resources in resource group
az resource list --resource-group <your-resource-group>

# Check Docker platform
docker version --format '{{.Server.Arch}}'
```

---

**🎉 Happy deploying! Your Supply Chain LLMOps platform will be running in no time!**
