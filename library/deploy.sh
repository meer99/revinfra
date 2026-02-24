#!/bin/bash
set -e

# Configuration
VALID_ENVIRONMENTS=("dev1" "sit" "uat" "prod")
LOCATION="australiaeast"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/main.bicep"

# Usage
usage() {
    echo "Usage: ./deploy.sh <environment> [--what-if | --confirm]"
    echo ""
    echo "Environments: ${VALID_ENVIRONMENTS[*]}"
    echo ""
    echo "Options:"
    echo "  --what-if    Preview changes without deploying"
    echo "  --confirm    Deploy infrastructure to the environment"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh dev1 --what-if     # Preview Dev1 changes"
    echo "  ./deploy.sh dev1 --confirm     # Deploy to Dev1"
    exit 1
}

# Validate environment
validate_environment() {
    local env="$1"
    for valid in "${VALID_ENVIRONMENTS[@]}"; do
        if [[ "$env" == "$valid" ]]; then
            return 0
        fi
    done
    echo "ERROR: Invalid environment '${env}'."
    echo "Valid environments: ${VALID_ENVIRONMENTS[*]}"
    exit 1
}

# Parse arguments
ENVIRONMENT="$1"
MODE="$2"

if [[ -z "$ENVIRONMENT" || -z "$MODE" ]]; then
    usage
fi

validate_environment "$ENVIRONMENT"

# Execute deployment
DEPLOYMENT_NAME="deploy-bcrev-${ENVIRONMENT}"

if [[ "$MODE" == "--what-if" ]]; then
    echo "Running What-If for '${ENVIRONMENT}'..."
    az deployment sub what-if \
        --location "$LOCATION" \
        --template-file "$TEMPLATE_FILE" \
        --parameters environment="$ENVIRONMENT" \
        --name "$DEPLOYMENT_NAME"
elif [[ "$MODE" == "--confirm" ]]; then
    echo "Deploying to '${ENVIRONMENT}'..."
    az deployment sub create \
        --location "$LOCATION" \
        --template-file "$TEMPLATE_FILE" \
        --parameters environment="$ENVIRONMENT" \
        --name "$DEPLOYMENT_NAME"
else
    echo "ERROR: Unknown option '${MODE}'."
    usage
fi
