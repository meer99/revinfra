#!/bin/bash
set -e

ENVIRONMENT=$1
DEPLOY_RESOURCE_GROUP=$2
DEPLOY_MANAGED_IDENTITY=$3
DEPLOY_LOG_ANALYTICS_WORKSPACE=$4
DEPLOY_CONTAINER_REGISTRY=$5
DEPLOY_CONTAINER_APPS_ENVIRONMENT=$6
DEPLOY_CONTAINER_APP_JOB_BILL=$7
DEPLOY_CONTAINER_APP_JOB_DATA=$8
DEPLOY_SQL_SERVER=$9
DEPLOY_SQL_DATABASE=${10}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying to '${ENVIRONMENT}'..."
az deployment sub create \
    --location australiaeast \
    --template-file "${SCRIPT_DIR}/main.bicep" \
    --parameters environment="$ENVIRONMENT" \
    --parameters deployResourceGroup="$DEPLOY_RESOURCE_GROUP" \
    --parameters deployManagedIdentity="$DEPLOY_MANAGED_IDENTITY" \
    --parameters deployLogAnalyticsWorkspace="$DEPLOY_LOG_ANALYTICS_WORKSPACE" \
    --parameters deployContainerRegistry="$DEPLOY_CONTAINER_REGISTRY" \
    --parameters deployContainerAppsEnvironment="$DEPLOY_CONTAINER_APPS_ENVIRONMENT" \
    --parameters deployContainerAppJobBill="$DEPLOY_CONTAINER_APP_JOB_BILL" \
    --parameters deployContainerAppJobData="$DEPLOY_CONTAINER_APP_JOB_DATA" \
    --parameters deploySqlServer="$DEPLOY_SQL_SERVER" \
    --parameters deploySqlDatabase="$DEPLOY_SQL_DATABASE" \
    --name "deploy-rebc-${ENVIRONMENT}"
