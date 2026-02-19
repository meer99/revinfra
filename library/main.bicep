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
var existingNetworkResourceGroup = variables.existingNetworkResourceGroup
var existingVirtualNetwork = variables.existingVirtualNetwork
var existingSubnet = variables.existingSubnet

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

// 2. Deploy Network Resource Group
var networkResourceGroupName = '${namePatterns.networkResourceGroup}-${environment}'

module networkResourceGroup 'module/resourceGroup.bicep' = if (envParams.deployNetworkResourceGroup) {
  name: 'deploy-rg-net-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.networkResourceGroup
  }
}

// 3. Deploy resources to resource group
var deployResources = envParams.deployManagedIdentity || envParams.deployLogAnalyticsWorkspace || envParams.deployContainerRegistry || envParams.deployContainerAppsEnvironment || envParams.deployContainerAppJobBill || envParams.deployContainerAppJobData || envParams.deploySqlServer || envParams.deploySqlDatabase || envParams.deployPrivateEndpointCr || envParams.deployPrivateEndpointCae || envParams.deployPrivateEndpointSql

module resources 'main-resources.bicep' = if (deployResources) {
  name: 'deploy-resources-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    environment: environment
    location: location
    tags: tags
    namePatterns: namePatterns
    envParams: envParams
    existingVirtualNetworkName: existingVirtualNetwork
    existingSubnetName: existingSubnet
    existingNetworkResourceGroupName: existingNetworkResourceGroup
  }
  dependsOn: [
    resourceGroup
  ]
}

// Outputs
output resourceGroupName string = envParams.deployResourceGroup ? resourceGroup.outputs.resourceGroupName : resourceGroupName
output networkResourceGroupName string = envParams.deployNetworkResourceGroup ? networkResourceGroup.outputs.resourceGroupName : networkResourceGroupName
output managedIdentityId string = deployResources && envParams.deployManagedIdentity ? resources.outputs.managedIdentityId : ''
output containerRegistryName string = deployResources && envParams.deployContainerRegistry ? resources.outputs.containerRegistryName : ''
output containerRegistryLoginServer string = deployResources && envParams.deployContainerRegistry ? resources.outputs.containerRegistryLoginServer : ''
output containerAppsEnvironmentName string = deployResources && envParams.deployContainerAppsEnvironment ? resources.outputs.containerAppsEnvironmentName : ''
output sqlServerName string = deployResources && envParams.deploySqlServer ? resources.outputs.sqlServerName : ''
output sqlDatabaseName string = deployResources && envParams.deploySqlDatabase ? resources.outputs.sqlDatabaseName : ''
output privateEndpointCrName string = deployResources && envParams.deployPrivateEndpointCr ? resources.outputs.privateEndpointCrName : ''
output privateEndpointCaeName string = deployResources && envParams.deployPrivateEndpointCae ? resources.outputs.privateEndpointCaeName : ''
output privateEndpointSqlName string = deployResources && envParams.deployPrivateEndpointSql ? resources.outputs.privateEndpointSqlName : ''
