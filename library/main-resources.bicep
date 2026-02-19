// Resources Module
// Description: Deploys all resources within the resource group
// Target Scope: resourceGroup

@description('Environment name (dev1, uat, prod)')
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

// 4. Deploy Container Apps Environment
module containerAppsEnvironment 'module/containerAppsEnvironment.bicep' = if (envParams.deployContainerAppsEnvironment) {
  name: 'deploy-cae-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.containerAppsEnvironment
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    logAnalyticsCustomerId: envParams.deployLogAnalyticsWorkspace ? logAnalyticsWorkspace.outputs.workspaceCustomerId : ''
    logAnalyticsSharedKey: envParams.deployLogAnalyticsWorkspace ? logAnalyticsWorkspace.outputs.workspaceSharedKey : ''
  }
  dependsOn: [
    logAnalyticsWorkspace
    managedIdentity
  ]
}

// 5. Deploy Container App Job - Bill
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

// 6. Deploy Container App Job - Data
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

// 7. Deploy SQL Server
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

// 8. Deploy SQL Database
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

// 9. Deploy Private Endpoint for Container Registry
module privateEndpointCr 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointCr && envParams.deployContainerRegistry) {
  name: 'deploy-pe-cr-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.privateEndpointCr
    privateLinkServiceId: envParams.deployContainerRegistry ? containerRegistry.outputs.containerRegistryId : ''
    groupIds: ['registry']
    subnetId: subnetId
  }
  dependsOn: [
    containerRegistry
  ]
}

// 10. Deploy Private Endpoint for Container Apps Environment
module privateEndpointCae 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointCae && envParams.deployContainerAppsEnvironment) {
  name: 'deploy-pe-cae-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.privateEndpointCae
    privateLinkServiceId: envParams.deployContainerAppsEnvironment ? containerAppsEnvironment.outputs.containerAppsEnvironmentId : ''
    groupIds: ['managedEnvironments']
    subnetId: subnetId
  }
  dependsOn: [
    containerAppsEnvironment
  ]
}

// 11. Deploy Private Endpoint for SQL Server
module privateEndpointSql 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointSql && envParams.deploySqlServer) {
  name: 'deploy-pe-sql-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.privateEndpointSql
    privateLinkServiceId: envParams.deploySqlServer ? sqlServer.outputs.sqlServerId : ''
    groupIds: ['sqlServer']
    subnetId: subnetId
  }
  dependsOn: [
    sqlServer
  ]
}

// Outputs
output managedIdentityId string = envParams.deployManagedIdentity ? managedIdentity.outputs.managedIdentityId : ''
output containerRegistryName string = envParams.deployContainerRegistry ? containerRegistry.outputs.containerRegistryName : ''
output containerRegistryLoginServer string = envParams.deployContainerRegistry ? containerRegistry.outputs.containerRegistryLoginServer : ''
output containerRegistryId string = envParams.deployContainerRegistry ? containerRegistry.outputs.containerRegistryId : ''
output containerAppsEnvironmentName string = envParams.deployContainerAppsEnvironment ? containerAppsEnvironment.outputs.containerAppsEnvironmentName : ''
output containerAppsEnvironmentId string = envParams.deployContainerAppsEnvironment ? containerAppsEnvironment.outputs.containerAppsEnvironmentId : ''
output sqlServerName string = envParams.deploySqlServer ? sqlServer.outputs.sqlServerName : ''
output sqlServerId string = envParams.deploySqlServer ? sqlServer.outputs.sqlServerId : ''
output sqlDatabaseName string = envParams.deploySqlDatabase ? sqlDatabase.outputs.sqlDatabaseName : ''
output privateEndpointCrName string = envParams.deployPrivateEndpointCr && envParams.deployContainerRegistry ? privateEndpointCr.outputs.privateEndpointName : ''
output privateEndpointCaeName string = envParams.deployPrivateEndpointCae && envParams.deployContainerAppsEnvironment ? privateEndpointCae.outputs.privateEndpointName : ''
output privateEndpointSqlName string = envParams.deployPrivateEndpointSql && envParams.deploySqlServer ? privateEndpointSql.outputs.privateEndpointName : ''
