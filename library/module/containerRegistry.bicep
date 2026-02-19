// Module: Container Registry
// Description: Creates an Azure Container Registry with Premium SKU for private endpoint support
// Note: Public access is disabled, private access is enabled

@description('Environment name (dev1, sit, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the container registry')
param tags object = {}

@description('Container registry name pattern')
param namePattern string = 'acraetestrebc'

@description('Managed identity resource ID')
param managedIdentityId string

@description('SKU for the container registry')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Premium'

@description('Enable admin user')
param adminUserEnabled bool = false

// Container registry names cannot contain hyphens or underscores, only alphanumeric
var containerRegistryName = '${namePattern}${environment}'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
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

@description('The name of the container registry')
output containerRegistryName string = containerRegistry.name

@description('The resource ID of the container registry')
output containerRegistryId string = containerRegistry.id

@description('The login server of the container registry')
output containerRegistryLoginServer string = containerRegistry.properties.loginServer
