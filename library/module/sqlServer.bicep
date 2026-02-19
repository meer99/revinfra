// Module: SQL Server
// Description: Creates an Azure SQL Server with public access disabled

@description('Environment name (dev1, sit, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the SQL server')
param tags object = {}

@description('SQL Server name pattern')
param namePattern string = 'sql-rebc'

@description('SQL Server administrator login')
param administratorLogin string

@description('SQL Server administrator password')
@secure()
param administratorLoginPassword string

@description('Minimum TLS version')
@allowed(['1.0', '1.1', '1.2'])
param minimalTlsVersion string = '1.2'

var sqlServerName = '${namePattern}-${environment}'

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
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

@description('The name of the SQL server')
output sqlServerName string = sqlServer.name

@description('The resource ID of the SQL server')
output sqlServerId string = sqlServer.id

@description('The fully qualified domain name of the SQL server')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
