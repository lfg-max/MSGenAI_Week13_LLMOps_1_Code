#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Load the environment variables from setup.env
source nra_setup.env

echo "========================================"
echo " Checking Azure Authentication..."
echo "========================================"

# Check if user is already logged in
if ! az account show > /dev/null 2>&1; then
    echo "You are not logged in to Azure."
    echo "Initiating login process..."
    az login
else
    echo "Already logged in to Azure."
fi

echo "========================================================"
echo " WARNING: INITIATING RESOURCE CLEANUP"
echo "========================================================"
echo "This will permanently delete the following resources from"
echo "the Resource Group: $RESOURCE_GROUP"
echo " - Web App: $WEB_APP_NAME"
echo " - App Service Plan: $APP_SERVICE_PLAN_NAME"
echo " - Container Registry: $ACR_NAME"
echo " - AI Search Service: $SEARCH_SERVICE_NAME"
echo " - Blob Container: $CONTAINER_NAME"
echo " - Storage Account: $STORAGE_ACCOUNT_NAME"
echo "--------------------------------------------------------"
echo "The Resource Group '$RESOURCE_GROUP' itself WILL NOT be deleted."
echo "Press Ctrl+C within 10 seconds to abort..."
sleep 10

echo -e "\n[1/6] Deleting Web App: $WEB_APP_NAME..."
az webapp delete --name "$WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" || echo "Web App not found."

echo -e "\n[2/6] Deleting App Service Plan: $APP_SERVICE_PLAN_NAME..."
az appservice plan delete --name "$APP_SERVICE_PLAN_NAME" --resource-group "$RESOURCE_GROUP" --yes || echo "Plan not found."

echo -e "\n[3/6] Deleting Container Registry: $ACR_NAME..."
az acr delete --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --yes || echo "ACR not found."

echo -e "\n[4/6] Deleting AI Search Service: $SEARCH_SERVICE_NAME..."
az search service delete --name "$SEARCH_SERVICE_NAME" --resource-group "$RESOURCE_GROUP" --yes || echo "Search service not found."

echo -e "\n[5/6] Deleting Blob Container: $CONTAINER_NAME..."
STORAGE_CONN_STR=$(az storage account show-connection-string --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --query connectionString -o tsv 2>/dev/null || echo "")
if [ -n "$STORAGE_CONN_STR" ]; then
    az storage container delete --name "$CONTAINER_NAME" --connection-string "$STORAGE_CONN_STR" || echo "Container not found."
fi

echo -e "\n[6/6] Deleting Storage Account: $STORAGE_ACCOUNT_NAME..."
az storage account delete --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --yes || echo "Storage account not found."

echo "========================================================"
echo " Cleanup Complete! Resource Group '$RESOURCE_GROUP' remains."
echo "========================================================"
