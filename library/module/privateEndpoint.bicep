// Module: Private Endpoint
// Description: Reusable module for creating private endpoints for various Azure services

@description('Private endpoint name')
param privateEndpointName string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the private endpoint')
param tags object = {}

@description('Subnet resource ID where the private endpoint will be created')
param subnetId string

@description('Resource ID of the service to create a private endpoint for')
param privateLinkServiceId string

@description('Group IDs for the private endpoint (e.g., registry, sqlServer, managedEnvironments)')
param groupIds array

@description('Enable private DNS integration')
param enablePrivateDnsIntegration bool = false

@description('Private DNS Zone IDs for DNS integration')
param privateDnsZoneIds array = []

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
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
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (enablePrivateDnsIntegration && length(privateDnsZoneIds) > 0) {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [for (zoneId, i) in privateDnsZoneIds: {
      name: 'config${i}'
      properties: {
        privateDnsZoneId: zoneId
      }
    }]
  }
}

@description('The name of the private endpoint')
output privateEndpointName string = privateEndpoint.name

@description('The resource ID of the private endpoint')
output privateEndpointId string = privateEndpoint.id

@description('The private IP address of the private endpoint')
output privateEndpointIpAddress string = privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
