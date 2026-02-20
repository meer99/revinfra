#!/bin/bash
set -e

ENVIRONMENT=$1
CONFIRM=$2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$CONFIRM" != "--confirm" ]; then
    echo "ERROR: Deployment requires explicit confirmation."
    echo "Usage: ./deploy.sh <environment> --confirm"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d%H%M%S)
DEPLOYMENT_NAME="deploy-bcrev-${ENVIRONMENT}-${TIMESTAMP}"

echo "Deploying to '${ENVIRONMENT}' (${DEPLOYMENT_NAME})..."
az deployment sub create \
    --location australiaeast \
    --template-file "${SCRIPT_DIR}/main.bicep" \
    --parameters environment="$ENVIRONMENT" \
    --name "$DEPLOYMENT_NAME"
