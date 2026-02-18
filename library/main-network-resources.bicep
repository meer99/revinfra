// Network Resources Module
// Description: Deploys networking resources (VNet, subnet, and private endpoints) within the network resource group
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

@description('Resource ID of the container registry')
param containerRegistryId string

@description('Resource ID of the container apps environment')
param containerAppsEnvironmentId string

@description('Resource ID of the SQL server')
param sqlServerId string

// 1. Deploy Virtual Network with Subnet
module virtualNetwork 'module/virtualNetwork.bicep' = if (envParams.deployVirtualNetwork) {
  name: 'deploy-vnt-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.virtualNetwork
    subnetNamePattern: namePatterns.subnet
  }
}

// 2. Deploy Private Endpoint for Container Registry
module privateEndpointCr 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointCr) {
  name: 'deploy-pe-cr-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.privateEndpointCr
    privateLinkServiceId: containerRegistryId
    groupIds: ['registry']
    subnetId: virtualNetwork.outputs.subnetId
  }
  dependsOn: [
    virtualNetwork
  ]
}

// 3. Deploy Private Endpoint for Container Apps Environment
module privateEndpointCae 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointCae) {
  name: 'deploy-pe-cae-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.privateEndpointCae
    privateLinkServiceId: containerAppsEnvironmentId
    groupIds: ['managedEnvironments']
    subnetId: virtualNetwork.outputs.subnetId
  }
  dependsOn: [
    virtualNetwork
  ]
}

// 4. Deploy Private Endpoint for SQL Server
module privateEndpointSql 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointSql) {
  name: 'deploy-pe-sql-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.privateEndpointSql
    privateLinkServiceId: sqlServerId
    groupIds: ['sqlServer']
    subnetId: virtualNetwork.outputs.subnetId
  }
  dependsOn: [
    virtualNetwork
  ]
}

// Outputs
output virtualNetworkName string = envParams.deployVirtualNetwork ? virtualNetwork.outputs.virtualNetworkName : ''
output subnetName string = envParams.deployVirtualNetwork ? virtualNetwork.outputs.subnetName : ''
output privateEndpointCrName string = envParams.deployPrivateEndpointCr ? privateEndpointCr.outputs.privateEndpointName : ''
output privateEndpointCaeName string = envParams.deployPrivateEndpointCae ? privateEndpointCae.outputs.privateEndpointName : ''
output privateEndpointSqlName string = envParams.deployPrivateEndpointSql ? privateEndpointSql.outputs.privateEndpointName : ''
