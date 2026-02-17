// Module: Subnet
// Description: Creates a subnet within an existing Virtual Network
// Target Scope: resourceGroup (of the VNet)

@description('Name of the existing Virtual Network')
param vnetName string

@description('Name of the subnet to create')
param subnetName string

@description('Address prefix for the subnet (CIDR notation, e.g. 10.0.0.0/27)')
param addressPrefix string

@description('Service delegation name (e.g. Microsoft.App/environments). Leave empty for no delegation.')
param delegationServiceName string = ''

var delegations = empty(delegationServiceName) ? [] : [
  {
    name: '${subnetName}-delegation'
    properties: {
      serviceName: delegationServiceName
    }
  }
]

resource existingVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: subnetName
  parent: existingVnet
  properties: {
    addressPrefix: addressPrefix
    delegations: delegations
  }
}

@description('The resource ID of the subnet')
output subnetId string = subnet.id

@description('The name of the subnet')
output subnetName string = subnet.name
