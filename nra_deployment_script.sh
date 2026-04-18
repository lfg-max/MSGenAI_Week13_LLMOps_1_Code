#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Load the environment variables from setup.env
source nra_setup.env

# Helper function to display a countdown timer
countdown() {
    local secs=$1
    while [ $secs -gt 0 ]; do
        printf "\rWaiting... %d seconds remaining \033[K" "$secs"
        sleep 1
        ((secs--))
    done
    echo ""
}

echo "========================================"
echo " Checking Azure Authentication..."
echo "========================================"

if ! az account show > /dev/null 2>&1; then
    echo "You are not logged in to Azure. Initiating login..."
    az login
else
    echo "Already logged in to Azure."
fi

echo "========================================"
echo " Checking Required Environment Variables..."
echo "========================================"

# Check for OpenAI API Key
if [ ! -f .env ]; then
    echo "Creating .env file..."
    touch .env
fi

OPENAI_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2 | tr -d '"')
if [ -z "$OPENAI_KEY" ]; then
    echo "WARNING: OPENAI_API_KEY not found in .env file."
    echo "Please set OPENAI_API_KEY in .env before running the app."
    echo "The deployment will continue, but you'll need to add this manually."
else
    echo "✓ OPENAI_API_KEY found in .env"
fi

# Validate Azure OpenAI deployment
echo "========================================"
echo " Validating Azure OpenAI Deployment..."
echo "========================================"

AZURE_ENDPOINT=$(grep "^AZURE_OPENAI_ENDPOINT=" .env | cut -d'=' -f2 | tr -d '"')
AZURE_DEPLOYMENT=$(grep "^AZURE_DEPLOYMENT=" .env | cut -d'=' -f2 | tr -d '"')

