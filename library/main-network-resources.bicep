// Network Resources Module
// Description: Deploys private endpoints using an existing VNet and subnet from an existing resource group
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

@description('Name of the existing virtual network')
param existingVirtualNetworkName string

@description('Name of the existing subnet')
param existingSubnetName string

@description('Name of the existing network resource group containing the VNet')
param existingNetworkResourceGroupName string

// Reference the existing Virtual Network and Subnet from the network resource group
resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: existingVirtualNetworkName
  scope: resourceGroup(existingNetworkResourceGroupName)
}

resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: existingVirtualNetwork
  name: existingSubnetName
}

// 1. Deploy Private Endpoint for Container Registry
module privateEndpointCr 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointCr) {
  name: 'deploy-pe-cr-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.privateEndpointCr
    privateLinkServiceId: containerRegistryId
    groupIds: ['registry']
    subnetId: existingSubnet.id
  }
}

// 2. Deploy Private Endpoint for Container Apps Environment
module privateEndpointCae 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointCae) {
  name: 'deploy-pe-cae-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.privateEndpointCae
    privateLinkServiceId: containerAppsEnvironmentId
    groupIds: ['managedEnvironments']
    subnetId: existingSubnet.id
  }
}

// 3. Deploy Private Endpoint for SQL Server
module privateEndpointSql 'module/privateEndpoint.bicep' = if (envParams.deployPrivateEndpointSql) {
  name: 'deploy-pe-sql-${environment}'
  params: {
    environment: environment
    location: location
    tags: tags
    namePattern: namePatterns.privateEndpointSql
    privateLinkServiceId: sqlServerId
    groupIds: ['sqlServer']
    subnetId: existingSubnet.id
  }
}

// Outputs
output virtualNetworkName string = existingVirtualNetwork.name
output subnetName string = existingSubnet.name
output privateEndpointCrName string = envParams.deployPrivateEndpointCr ? privateEndpointCr.outputs.privateEndpointName : ''
output privateEndpointCaeName string = envParams.deployPrivateEndpointCae ? privateEndpointCae.outputs.privateEndpointName : ''
output privateEndpointSqlName string = envParams.deployPrivateEndpointSql ? privateEndpointSql.outputs.privateEndpointName : ''
