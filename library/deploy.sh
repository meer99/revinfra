#!/bin/bash
set -e

ENVIRONMENT=$1
MODE=$2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read subscription name from variable.json
SUBSCRIPTION_NAME=$(jq -r '.subscriptionName' "${SCRIPT_DIR}/variable/variable.json")
if [ -z "$SUBSCRIPTION_NAME" ] || [ "$SUBSCRIPTION_NAME" = "null" ]; then
    echo "ERROR: 'subscriptionName' not found in variable/variable.json"
    exit 1
fi

# Set the target subscription explicitly to avoid wrong-tenant errors
echo "Setting subscription to '${SUBSCRIPTION_NAME}'..."
az account set --subscription "$SUBSCRIPTION_NAME" || { echo "ERROR: Failed to set subscription '${SUBSCRIPTION_NAME}'. Verify the subscription name and your access."; exit 1; }

if [ "$MODE" = "--what-if" ]; then
    echo "Running What-If for '${ENVIRONMENT}'..."
    az deployment sub what-if \
        --location australiaeast \
        --template-file "${SCRIPT_DIR}/main.bicep" \
        --parameters environment="$ENVIRONMENT" \
        --name "deploy-bcrev-${ENVIRONMENT}"
elif [ "$MODE" = "--confirm" ]; then
    echo "Deploying to '${ENVIRONMENT}'..."
    az deployment sub create \
        --location australiaeast \
        --template-file "${SCRIPT_DIR}/main.bicep" \
        --parameters environment="$ENVIRONMENT" \
        --name "deploy-bcrev-${ENVIRONMENT}"
else
    echo "ERROR: Deployment requires --confirm or --what-if flag."
    echo "Usage: ./deploy.sh <environment> --confirm"
    echo "       ./deploy.sh <environment> --what-if"
    exit 1
fi