if [ -n "$AZURE_ENDPOINT" ] && [ -n "$AZURE_DEPLOYMENT" ]; then
    echo "Checking Azure OpenAI deployment: $AZURE_DEPLOYMENT"
    
    # Extract account name from endpoint
    ACCOUNT_NAME=$(echo "$AZURE_ENDPOINT" | sed -n 's|https://\([^\.]*\).*|\1|p')
    RESOURCE_GROUP=$(az cognitiveservices account show --name "$ACCOUNT_NAME" --query resourceGroup -o tsv 2>/dev/null)
    
    if [ -n "$RESOURCE_GROUP" ]; then
        # Check if deployment exists
        DEPLOYMENT_EXISTS=$(az cognitiveservices account deployment show --name "$ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --deployment-name "$AZURE_DEPLOYMENT" --query name -o tsv 2>/dev/null)
        
        if [ "$DEPLOYMENT_EXISTS" == "$AZURE_DEPLOYMENT" ]; then
            echo "✓ Azure OpenAI deployment '$AZURE_DEPLOYMENT' exists and is accessible"
            
            # Get deployment details
            MODEL_VERSION=$(az cognitiveservices account deployment show --name "$ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --deployment-name "$AZURE_DEPLOYMENT" --query properties.model.version -o tsv 2>/dev/null)
            if [ -n "$MODEL_VERSION" ]; then
                echo "  Model version: $MODEL_VERSION"
            fi
        else
            echo "WARNING: Azure OpenAI deployment '$AZURE_DEPLOYMENT' not found in account '$ACCOUNT_NAME'"
            echo "Please verify the deployment name in .env matches your Azure OpenAI resource"
        fi
    else
        echo "WARNING: Could not determine resource group for Azure OpenAI account '$ACCOUNT_NAME'"
        echo "Skipping deployment validation"
    fi
else
    echo "WARNING: AZURE_OPENAI_ENDPOINT or AZURE_DEPLOYMENT not set in .env"
    echo "Skipping Azure OpenAI deployment validation"
fi

echo "========================================"
echo " Starting Azure Infrastructure Setup..."
echo "========================================"

# 1. Verify Existing Resource Group
echo -e "\n[1/6] Verifying Resource Group: $RESOURCE_GROUP..."
az group show --name "$RESOURCE_GROUP" -o none || { echo "Error: Resource group '$RESOURCE_GROUP' does not exist."; exit 1; }

# 2. Create Storage Account & BLOB CONTAINER
echo -e "\n[2/6] Provisioning Storage Account: $STORAGE_ACCOUNT_NAME..."
az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION_STORAGE" \
    --sku "$STORAGE_SKU" \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access true \
    -o none

echo "Waiting for Storage APIs to stabilize..."
countdown 15

STORAGE_CONN_STR=$(az storage account show-connection-string --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --query connectionString -o tsv)

echo "Creating Blob Container: $CONTAINER_NAME..."
MAX_RETRIES=5
COUNT=0
until az storage container create --name "$CONTAINER_NAME" --connection-string "$STORAGE_CONN_STR" --public-access blob -o none || [ $COUNT -eq $MAX_RETRIES ]; do
    echo "Retrying container creation... ($((COUNT+1))/$MAX_RETRIES)"
    countdown 5
    ((COUNT++))
done

# --- DATA UPLOAD ---
ABS_DATA_PATH=$(realpath "$LOCAL_DATA_FOLDER")
if [ -d "$ABS_DATA_PATH" ]; then
    echo "Uploading local data..."
    az storage blob upload-batch --destination "$CONTAINER_NAME" --source "$ABS_DATA_PATH" --connection-string "$STORAGE_CONN_STR" --overwrite -o none
fi

# 3. Create Azure AI Search (Vector Database)
echo -e "\n[3/6] Provisioning Azure AI Search: $SEARCH_SERVICE_NAME..."
az search service create --name "$SEARCH_SERVICE_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION_SEARCH" --sku "$SEARCH_SKU" -o none || true
SEARCH_ADMIN_KEY=$(az search admin-key show --resource-group "$RESOURCE_GROUP" --service-name "$SEARCH_SERVICE_NAME" --query primaryKey -o tsv)
SEARCH_ENDPOINT="https://${SEARCH_SERVICE_NAME}.search.windows.net/"

# 4. Create Azure Container Registry (ACR)
echo -e "\n[4/6] Provisioning ACR: $ACR_NAME..."
az acr create --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION_ACR" --sku "$ACR_SKU" --admin-enabled true -o none
az acr update -n "$ACR_NAME" --admin-enabled true -o none

ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" -o tsv)

echo "CRITICAL: Waiting for ACR Admin credentials to propagate across Azure regions..."
countdown 60

# 5. Build and Push Docker Image
echo -e "\n[5/6] Building and Pushing Image..."
az acr login --name "$ACR_NAME"
docker build --platform linux/amd64 -t "$IMAGE_NAME:$IMAGE_TAG" .
docker tag "$IMAGE_NAME:$IMAGE_TAG" "$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"

# 6. Create App Service & Web App
echo -e "\n[6/6] Provisioning Web App: $WEB_APP_NAME..."
az appservice plan create --name "$APP_SERVICE_PLAN_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION_WEBAPP" --is-linux --sku "$WEBAPP_SKU" -o none

az webapp create \
    --resource-group "$RESOURCE_GROUP" \
    --plan "$APP_SERVICE_PLAN_NAME" \
    --name "$WEB_APP_NAME" \
    --container-image-name "mcr.microsoft.com/appsvc/staticsite:latest" \
    -o none

echo "Setting Registry Credentials and App Settings..."
az webapp config appsettings set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$WEB_APP_NAME" \
    --settings \
    WEBSITES_PORT=8501 \
    DOCKER_REGISTRY_SERVER_URL="https://$ACR_LOGIN_SERVER" \
    DOCKER_REGISTRY_SERVER_USERNAME="$ACR_NAME" \
    DOCKER_REGISTRY_SERVER_PASSWORD="$ACR_PASSWORD" \
    DOCKER_CUSTOM_IMAGE_NAME="$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG" \
    AZURE_SEARCH_ENDPOINT="${SEARCH_ENDPOINT}" \
    AZURE_SEARCH_KEY="${SEARCH_ADMIN_KEY}" \
    AZURE_SEARCH_INDEX="supply-chain-index" \
    VECTOR_STORE_TYPE="azure" \
    -o none

echo "Switching Web App to the custom ACR image..."
az webapp config container set \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --container-image-name "$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG" \
    --container-registry-url "https://$ACR_LOGIN_SERVER" \
    --container-registry-user "$ACR_NAME" \
    --container-registry-password "$ACR_PASSWORD" \
    -o none

echo "Restarting Web App and verifying status..."
az webapp restart --name "$WEB_APP_NAME" --resource-group "$RESOURCE_GROUP"

echo "Waiting for container startup..."
countdown 45

# --- AUTO UPDATE .ENV FILE ---
echo -e "\n========================================"
echo " Updating local .env file..."
echo "========================================"

# Helper function to safely update or append variables in .env without losing existing ones
update_env_var() {
    local key=$1
    local val=$2
    local file=".env"
    
    # Create the file if it doesn't exist
    touch "$file"
    
    # If the key already exists, replace that line. Otherwise, append it.
    if grep -q "^${key}=" "$file"; then
        # Read line by line to safely handle special characters (like '=' or '/' in keys)
        while IFS= read -r line || [ -n "$line" ]; do
            if [[ "$line" == "$key="* ]]; then
                echo "${key}=\"${val}\""
            else
                echo "$line"
            fi
        done < "$file" > "${file}.tmp"
        mv "${file}.tmp" "$file"
    else
        echo "${key}=\"${val}\"" >> "$file"
    fi
}

# Update Azure AI Search credentials
update_env_var "AZURE_SEARCH_ENDPOINT" "${SEARCH_ENDPOINT}"
update_env_var "AZURE_SEARCH_KEY" "${SEARCH_ADMIN_KEY}"
update_env_var "AZURE_SEARCH_INDEX" "supply-chain-index"

# Update Azure Storage credentials
update_env_var "AZURE_STORAGE_CONNECTION_STRING" "${STORAGE_CONN_STR}"
update_env_var "AZURE_STORAGE_CONTAINER_NAME" "${CONTAINER_NAME}"

# Validate Azure Search credentials are set
if [ -n "${SEARCH_ENDPOINT}" ] && [ -n "${SEARCH_ADMIN_KEY}" ]; then
    echo "✓ Azure Search credentials validated"
else
    echo "WARNING: Azure Search credentials may not be properly set"
fi

echo "Successfully updated credentials in the .env file!"

echo "========================================"
echo " VERIFYING RUNTIME STATUS"
echo "========================================"
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://${WEB_APP_NAME}.azurewebsites.net")

if [ "$STATUS_CODE" -eq 200 ] || [ "$STATUS_CODE" -eq 301 ]; then
    echo "SUCCESS: App is reachable (HTTP $STATUS_CODE)"
else
    echo "WARNING: App returned HTTP $STATUS_CODE. Checking internal logs..."
    az webapp log tail --name "$WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" --lines 30 &
    LOG_PID=$!
    countdown 10
    kill $LOG_PID || true
fi

echo "========================================"
echo " Deployment Summary"
echo " URL: https://${WEB_APP_NAME}.azurewebsites.net"
echo " Note: Your .env file is updated with Azure credentials."
echo " IMPORTANT: Ensure OPENAI_API_KEY and AZURE_OPENAI_API_KEY are set in .env"
echo "           or add them via Azure Web App Configuration for the app to function."
echo "========================================"
