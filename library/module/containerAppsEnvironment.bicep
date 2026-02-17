// Module: Container Apps Environment
// Description: Creates a Container Apps Environment with VNet integration
// Note: Requires a dedicated subnet with delegation to Microsoft.App/environments.
//       This subnet must not be shared with other resources (e.g. private endpoints).

@description('Environment name (dev, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the container apps environment')
param tags object = {}

@description('Container Apps Environment name pattern')
param namePattern string = 'cae-rebc'

@description('Log Analytics workspace customer ID')
param logAnalyticsCustomerId string

@description('Log Analytics workspace shared key')
@secure()
param logAnalyticsSharedKey string

@description('Subnet resource ID dedicated to the Container Apps Environment (must be delegated to Microsoft.App/environments)')
param infrastructureSubnetId string

@description('Whether the environment is internal-only (no public ingress)')
param internal bool = true

var containerAppsEnvironmentName = '${namePattern}-${environment}'

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppsEnvironmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    vnetConfiguration: {
      internal: internal
      infrastructureSubnetId: infrastructureSubnetId
    }
    zoneRedundant: false
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
