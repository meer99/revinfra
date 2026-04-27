// Main Orchestrator
// Description: Main Bicep file that orchestrates the deployment of all resources
// Target Scope: subscription (uses existing resource group)

targetScope = 'subscription'

@description('Environment name (dev1, sit, uat, prod)')
@allowed(['dev1', 'sit', 'uat', 'prod'])
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
var names = variables.names
// Construct the subnet resource ID explicitly to avoid cross-resource-group scope issues
var subnetId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${variables.networkResourceGroup}/providers/Microsoft.Network/virtualNetworks/${variables.virtualNetwork}/subnets/${variables.subnet}'

// Construct private DNS zone resource IDs
var privateDnsZoneIdCr = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${variables.networkResourceGroup}/providers/Microsoft.Network/privateDnsZones/${variables.privateDnsZones.containerRegistry}'
var privateDnsZoneIdSql = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${variables.networkResourceGroup}/providers/Microsoft.Network/privateDnsZones/${variables.privateDnsZones.sqlServer}'
var privateDnsZoneIdCae = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${variables.networkResourceGroup}/providers/Microsoft.Network/privateDnsZones/${variables.privateDnsZones.containerAppsEnvironment}'

// Use existing resource group
var resourceGroupName = variables.resourceGroup

// Deploy resources to existing resource group
var deployResources = envParams.deployManagedIdentity || envParams.deployLogAnalyticsWorkspace || envParams.deployContainerRegistry || envParams.deployContainerAppsEnvironment || envParams.deployContainerAppJobaccsync || envParams.deployContainerAppJobsah || envParams.deploySqlServer || envParams.deploySqlDatabase

module resources 'main-resources.bicep' = if (deployResources) {
  name: 'deploy-resources-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    environment: environment
    location: location
    tags: tags
    names: names
    envParams: envParams
    subnetId: subnetId
    privateDnsZoneIdCr: privateDnsZoneIdCr
    privateDnsZoneIdSql: privateDnsZoneIdSql
    privateDnsZoneIdCae: privateDnsZoneIdCae
  }
}

// Outputs
output resourceGroupName string = resourceGroupName
output managedIdentityId string = resources.?outputs.managedIdentityId ?? ''
output containerRegistryName string = resources.?outputs.containerRegistryName ?? ''
output containerRegistryLoginServer string = resources.?outputs.containerRegistryLoginServer ?? ''
output containerAppsEnvironmentName string = resources.?outputs.containerAppsEnvironmentName ?? ''
output sqlServerName string = resources.?outputs.sqlServerName ?? ''
output sqlDatabaseName string = resources.?outputs.sqlDatabaseName ?? ''
output privateEndpointCrName string = resources.?outputs.privateEndpointCrName ?? ''
output privateEndpointCaeName string = resources.?outputs.privateEndpointCaeName ?? ''
output privateEndpointSqlName string = resources.?outputs.privateEndpointSqlName ?? ''
