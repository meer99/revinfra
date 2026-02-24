#!/bin/bash
set -e

ENVIRONMENT=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "$ENVIRONMENT" ]]; then
    echo "Usage: ./deploy.sh <environment>"
    echo "  e.g. ./deploy.sh dev1"
    exit 1
fi

echo "Deploying to '${ENVIRONMENT}'..."
az deployment sub create \
    --location australiaeast \
    --template-file "${SCRIPT_DIR}/main.bicep" \
    --parameters environment="$ENVIRONMENT" \
    --name "deploy-bcrev-${ENVIRONMENT}"
