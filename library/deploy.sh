#!/bin/bash

# Deploy Script for REBC Infrastructure
# Called by Azure DevOps pipeline or manually
# Usage: ./deploy.sh <environment>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <environment> (dev|uat|prod)"
    exit 1
fi

ENVIRONMENT=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_FILE="${SCRIPT_DIR}/main.bicep"

if [[ ! "$ENVIRONMENT" =~ ^(dev|uat|prod)$ ]]; then
    echo "Error: Invalid environment '${ENVIRONMENT}'. Valid: dev, uat, prod"
    exit 1
fi

if [ ! -f "$BICEP_FILE" ]; then
    echo "Error: Bicep file not found at ${BICEP_FILE}"
    exit 1
fi

DEPLOYMENT_NAME="deploy-rebc-${ENVIRONMENT}-${BUILD_BUILDID:-$(date +%Y%m%d-%H%M%S)}"
RESOURCE_GROUP="rg-rebc-${ENVIRONMENT}"

# Delete resources that cannot be updated in-place before redeployment.
# - Private endpoints cannot change subnets (moving from snet-rebc to snet-bcr).
# - Container Apps Environment must be recreated with workload profiles enabled.
# - Container app jobs and CAE private endpoint depend on the CAE and must be deleted first.

echo "Cleaning up resources that require recreation in '${RESOURCE_GROUP}'..."

# Check if the resource group exists before attempting deletions
if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    # Delete container app jobs (depend on CAE)
    for JOB_NAME in "caj-bill-${ENVIRONMENT}" "caj-data-${ENVIRONMENT}"; do
        if az containerapp job show --name "$JOB_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
            echo "Deleting container app job '${JOB_NAME}'..."
            az containerapp job delete --name "$JOB_NAME" --resource-group "$RESOURCE_GROUP" --yes
        fi
    done

    # Delete private endpoints (cannot change subnet in-place)
    for PE_NAME in "pe-cae-${ENVIRONMENT}" "pe-cr-${ENVIRONMENT}" "pe-sql-${ENVIRONMENT}"; do
        if az network private-endpoint show --name "$PE_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
            echo "Deleting private endpoint '${PE_NAME}'..."
            az network private-endpoint delete --name "$PE_NAME" --resource-group "$RESOURCE_GROUP"
        fi
    done

    # Delete Container Apps Environment (must be recreated with workload profiles)
    CAE_NAME="cae-rebc-${ENVIRONMENT}"
    if az containerapp env show --name "$CAE_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
        echo "Deleting Container Apps Environment '${CAE_NAME}'..."
        az containerapp env delete --name "$CAE_NAME" --resource-group "$RESOURCE_GROUP" --yes
    fi
fi

echo "Deploying to '${ENVIRONMENT}'..."
az deployment sub create \
    --location australiaeast \
    --template-file "$BICEP_FILE" \
    --parameters environment="$ENVIRONMENT" \
    --name "$DEPLOYMENT_NAME"

echo "Deployment complete."
