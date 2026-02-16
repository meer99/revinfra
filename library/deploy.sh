#!/bin/bash

################################################################################
# Deploy Script for REBC Infrastructure
# Description: Deploys Azure infrastructure using Bicep templates
# Usage: ./deploy.sh <environment>
# Example: ./deploy.sh dev
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print section headers
print_header() {
    echo ""
    print_message "${GREEN}" "===================================="
    print_message "${GREEN}" "$1"
    print_message "${GREEN}" "===================================="
    echo ""
}

# Check if environment parameter is provided
if [ -z "$1" ]; then
    print_message "${RED}" "Error: Environment parameter is required"
    echo "Usage: $0 <environment>"
    echo "Valid environments: dev, uat, prod"
    exit 1
fi

ENVIRONMENT=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_FILE="${SCRIPT_DIR}/main.bicep"
DEPLOYMENT_NAME="deploy-rebc-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|uat|prod)$ ]]; then
    print_message "${RED}" "Error: Invalid environment '${ENVIRONMENT}'"
    echo "Valid environments: dev, uat, prod"
    exit 1
fi

# Check if Bicep file exists
if [ ! -f "$BICEP_FILE" ]; then
    print_message "${RED}" "Error: Bicep file not found at ${BICEP_FILE}"
    exit 1
fi

print_header "REBC Infrastructure Deployment"
print_message "${YELLOW}" "Environment: ${ENVIRONMENT}"
print_message "${YELLOW}" "Deployment Name: ${DEPLOYMENT_NAME}"
print_message "${YELLOW}" "Bicep File: ${BICEP_FILE}"

# Check if user is logged in to Azure
print_header "Checking Azure Login Status"
if ! az account show &> /dev/null; then
    print_message "${RED}" "Error: Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
print_message "${GREEN}" "✓ Logged in to Azure"
print_message "${YELLOW}" "  Subscription: ${SUBSCRIPTION_NAME}"
print_message "${YELLOW}" "  Subscription ID: ${SUBSCRIPTION_ID}"

# Validate Bicep file
print_header "Validating Bicep Template"
if az deployment sub validate \
    --location australiaeast \
    --template-file "$BICEP_FILE" \
    --parameters environment="$ENVIRONMENT" \
    --output none; then
    print_message "${GREEN}" "✓ Bicep template validation successful"
else
    print_message "${RED}" "✗ Bicep template validation failed"
    exit 1
fi

# Perform What-If analysis
print_header "What-If Analysis"
print_message "${YELLOW}" "Analyzing what changes will be made..."
az deployment sub what-if \
    --location australiaeast \
    --template-file "$BICEP_FILE" \
    --parameters environment="$ENVIRONMENT" \
    --name "$DEPLOYMENT_NAME"

# Ask for confirmation
echo ""
read -p "Do you want to proceed with the deployment? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    print_message "${YELLOW}" "Deployment cancelled by user"
    exit 0
fi

# Deploy
print_header "Deploying Infrastructure"
print_message "${YELLOW}" "Starting deployment..."

if az deployment sub create \
    --location australiaeast \
    --template-file "$BICEP_FILE" \
    --parameters environment="$ENVIRONMENT" \
    --name "$DEPLOYMENT_NAME" \
    --output json > /tmp/deployment-output.json; then
    
    print_message "${GREEN}" "✓ Deployment successful!"
    
    # Extract outputs
    print_header "Deployment Outputs"
    
    RESOURCE_GROUP=$(jq -r '.properties.outputs.resourceGroupName.value' /tmp/deployment-output.json 2>/dev/null || echo "N/A")
    CONTAINER_REGISTRY=$(jq -r '.properties.outputs.containerRegistryName.value' /tmp/deployment-output.json 2>/dev/null || echo "N/A")
    ACR_LOGIN_SERVER=$(jq -r '.properties.outputs.containerRegistryLoginServer.value' /tmp/deployment-output.json 2>/dev/null || echo "N/A")
    SQL_SERVER=$(jq -r '.properties.outputs.sqlServerName.value' /tmp/deployment-output.json 2>/dev/null || echo "N/A")
    
    print_message "${GREEN}" "Resource Group: ${RESOURCE_GROUP}"
    print_message "${GREEN}" "Container Registry: ${CONTAINER_REGISTRY}"
    print_message "${GREEN}" "ACR Login Server: ${ACR_LOGIN_SERVER}"
    print_message "${GREEN}" "SQL Server: ${SQL_SERVER}"
    
    # Post-deployment steps
    print_header "Post-Deployment Steps"
    
    if [ "$CONTAINER_REGISTRY" != "N/A" ] && [ "$CONTAINER_REGISTRY" != "" ]; then
        print_message "${YELLOW}" "To push an image to the container registry:"
        echo ""
        echo "  1. Build your Docker image:"
        echo "     docker build -t myapp:latest ."
        echo ""
        echo "  2. Tag the image for ACR:"
        echo "     docker tag myapp:latest ${ACR_LOGIN_SERVER}/myapp:latest"
        echo ""
        echo "  3. Login to ACR (using managed identity or service principal):"
        echo "     az acr login --name ${CONTAINER_REGISTRY}"
        echo ""
        echo "  4. Push the image:"
        echo "     docker push ${ACR_LOGIN_SERVER}/myapp:latest"
        echo ""
        echo "  Note: Since the registry has public access disabled, you'll need to push"
        echo "        from a machine that has access to the private endpoint or use Azure CLI"
        echo "        with appropriate permissions."
        echo ""
    fi
    
    print_message "${GREEN}" "Deployment completed successfully!"
    
else
    print_message "${RED}" "✗ Deployment failed!"
    exit 1
fi

# Cleanup
rm -f /tmp/deployment-output.json

print_header "Done"
