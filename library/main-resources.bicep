// Resources Module
// Description: Deploys all resources within the resource group
// Target Scope: resourceGroup

@description('Environment name (dev, uat, prod)')
param environment string

@description('Azure region for resources')
param location string

@description('Tags to apply to resources')
param tags object

@description('Name patterns for resources')
param namePatterns object

@description('VNet name')
param vnetName string

@description('Subnet name for private endpoints')
param subnetName string

@description('Existing VNet resource group')
param existingVnetResourceGroup string

@description('Environment parameters')
param envParams object

// 1. Deploy Managed Identity
module managedIdentity 'module/managedIdentity.bicep' = if (envParams.deployManagedIdentity) {
  name: 'deploy-mi-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.managedIdentity
  }
}

// 2. Deploy Log Analytics Workspace
module logAnalyticsWorkspace 'module/logAnalyticsWorkspace.bicep' = if (envParams.deployLogAnalyticsWorkspace) {
  name: 'deploy-log-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.logAnalyticsWorkspace
  }
}

// 3. Deploy Container Registry
module containerRegistry 'module/containerRegistry.bicep' = if (envParams.deployContainerRegistry) {
  name: 'deploy-acr-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.containerRegistry
    managedIdentityId: managedIdentity.outputs.managedIdentityId
  }
  dependsOn: [
    managedIdentity
  ]
}

// Get reference to existing VNet and Subnet
resource existingVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
  scope: resourceGroup(existingVnetResourceGroup)
}

resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: subnetName
  parent: existingVnet
}

// 4. Deploy Private Endpoint for Container Registry
module privateEndpointContainerRegistry 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointContainerRegistry) {
  name: 'deploy-pe-cr-${environment}'
  params: {
    privateEndpointName: '${namePatterns.privateEndpointContainerRegistry}-${environment}'
    location: location
    tags: tags
    subnetId: existingSubnet.id
    privateLinkServiceId: containerRegistry.outputs.containerRegistryId
    groupIds: ['registry']
  }
  dependsOn: [
    containerRegistry
  ]
}

// 5. Deploy Container Apps Environment
module containerAppsEnvironment 'module/containerAppsEnvironment.bicep' = if (envParams.deployContainerAppsEnvironment) {
  name: 'deploy-cae-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.containerAppsEnvironment
    logAnalyticsCustomerId: envParams.deployLogAnalyticsWorkspace ? logAnalyticsWorkspace.outputs.workspaceCustomerId : ''
    logAnalyticsSharedKey: envParams.deployLogAnalyticsWorkspace ? listKeys(resourceId('Microsoft.OperationalInsights/workspaces', '${namePatterns.logAnalyticsWorkspace}-${environment}'), '2022-10-01').primarySharedKey : ''
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}

// 6. Deploy Private Endpoint for Container Apps Environment
module privateEndpointContainerAppsEnvironment 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointContainerAppsEnvironment) {
  name: 'deploy-pe-cae-${environment}'
  params: {
    privateEndpointName: '${namePatterns.privateEndpointContainerAppsEnvironment}-${environment}'
    location: location
    tags: tags
    subnetId: existingSubnet.id
    privateLinkServiceId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    groupIds: ['managedEnvironments']
  }
  dependsOn: [
    containerAppsEnvironment
  ]
}

// 7. Deploy Container App Job - Bill
module containerAppJobBill 'module/containerAppJob1.bicep' = if (envParams.deployContainerAppJobBill) {
  name: 'deploy-caj-bill-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    containerImage: envParams.containerImage
  }
  dependsOn: [
    containerAppsEnvironment
    managedIdentity
  ]
}

// 8. Deploy Container App Job - Data
module containerAppJobData 'module/containerAppJob2.bicep' = if (envParams.deployContainerAppJobData) {
  name: 'deploy-caj-data-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    containerImage: envParams.containerImage
  }
  dependsOn: [
    containerAppsEnvironment
    managedIdentity
  ]
}

// 9. Deploy SQL Server
module sqlServer 'module/sqlServer.bicep' = if (envParams.deploySqlServer) {
  name: 'deploy-sql-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.sqlServer
    administratorLogin: envParams.sqlAdministratorLogin
    administratorLoginPassword: envParams.sqlAdministratorLoginPassword
  }
}

// 10. Deploy SQL Database
module sqlDatabase 'module/sqlDatabase.bicep' = if (envParams.deploySqlDatabase) {
  name: 'deploy-db-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.sqlDatabase
    sqlServerName: sqlServer.outputs.sqlServerName
  }
  dependsOn: [
    sqlServer
  ]
}

// 11. Deploy Private Endpoint for SQL Server
module privateEndpointSqlServer 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointSqlServer) {
  name: 'deploy-pe-sql-${environment}'
  params: {
    privateEndpointName: '${namePatterns.privateEndpointSqlServer}-${environment}'
    location: location
    tags: tags
    subnetId: existingSubnet.id
    privateLinkServiceId: sqlServer.outputs.sqlServerId
    groupIds: ['sqlServer']
  }
  dependsOn: [
    sqlServer
  ]
}

// Outputs
output managedIdentityId string = envParams.deployManagedIdentity ? managedIdentity.outputs.managedIdentityId : ''
output containerRegistryName string = envParams.deployContainerRegistry ? containerRegistry.outputs.containerRegistryName : ''
output containerRegistryLoginServer string = envParams.deployContainerRegistry ? containerRegistry.outputs.containerRegistryLoginServer : ''
output containerAppsEnvironmentName string = envParams.deployContainerAppsEnvironment ? containerAppsEnvironment.outputs.containerAppsEnvironmentName : ''
output sqlServerName string = envParams.deploySqlServer ? sqlServer.outputs.sqlServerName : ''
output sqlDatabaseName string = envParams.deploySqlDatabase ? sqlDatabase.outputs.sqlDatabaseName : ''
