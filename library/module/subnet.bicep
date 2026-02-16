// Module: Subnet
// Description: Creates or updates a subnet with optional delegation for Container Apps Environment
// Note: This module ensures the CAE subnet has proper delegation and a single address prefix

@description('VNet name where the subnet will be created')
param vnetName string

@description('Subnet name')
param subnetName string

@description('Subnet address prefix (e.g., 10.0.1.0/23)')
param addressPrefix string

@description('Enable delegation for Microsoft.App/environments')
param delegateToContainerApps bool = false

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: addressPrefix
    delegations: delegateToContainerApps ? [
      {
        name: 'Microsoft.App.environments'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ] : []
  }
}

@description('The resource ID of the subnet')
output subnetId string = subnet.id

@description('The name of the subnet')
output subnetName string = subnet.name
