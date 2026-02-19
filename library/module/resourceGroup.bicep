// Module: Resource Group
// Description: Creates a resource group at subscription scope
// Target Scope: subscription

targetScope = 'subscription'

@description('Environment name (dev1, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the resource group')
param tags object = {}

@description('Resource group name pattern')
param namePattern string = 'rg-rebc'

var resourceGroupName = '${namePattern}-${environment}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

@description('The name of the resource group')
output resourceGroupName string = resourceGroup.name

@description('The ID of the resource group')
output resourceGroupId string = resourceGroup.id

@description('The location of the resource group')
output resourceGroupLocation string = resourceGroup.location
