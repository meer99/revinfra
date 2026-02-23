// Module: SQL Database
// Description: Creates an Azure SQL Database with specified service tier and DTUs

@description('Environment name (dev1, sit, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the SQL database')
param tags object = {}

@description('SQL Database name pattern')
param namePattern string = 'bc_cc_revenue_data'

@description('SQL Server name')
param sqlServerName string

@description('Database SKU name')
@allowed(['Basic', 'S0', 'S1', 'S2', 'S3', 'S4', 'S6', 'S7', 'S9', 'S12'])
param skuName string = 'S0'

@description('Database SKU tier')
@allowed(['Basic', 'Standard', 'Premium'])
param skuTier string = 'Standard'

@description('Database capacity in DTUs')
param capacity int = 10

@description('Maximum size of the database in bytes')
param maxSizeBytes int = 5368709120 // 5 GB

@description('Collation of the database')
param collation string = 'SQL_Latin1_General_CP1_CI_AS'

var databaseName = '${namePattern}-${environment}'

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: '${sqlServerName}/${databaseName}'
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
    capacity: capacity
  }
  properties: {
    collation: collation
    maxSizeBytes: maxSizeBytes
    catalogCollation: collation
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
  }
}

@description('The name of the SQL database')
output sqlDatabaseName string = databaseName

@description('The resource ID of the SQL database')
output sqlDatabaseId string = sqlDatabase.id
