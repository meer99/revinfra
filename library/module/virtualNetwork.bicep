// Module: Virtual Network
// Description: Creates a Virtual Network with a subnet for private endpoints

@description('Environment name (dev, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the virtual network')
param tags object = {}

@description('Virtual network name pattern')
param namePattern string = 'vnt-rebc'

@description('Subnet name pattern')
param subnetNamePattern string = 'snet-rebc'

@description('Address prefix for the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Address prefix for the subnet')
param subnetAddressPrefix string = '10.0.0.0/24'

var virtualNetworkName = '${namePattern}-${environment}'
var subnetName = '${subnetNamePattern}-${environment}'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

@description('The name of the virtual network')
output virtualNetworkName string = virtualNetwork.name

@description('The resource ID of the virtual network')
output virtualNetworkId string = virtualNetwork.id

@description('The name of the subnet')
output subnetName string = virtualNetwork.properties.subnets[0].name

@description('The resource ID of the subnet')
output subnetId string = virtualNetwork.properties.subnets[0].id
