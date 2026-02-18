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
var deployResources = envParams.deployManagedIdentity || envParams.deployLogAnalyticsWorkspace || envParams.deployContainerRegistry || envParams.deployContainerAppsEnvironment || envParams.deployContainerAppJobBill || envParams.deployContainerAppJobData || envParams.deploySqlServer || envParams.deploySqlDatabase

module resources 'main-resources.bicep' = if (deployResources) {
  name: 'deploy-resources-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    environment: environment
    location: location
    tags: tags
    namePatterns: namePatterns
    envParams: envParams
  }
  dependsOn: [
    resourceGroup
  ]
}

// 4. Deploy private endpoints to the existing network resource group
var deployNetworkResources = envParams.deployPrivateEndpointCr || envParams.deployPrivateEndpointCae || envParams.deployPrivateEndpointSql

module networkResources 'main-network-resources.bicep' = if (deployNetworkResources) {
  name: 'deploy-network-resources-${environment}'
  scope: az.resourceGroup(existingNetworkResourceGroup)
  params: {
    environment: environment
    location: location
    tags: tags
    namePatterns: namePatterns
    envParams: envParams
    containerRegistryId: deployResources && envParams.deployContainerRegistry ? resources.outputs.containerRegistryId : ''
    containerAppsEnvironmentId: deployResources && envParams.deployContainerAppsEnvironment ? resources.outputs.containerAppsEnvironmentId : ''
    sqlServerId: deployResources && envParams.deploySqlServer ? resources.outputs.sqlServerId : ''
    existingVirtualNetworkName: existingVirtualNetwork
    existingSubnetName: existingSubnet
  }
  dependsOn: [
    resources
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
output virtualNetworkName string = deployNetworkResources ? networkResources.outputs.virtualNetworkName : ''
output privateEndpointCrName string = deployNetworkResources && envParams.deployPrivateEndpointCr ? networkResources.outputs.privateEndpointCrName : ''
output privateEndpointCaeName string = deployNetworkResources && envParams.deployPrivateEndpointCae ? networkResources.outputs.privateEndpointCaeName : ''
output privateEndpointSqlName string = deployNetworkResources && envParams.deployPrivateEndpointSql ? networkResources.outputs.privateEndpointSqlName : ''
