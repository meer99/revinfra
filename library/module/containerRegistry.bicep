// Module: Container Registry
// Description: Creates an Azure Container Registry with Premium SKU for private endpoint support
// Note: Public access is disabled, private access is enabled

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the container registry')
param tags object = {}

@description('Container registry name')
param name string

@description('Managed identity resource ID')
param managedIdentityId string

@description('SKU for the container registry')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Premium'

@description('Enable admin user')
param adminUserEnabled bool = false

@description('Deploy private endpoint for the container registry')
param deployPrivateEndpoint bool = false

@description('Subnet resource ID where the private endpoint will be created')
param subnetId string = ''

@description('Private endpoint name')
param privateEndpointName string = ''

@description('Private DNS zone resource ID for the container registry')
param privateDnsZoneId string = ''

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
    dataEndpointEnabled: false
    encryption: {
      status: 'disabled'
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (deployPrivateEndpoint) {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: containerRegistry.id
          groupIds: ['registry']
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (deployPrivateEndpoint) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurecr-io'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

@description('The name of the container registry')
output containerRegistryName string = containerRegistry.name

@description('The resource ID of the container registry')
output containerRegistryId string = containerRegistry.id

@description('The login server of the container registry')
output containerRegistryLoginServer string = containerRegistry.properties.loginServer

@description('The name of the private endpoint')
output privateEndpointName string = deployPrivateEndpoint ? privateEndpoint.name : ''
