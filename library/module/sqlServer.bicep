// Module: SQL Server
// Description: Creates an Azure SQL Server with public access disabled

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the SQL server')
param tags object = {}

@description('SQL Server name')
param name string

@description('SQL Server administrator login')
param administratorLogin string

@description('SQL Server administrator password')
@secure()
param administratorLoginPassword string

@description('Minimum TLS version')
@allowed(['1.0', '1.1', '1.2'])
param minimalTlsVersion string = '1.2'

@description('Deploy private endpoint for the SQL server')
param deployPrivateEndpoint bool = false

@description('Subnet resource ID where the private endpoint will be created')
param subnetId string = ''

@description('Private endpoint name')
param privateEndpointName string = ''

@description('Private DNS zone resource ID for the SQL server')
param privateDnsZoneId string = ''

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: '12.0'
    minimalTlsVersion: minimalTlsVersion
    publicNetworkAccess: 'Disabled'
    restrictOutboundNetworkAccess: 'Disabled'
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
          privateLinkServiceId: sqlServer.id
          groupIds: ['sqlServer']
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
        name: 'privatelink-database-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

@description('The name of the SQL server')
output sqlServerName string = sqlServer.name

@description('The resource ID of the SQL server')
output sqlServerId string = sqlServer.id

@description('The fully qualified domain name of the SQL server')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

@description('The name of the private endpoint')
output privateEndpointName string = deployPrivateEndpoint ? privateEndpoint.name : ''
