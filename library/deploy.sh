#!/bin/bash

# Deploy Script for REBC Infrastructure
# Usage: ./deploy.sh <environment>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <environment> (dev|uat|prod)"
    exit 1
fi

ENVIRONMENT=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_FILE="${SCRIPT_DIR}/main.bicep"
DEPLOYMENT_NAME="deploy-rebc-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"

if [[ ! "$ENVIRONMENT" =~ ^(dev|uat|prod)$ ]]; then
    echo "Error: Invalid environment '${ENVIRONMENT}'. Valid: dev, uat, prod"
    exit 1
fi

if [ ! -f "$BICEP_FILE" ]; then
    echo "Error: Bicep file not found at ${BICEP_FILE}"
    exit 1
fi

# What-If analysis
echo "Running What-If analysis for '${ENVIRONMENT}'..."
az deployment sub what-if \
    --location australiaeast \
    --template-file "$BICEP_FILE" \
    --parameters environment="$ENVIRONMENT" \
    --name "$DEPLOYMENT_NAME"

# Confirm and deploy
read -p "Proceed with deployment? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo "Deploying to '${ENVIRONMENT}'..."
az deployment sub create \
    --location australiaeast \
    --template-file "$BICEP_FILE" \
    --parameters environment="$ENVIRONMENT" \
    --name "$DEPLOYMENT_NAME"

echo "Deployment complete."
