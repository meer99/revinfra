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

echo "Deploying to '${ENVIRONMENT}'..."
az deployment sub create \
    --location australiaeast \
    --template-file "${SCRIPT_DIR}/main.bicep" \
    --parameters environment="$ENVIRONMENT" \
    --name "deploy-bcrev-${ENVIRONMENT}"
