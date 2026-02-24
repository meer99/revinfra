// Module: Container Apps Environment
// Description: Creates a Container Apps Environment with workload profiles.
//       Private connectivity is achieved via private endpoints.

@description('Environment name (dev1, sit, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the container apps environment')
param tags object = {}

@description('Container Apps Environment name pattern')
param namePattern string = 'cae-ae-bcrev'

@description('Managed identity resource ID')
param managedIdentityId string

@description('Log Analytics workspace customer ID')
param logAnalyticsCustomerId string

@description('Log Analytics workspace shared key')
@secure()
param logAnalyticsSharedKey string

@description('Deploy private endpoint for the container apps environment')
param deployPrivateEndpoint bool = false

@description('Subnet resource ID where the private endpoint will be created')
param subnetId string = ''

@description('Private endpoint name pattern')
param privateEndpointNamePattern string = ''

@description('Private DNS zone resource ID for the container apps environment')
param privateDnsZoneId string = ''

var containerAppsEnvironmentName = '${namePattern}-${environment}'
var privateEndpointName = '${privateEndpointNamePattern}-${environment}'

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' = {
  name: containerAppsEnvironmentName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    zoneRedundant: false
    publicNetworkAccess: 'Disabled'
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
          privateLinkServiceId: containerAppsEnvironment.id
          groupIds: ['managedEnvironments']
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
        name: 'privatelink-azurecontainerapps-io'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

@description('The name of the container apps environment')
output containerAppsEnvironmentName string = containerAppsEnvironment.name

@description('The resource ID of the container apps environment')
output containerAppsEnvironmentId string = containerAppsEnvironment.id

@description('The default domain of the container apps environment')
output containerAppsEnvironmentDefaultDomain string = containerAppsEnvironment.properties.defaultDomain

@description('The static IP address of the container apps environment')
output containerAppsEnvironmentStaticIp string = containerAppsEnvironment.properties.staticIp

@description('The name of the private endpoint')
output privateEndpointName string = deployPrivateEndpoint ? privateEndpoint.name : ''
