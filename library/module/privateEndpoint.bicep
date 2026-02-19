// Module: Private Endpoint
// Description: Creates a private endpoint for a specified resource

@description('Environment name (dev1, sit, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the private endpoint')
param tags object = {}

@description('Private endpoint name pattern')
param namePattern string

@description('Resource ID of the target resource for the private endpoint')
param privateLinkServiceId string

@description('Group IDs for the private endpoint (e.g., registry, managedEnvironments, sqlServer)')
param groupIds array

@description('Subnet resource ID where the private endpoint will be created')
param subnetId string

var privateEndpointName = '${namePattern}-${environment}'

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

@description('The name of the private endpoint')
output privateEndpointName string = privateEndpoint.name

@description('The resource ID of the private endpoint')
output privateEndpointId string = privateEndpoint.id
