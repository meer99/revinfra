// Module: Log Analytics Workspace
// Description: Creates a Log Analytics workspace for monitoring

@description('Environment name (dev, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the workspace')
param tags object = {}

@description('Log Analytics workspace name pattern')
param namePattern string = 'log-rebc'

@description('Workspace SKU')
@allowed(['PerGB2018', 'Free', 'Standalone', 'PerNode'])
param sku string = 'PerGB2018'

@description('Data retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

var workspaceName = '${namePattern}-${environment}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The name of the Log Analytics workspace')
output workspaceName string = logAnalyticsWorkspace.name

@description('The resource ID of the Log Analytics workspace')
output workspaceId string = logAnalyticsWorkspace.id

@description('The customer ID of the Log Analytics workspace')
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId

@description('The primary shared key of the Log Analytics workspace')
output workspaceSharedKey string = logAnalyticsWorkspace.listKeys().primarySharedKey
