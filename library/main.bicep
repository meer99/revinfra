// Main Orchestrator
// Description: Main Bicep file that orchestrates the deployment of all resources
// Target Scope: subscription

targetScope = 'subscription'

@description('Environment name (dev, uat, prod)')
@allowed(['dev', 'uat', 'prod'])
param environment string

@description('Deploy Resource Group')
param deployResourceGroup bool = false

@description('Deploy Managed Identity')
param deployManagedIdentity bool = false

@description('Deploy Log Analytics Workspace')
param deployLogAnalyticsWorkspace bool = false

@description('Deploy Container Registry')
param deployContainerRegistry bool = false

@description('Deploy Container Apps Environment')
param deployContainerAppsEnvironment bool = false

@description('Deploy Container App Job - Bill')
param deployContainerAppJobBill bool = false

@description('Deploy Container App Job - Data')
param deployContainerAppJobData bool = false

@description('Deploy SQL Server')
param deploySqlServer bool = false

@description('Deploy SQL Database')
param deploySqlDatabase bool = false

// Load configuration files
var variables = loadJsonContent('variable/variable.json')
var commonTags = loadJsonContent('variable/tags.json')
var parametersAll = loadJsonContent('variable/parameters.json')
var envParams = parametersAll[environment]

// Merge tags with environment
var tags = union(commonTags, {
  Environment: environment
})

// Extract configuration
var location = variables.location
var namePatterns = variables.namePatterns

// 1. Deploy Resource Group
var resourceGroupName = '${namePatterns.resourceGroup}-${environment}'

module resourceGroup 'module/resourceGroup.bicep' = if (deployResourceGroup) {
  name: 'deploy-rg-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.resourceGroup
  }
}

// 2. Deploy resources to resource group
var shouldDeployResources = deployManagedIdentity || deployLogAnalyticsWorkspace || deployContainerRegistry || deployContainerAppsEnvironment || deployContainerAppJobBill || deployContainerAppJobData || deploySqlServer || deploySqlDatabase

module resources 'main-resources.bicep' = if (shouldDeployResources) {
  name: 'deploy-resources-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    environment: environment
    location: location
    tags: tags
    namePatterns: namePatterns
    envParams: envParams
    deployManagedIdentity: deployManagedIdentity
    deployLogAnalyticsWorkspace: deployLogAnalyticsWorkspace
    deployContainerRegistry: deployContainerRegistry
    deployContainerAppsEnvironment: deployContainerAppsEnvironment
    deployContainerAppJobBill: deployContainerAppJobBill
    deployContainerAppJobData: deployContainerAppJobData
    deploySqlServer: deploySqlServer
    deploySqlDatabase: deploySqlDatabase
  }
  dependsOn: [
    resourceGroup
  ]
}

// Outputs
output resourceGroupName string = deployResourceGroup ? resourceGroup.outputs.resourceGroupName : resourceGroupName
output managedIdentityId string = shouldDeployResources && deployManagedIdentity ? resources.outputs.managedIdentityId : ''
output containerRegistryName string = shouldDeployResources && deployContainerRegistry ? resources.outputs.containerRegistryName : ''
output containerRegistryLoginServer string = shouldDeployResources && deployContainerRegistry ? resources.outputs.containerRegistryLoginServer : ''
output containerAppsEnvironmentName string = shouldDeployResources && deployContainerAppsEnvironment ? resources.outputs.containerAppsEnvironmentName : ''
output sqlServerName string = shouldDeployResources && deploySqlServer ? resources.outputs.sqlServerName : ''
output sqlDatabaseName string = shouldDeployResources && deploySqlDatabase ? resources.outputs.sqlDatabaseName : ''
