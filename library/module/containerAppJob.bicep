// Module: Container App Job
// Description: Reusable module for creating Container App Jobs

@description('Job name')
param jobName string

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

@description('Container name')
param containerName string = 'main-container'

@description('CPU cores for the container')
param cpu string = '0.25'

@description('Memory for the container')
param memory string = '0.5Gi'

@description('Trigger type for the job')
@allowed(['Manual', 'Schedule', 'Event'])
param triggerType string = 'Manual'

@description('Cron expression for scheduled jobs (only used when triggerType is Schedule)')
param cronExpression string = '0 0 * * *'

@description('Replica timeout in seconds')
param replicaTimeout int = 1800

@description('Replica retry limit')
param replicaRetryLimit int = 0

@description('Parallelism (number of replicas to start per job execution)')
param parallelism int = 1

@description('Replica completions')
param replicaCompletionCount int = 1

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
      manualTriggerConfig: triggerType == 'Manual' ? {
        parallelism: parallelism
        replicaCompletionCount: replicaCompletionCount
      } : null
      scheduleTriggerConfig: triggerType == 'Schedule' ? {
        cronExpression: cronExpression
        parallelism: parallelism
        replicaCompletionCount: replicaCompletionCount
      } : null
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
