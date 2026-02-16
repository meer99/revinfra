// Module: Virtual Network
// Description: Creates a Virtual Network with a subnet

@description('Environment name (dev, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the virtual network')
param tags object = {}

@description('Virtual Network name pattern')
param namePattern string = 'vnet-rebc'

@description('Subnet name')
param subnetName string = 'snet-rebc'

@description('Virtual Network address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet address prefix')
param subnetAddressPrefix string = '10.0.0.0/23'

var vnetName = '${namePattern}-${environment}'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
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
        }
      }
    ]
  }
}

@description('The name of the virtual network')
output vnetName string = virtualNetwork.name

@description('The resource ID of the virtual network')
output vnetId string = virtualNetwork.id

@description('The resource ID of the subnet')
output subnetId string = virtualNetwork.properties.subnets[0].id
