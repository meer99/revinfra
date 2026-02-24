// Module: Managed Identity
// Description: Creates a user-assigned managed identity

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the managed identity')
param tags object = {}

@description('Managed identity name')
param name string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

@description('The name of the managed identity')
output managedIdentityName string = managedIdentity.name

@description('The resource ID of the managed identity')
output managedIdentityId string = managedIdentity.id

@description('The principal ID of the managed identity')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('The client ID of the managed identity')
output managedIdentityClientId string = managedIdentity.properties.clientId
