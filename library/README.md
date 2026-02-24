# REBC Infrastructure Library

This directory contains modular Bicep templates for deploying Azure infrastructure across multiple environments (Dev1, SIT, UAT, Prod).

## Directory Structure

```
library/
├── module/                              # Reusable Bicep modules
│   ├── resourceGroup.bicep              # Resource Group module
│   ├── managedIdentity.bicep            # Managed Identity module
│   ├── containerRegistry.bicep          # Container Registry module (Premium SKU)
│   ├── containerAppsEnvironment.bicep   # Container Apps Environment module
│   ├── containerAppJob1.bicep           # Container App Job module for caj-ae-bcrevdata-accsync-{env}
│   ├── containerAppJob2.bicep           # Container App Job module for caj-ae-bcrevproc-sah-cb-{env}
│   ├── sqlServer.bicep                  # SQL Server module
│   ├── sqlDatabase.bicep                # SQL Database module
│   └── logAnalyticsWorkspace.bicep      # Log Analytics Workspace module
├── variable/                            # Configuration files
│   ├── tags.json                        # Common tags for all resources
│   ├── variable.json                    # Shared variables (names, location, etc.)
│   └── parameters.json                  # Environment-specific parameters
├── main.bicep                           # Main orchestrator template
├── deploy.sh                            # Deployment script
└── azure-pipeline.yml                   # Azure DevOps pipeline
```

## Resources Deployed

- **Resource Group**: `rg-ae-bcrev-{env}`
- **Managed Identity**: `mi-ae-bcrevdata-{env}`
- **Log Analytics Workspace**: `log-ae-bcrevdata-{env}`
- **Container Registry**: `acraebcrev{env}` (Premium SKU)
- **Container Apps Environment**: `cae-ae-bcrev-{env}`
- **Container App Job - Bill**: `caj-ae-bcrevdata-accsync-{env}`
- **Container App Job - Data**: `caj-ae-bcrevproc-sah-cb-{env}`
- **SQL Server**: `sql-ae-bcrevdata-{env}`
- **SQL Database**: `bc_cc_revenue_data-{env}`

## Prerequisites

### Azure Resources (Must Exist)
- **Subscription**: rebcsubtest

### Tools Required
- Azure CLI (latest version)
- Bicep CLI (latest version)

## Deployment

### Azure DevOps Pipeline

The pipeline (`azure-pipeline.yml`) validates Bicep templates and deploys to the selected environment. The pipeline uses `trigger: none`, so it must be run manually from Azure DevOps. When running the pipeline, select the target environment (dev1, sit, uat, or prod) via the `environment` parameter.

> **Note**: All deployment flags in `parameters.json` are set to `false` by default. Set the required flags to `true` before running the pipeline to deploy specific resources.

### Manual Deployment

```bash
# Deploy to Dev1
./deploy.sh dev1

# Deploy to SIT
./deploy.sh sit

# Deploy to UAT
./deploy.sh uat

# Deploy to Prod
./deploy.sh prod
```

## Support

For issues or questions, please contact the Infrastructure Team.

## Troubleshooting

### AADSTS700016: Application not found in directory

If you see the error:
```
AADSTS700016: Application with identifier '...' was not found in the directory
```

This means the service principal used by the Azure service connection is not registered in the target Azure AD tenant. To fix:

1. **Verify the service connection** in Azure DevOps → Project Settings → Service connections.
2. Ensure the **Tenant ID** on the service connection matches the Azure AD tenant that owns your subscription.
3. Ensure the **Application (client) ID** corresponds to a valid App Registration in that tenant.
4. When running the pipeline, select the correct service connection name via the **Azure Service Connection** parameter.
