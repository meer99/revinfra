#!/bin/bash
set -e

ENVIRONMENT=$1
MODE=$2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
