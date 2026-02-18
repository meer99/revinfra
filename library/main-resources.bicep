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
