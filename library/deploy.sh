#!/bin/bash
set -e

ENVIRONMENT=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "$ENVIRONMENT" ]]; then
    echo "Usage: ./deploy.sh <environment>"
    echo "  e.g. ./deploy.sh dev1"
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
