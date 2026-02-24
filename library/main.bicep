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

// 1. Deploy Managed Identity
module managedIdentity 'module/managedIdentity.bicep' = if (envParams.deployManagedIdentity) {
  name: 'deploy-mi-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    name: '${names.managedIdentity}-${environment}'
  }
}

// 2. Deploy Log Analytics Workspace
module logAnalyticsWorkspace 'module/logAnalyticsWorkspace.bicep' = if (envParams.deployLogAnalyticsWorkspace) {
  name: 'deploy-log-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    name: '${names.logAnalyticsWorkspace}-${environment}'
  }
}

// 3. Deploy Container Registry (with optional private endpoint)
module containerRegistry 'module/containerRegistry.bicep' = if (envParams.deployContainerRegistry) {
  name: 'deploy-acr-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    name: '${names.containerRegistry}${environment}'
    managedIdentityId: managedIdentity.?outputs.managedIdentityId ?? ''
    deployPrivateEndpoint: envParams.deployPrivateEndpointCr
    subnetId: subnetId
    privateEndpointName: '${names.privateEndpointCr}-${environment}'
    privateDnsZoneId: privateDnsZoneIdCr
  }
}

// 4. Deploy Container Apps Environment (with optional private endpoint)
module containerAppsEnvironment 'module/containerAppsEnvironment.bicep' = if (envParams.deployContainerAppsEnvironment) {
  name: 'deploy-cae-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    name: '${names.containerAppsEnvironment}-${environment}'
    managedIdentityId: managedIdentity.?outputs.managedIdentityId ?? ''
    logAnalyticsCustomerId: logAnalyticsWorkspace.?outputs.workspaceCustomerId ?? ''
    logAnalyticsSharedKey: logAnalyticsWorkspace.?outputs.workspaceSharedKey ?? ''
    deployPrivateEndpoint: envParams.deployPrivateEndpointCae
    subnetId: subnetId
    privateEndpointName: '${names.privateEndpointCae}-${environment}'
    privateDnsZoneId: privateDnsZoneIdCae
  }
}

// 5. Deploy Container App Job - accsync
module containerAppJobaccsync 'module/containerAppJob1.bicep' = if (envParams.deployContainerAppJobaccsync) {
  name: 'deploy-caj-accsync-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.?outputs.containerAppsEnvironmentId ?? ''
    managedIdentityId: managedIdentity.?outputs.managedIdentityId ?? ''
    containerImage: envParams.containerImage
    name: '${names.containerAppJobaccsync}-${environment}'
  }
}

// 6. Deploy Container App Job - sah
module containerAppJobsah 'module/containerAppJob2.bicep' = if (envParams.deployContainerAppJobsah) {
  name: 'deploy-caj-sah-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.?outputs.containerAppsEnvironmentId ?? ''
    managedIdentityId: managedIdentity.?outputs.managedIdentityId ?? ''
    containerImage: envParams.containerImage
    name: '${names.containerAppJobsah}-${environment}'
  }
}

// 7. Deploy SQL Server (with optional private endpoint)
module sqlServer 'module/sqlServer.bicep' = if (envParams.deploySqlServer) {
  name: 'deploy-sql-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    name: '${names.sqlServer}-${environment}'
    administratorLogin: envParams.sqlAdministratorLogin
    administratorLoginPassword: envParams.sqlAdministratorLoginPassword
    deployPrivateEndpoint: envParams.deployPrivateEndpointSql
    subnetId: subnetId
    privateEndpointName: '${names.privateEndpointSql}-${environment}'
    privateDnsZoneId: privateDnsZoneIdSql
  }
}

// 8. Deploy SQL Database
module sqlDatabase 'module/sqlDatabase.bicep' = if (envParams.deploySqlDatabase) {
  name: 'deploy-db-${environment}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    name: '${names.sqlDatabase}-${environment}'
    sqlServerName: sqlServer.?outputs.sqlServerName ?? ''
  }
}

// Outputs
output resourceGroupName string = resourceGroupName
output managedIdentityId string = managedIdentity.?outputs.managedIdentityId ?? ''
output containerRegistryName string = containerRegistry.?outputs.containerRegistryName ?? ''
output containerRegistryLoginServer string = containerRegistry.?outputs.containerRegistryLoginServer ?? ''
output containerAppsEnvironmentName string = containerAppsEnvironment.?outputs.containerAppsEnvironmentName ?? ''
output sqlServerName string = sqlServer.?outputs.sqlServerName ?? ''
output sqlDatabaseName string = sqlDatabase.?outputs.sqlDatabaseName ?? ''
output privateEndpointCrName string = containerRegistry.?outputs.privateEndpointName ?? ''
output privateEndpointCaeName string = containerAppsEnvironment.?outputs.privateEndpointName ?? ''
output privateEndpointSqlName string = sqlServer.?outputs.privateEndpointName ?? ''
