// Resources Module
// Description: Deploys all resources within the existing resource group
// Target Scope: resourceGroup

@description('Environment name (dev1, sit, uat, prod)')
param environment string

@description('Azure region for resources')
param location string

@description('Tags to apply to resources')
param tags object

@description('Name patterns for resources')
param namePatterns object

@description('Environment parameters')
param envParams object

@description('Resource ID of the existing subnet for private endpoints')
param subnetId string

@description('Private DNS zone resource ID for Container Registry')
param privateDnsZoneIdCr string

@description('Private DNS zone resource ID for SQL Server')
param privateDnsZoneIdSql string

@description('Private DNS zone resource ID for Container Apps Environment')
param privateDnsZoneIdCae string

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

// 3. Deploy Container Registry (with optional private endpoint)
module containerRegistry 'module/containerRegistry.bicep' = if (envParams.deployContainerRegistry) {
  name: 'deploy-acr-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.containerRegistry
    managedIdentityId: managedIdentity.?outputs.managedIdentityId ?? ''
    deployPrivateEndpoint: envParams.deployPrivateEndpointCr
    subnetId: subnetId
    privateEndpointNamePattern: namePatterns.privateEndpointCr
    privateDnsZoneId: privateDnsZoneIdCr
  }
}

// 4. Deploy Container Apps Environment (with optional private endpoint)
module containerAppsEnvironment 'module/containerAppsEnvironment.bicep' = if (envParams.deployContainerAppsEnvironment) {
  name: 'deploy-cae-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.containerAppsEnvironment
    managedIdentityId: managedIdentity.?outputs.managedIdentityId ?? ''
    logAnalyticsCustomerId: logAnalyticsWorkspace.?outputs.workspaceCustomerId ?? ''
    logAnalyticsSharedKey: logAnalyticsWorkspace.?outputs.workspaceSharedKey ?? ''
    deployPrivateEndpoint: envParams.deployPrivateEndpointCae
    subnetId: subnetId
    privateEndpointNamePattern: namePatterns.privateEndpointCae
    privateDnsZoneId: privateDnsZoneIdCae
  }
}

// 5. Deploy Container App Job - accsync
module containerAppJobaccsync 'module/containerAppJob1.bicep' = if (envParams.deployContainerAppJobaccsync) {
  name: 'deploy-caj-accsync-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.?outputs.containerAppsEnvironmentId ?? ''
    managedIdentityId: managedIdentity.?outputs.managedIdentityId ?? ''
    containerImage: envParams.containerImage
  }
}

// 6. Deploy Container App Job - sah
module containerAppJobsah 'module/containerAppJob2.bicep' = if (envParams.deployContainerAppJobsah) {
  name: 'deploy-caj-sah-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.?outputs.containerAppsEnvironmentId ?? ''
    managedIdentityId: managedIdentity.?outputs.managedIdentityId ?? ''
    containerImage: envParams.containerImage
  }
}

// 7. Deploy SQL Server (with optional private endpoint)
module sqlServer 'module/sqlServer.bicep' = if (envParams.deploySqlServer) {
  name: 'deploy-sql-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.sqlServer
    administratorLogin: envParams.sqlAdministratorLogin
    administratorLoginPassword: envParams.sqlAdministratorLoginPassword
    deployPrivateEndpoint: envParams.deployPrivateEndpointSql
    subnetId: subnetId
    privateEndpointNamePattern: namePatterns.privateEndpointSql
    privateDnsZoneId: privateDnsZoneIdSql
  }
}

// 8. Deploy SQL Database
module sqlDatabase 'module/sqlDatabase.bicep' = if (envParams.deploySqlDatabase) {
  name: 'deploy-db-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.sqlDatabase
    sqlServerName: sqlServer.?outputs.sqlServerName ?? ''
  }
}

// Outputs
output managedIdentityId string = managedIdentity.?outputs.managedIdentityId ?? ''
output containerRegistryName string = containerRegistry.?outputs.containerRegistryName ?? ''
output containerRegistryLoginServer string = containerRegistry.?outputs.containerRegistryLoginServer ?? ''
output containerRegistryId string = containerRegistry.?outputs.containerRegistryId ?? ''
output containerAppsEnvironmentName string = containerAppsEnvironment.?outputs.containerAppsEnvironmentName ?? ''
output containerAppsEnvironmentId string = containerAppsEnvironment.?outputs.containerAppsEnvironmentId ?? ''
output sqlServerName string = sqlServer.?outputs.sqlServerName ?? ''
output sqlServerId string = sqlServer.?outputs.sqlServerId ?? ''
output sqlDatabaseName string = sqlDatabase.?outputs.sqlDatabaseName ?? ''
output privateEndpointCrName string = containerRegistry.?outputs.privateEndpointName ?? ''
output privateEndpointCaeName string = containerAppsEnvironment.?outputs.privateEndpointName ?? ''
output privateEndpointSqlName string = sqlServer.?outputs.privateEndpointName ?? ''
