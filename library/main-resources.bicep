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

// 1. Deploy Managed Identity
module managedIdentity 'module/managedIdentity.bicep' = if (deployManagedIdentity) {
  name: 'deploy-mi-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.managedIdentity
  }
}

// 2. Deploy Log Analytics Workspace
module logAnalyticsWorkspace 'module/logAnalyticsWorkspace.bicep' = if (deployLogAnalyticsWorkspace) {
  name: 'deploy-log-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.logAnalyticsWorkspace
  }
}

// 3. Deploy Container Registry
module containerRegistry 'module/containerRegistry.bicep' = if (deployContainerRegistry) {
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
module containerAppsEnvironment 'module/containerAppsEnvironment.bicep' = if (deployContainerAppsEnvironment) {
  name: 'deploy-cae-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.containerAppsEnvironment
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    logAnalyticsCustomerId: deployLogAnalyticsWorkspace ? logAnalyticsWorkspace.outputs.workspaceCustomerId : ''
    logAnalyticsSharedKey: deployLogAnalyticsWorkspace ? logAnalyticsWorkspace.outputs.workspaceSharedKey : ''
  }
  dependsOn: [
    logAnalyticsWorkspace
    managedIdentity
  ]
}

// 5. Deploy Container App Job - Bill
module containerAppJobBill 'module/containerAppJob1.bicep' = if (deployContainerAppJobBill) {
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
module containerAppJobData 'module/containerAppJob2.bicep' = if (deployContainerAppJobData) {
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
module sqlServer 'module/sqlServer.bicep' = if (deploySqlServer) {
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
module sqlDatabase 'module/sqlDatabase.bicep' = if (deploySqlDatabase) {
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
output managedIdentityId string = deployManagedIdentity ? managedIdentity.outputs.managedIdentityId : ''
output containerRegistryName string = deployContainerRegistry ? containerRegistry.outputs.containerRegistryName : ''
output containerRegistryLoginServer string = deployContainerRegistry ? containerRegistry.outputs.containerRegistryLoginServer : ''
output containerAppsEnvironmentName string = deployContainerAppsEnvironment ? containerAppsEnvironment.outputs.containerAppsEnvironmentName : ''
output sqlServerName string = deploySqlServer ? sqlServer.outputs.sqlServerName : ''
output sqlDatabaseName string = deploySqlDatabase ? sqlDatabase.outputs.sqlDatabaseName : ''
