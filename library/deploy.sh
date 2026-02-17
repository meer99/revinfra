#!/bin/bash
set -e

ENVIRONMENT=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying to '${ENVIRONMENT}'..."
az deployment sub create \
    --location australiaeast \
    --template-file "${SCRIPT_DIR}/main.bicep" \
    --parameters environment="$ENVIRONMENT" \
    --name "deploy-rebc-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"
