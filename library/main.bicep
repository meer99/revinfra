// Main Orchestrator
// Description: Main Bicep file that orchestrates the deployment of all resources
// Target Scope: subscription

targetScope = 'subscription'

@description('Environment name (dev, uat, prod)')
@allowed(['dev', 'uat', 'prod'])
param environment string

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
var vnetName = variables.vnetName
var subnetName = variables.subnetName
var existingVnetResourceGroup = envParams.existingVnetResourceGroup

// 1. Deploy Resource Group
var resourceGroupName = '${namePatterns.resourceGroup}-${environment}'

module resourceGroup 'module/resourceGroup.bicep' = if (envParams.deployResourceGroup) {
  name: 'deploy-rg-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.resourceGroup
  }
}

// 2. Deploy resources to resource group
module resources 'main-resources.bicep' = {
  name: 'deploy-resources-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    environment: environment
    location: location
    tags: tags
    namePatterns: namePatterns
    vnetName: vnetName
    subnetName: subnetName
    existingVnetResourceGroup: existingVnetResourceGroup
    envParams: envParams
  }
  dependsOn: [
    resourceGroup
  ]
}

// Outputs
output resourceGroupName string = envParams.deployResourceGroup ? resourceGroup.outputs.resourceGroupName : resourceGroupName
output managedIdentityId string = envParams.deployManagedIdentity ? resources.outputs.managedIdentityId : ''
output containerRegistryName string = envParams.deployContainerRegistry ? resources.outputs.containerRegistryName : ''
output containerRegistryLoginServer string = envParams.deployContainerRegistry ? resources.outputs.containerRegistryLoginServer : ''
output containerAppsEnvironmentName string = envParams.deployContainerAppsEnvironment ? resources.outputs.containerAppsEnvironmentName : ''
output sqlServerName string = envParams.deploySqlServer ? resources.outputs.sqlServerName : ''
output sqlDatabaseName string = envParams.deploySqlDatabase ? resources.outputs.sqlDatabaseName : ''
