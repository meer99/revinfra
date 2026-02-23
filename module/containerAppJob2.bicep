// Description: Dedicated module for caj-ae-bcrevproc-sah-cb-{env}

@description('Environment name (dev1, sit, uat, prod)')
param environment string

@description('Azure region for resources')
param location string = 'australiaeast'

@description('Tags to apply to the container app job')
param tags object = {}

@description('Container Apps Environment resource ID')
param containerAppsEnvironmentId string

@description('Managed identity resource ID')
param managedIdentityId string

@description('Container image (e.g., mcr.microsoft.com/azuredocs/containerapps-helloworld:latest)')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var jobName = 'caj-ae-bcrevproc-sah-cb-${environment}'
var containerName = 'caj-ae-bcrevproc-sah-cb-${environment}'
var cpu = '0.25'
var memory = '0.5Gi'
var triggerType = 'Manual'
var replicaTimeout = 1800
var replicaRetryLimit = 0
var parallelism = 1
var replicaCompletionCount = 1

resource containerAppJob 'Microsoft.App/jobs@2023-05-01' = {
  name: jobName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironmentId
    configuration: {
      replicaTimeout: replicaTimeout
      replicaRetryLimit: replicaRetryLimit
      triggerType: triggerType
      manualTriggerConfig: {
        parallelism: parallelism
        replicaCompletionCount: replicaCompletionCount
      }
    }
    template: {
      containers: [
        {
          name: containerName
          image: containerImage
          resources: {
            cpu: json(cpu)
            memory: memory
          }
        }
      ]
    }
  }
}

@description('The name of the container app job')
output containerAppJobName string = containerAppJob.name

@description('The resource ID of the container app job')
output containerAppJobId string = containerAppJob.id
