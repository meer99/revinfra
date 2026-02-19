// Module: Container Apps Environment
// Description: Creates a Container Apps Environment with workload profiles.
//       Private connectivity is achieved via private endpoints.

@description('Environment name (dev, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the container apps environment')
param tags object = {}

@description('Container Apps Environment name pattern')
param namePattern string = 'cae-rebc'

@description('Managed identity resource ID')
param managedIdentityId string

@description('Log Analytics workspace customer ID')
param logAnalyticsCustomerId string

@description('Log Analytics workspace shared key')
@secure()
param logAnalyticsSharedKey string

var containerAppsEnvironmentName = '${namePattern}-${environment}'

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

@description('The name of the container apps environment')
output containerAppsEnvironmentName string = containerAppsEnvironment.name

@description('The resource ID of the container apps environment')
output containerAppsEnvironmentId string = containerAppsEnvironment.id

@description('The default domain of the container apps environment')
output containerAppsEnvironmentDefaultDomain string = containerAppsEnvironment.properties.defaultDomain

@description('The static IP address of the container apps environment')
output containerAppsEnvironmentStaticIp string = containerAppsEnvironment.properties.staticIp
