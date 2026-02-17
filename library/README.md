# REBC Infrastructure Library

This directory contains modular Bicep templates for deploying Azure infrastructure across multiple environments (Dev, UAT, Prod).

## Directory Structure

```
library/
├── module/                              # Reusable Bicep modules
│   ├── resourceGroup.bicep              # Resource Group module
│   ├── managedIdentity.bicep            # Managed Identity module
│   ├── containerRegistry.bicep          # Container Registry module (Premium SKU)
│   ├── containerAppsEnvironment.bicep   # Container Apps Environment module
│   ├── containerAppJob1.bicep           # Container App Job module for caj-bill-{env}
│   ├── containerAppJob2.bicep           # Container App Job module for caj-data-{env}
│   ├── sqlServer.bicep                  # SQL Server module
│   ├── sqlDatabase.bicep                # SQL Database module
│   ├── privateEndpoint.bicep            # Private Endpoint module (reusable)
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

- **Resource Group**: `rg-rebc-{env}`
- **Managed Identity**: `mi-rebc-{env}`
- **Log Analytics Workspace**: `log-rebc-{env}`
- **Container Registry**: `acraetestrebc{env}` (Premium SKU)
- **Container Apps Environment**: `cae-rebc-{env}`
- **Container App Job - Bill**: `caj-bill-{env}`
- **Container App Job - Data**: `caj-data-{env}`
- **SQL Server**: `sql-rebc-{env}`
- **SQL Database**: `db-rebc-{env}`
- **Private Endpoint - Container Registry**: `pe-cr-{env}`
- **Private Endpoint - Container Apps Environment**: `pe-cae-{env}`
- **Private Endpoint - SQL Server**: `pe-sql-{env}`

All private endpoints use the existing subnet `snet-bcr` (`10.0.0.0/27`) within `vnet-internal`.

## Prerequisites

### Azure Resources (Must Exist)
- **Subscription**: rebcsubtest
- **Connectivity Resource Group**: rg-net
- **Virtual Network**: vnet-internal
- **Subnet**: snet-bcr (`10.0.0.0/27`, no delegation required)

### Tools Required
- Azure CLI (latest version)
- Bicep CLI (latest version)

## Deployment

### Azure DevOps Pipeline

The pipeline (`azure-pipeline.yml`) validates Bicep templates and deploys to the selected environment. The pipeline uses `trigger: none`, so it must be run manually from Azure DevOps. When running the pipeline, select the target environment (dev, uat, or prod) via the `environment` parameter.

> **Note**: All deployment flags in `parameters.json` are set to `false` by default. Set the required flags to `true` before running the pipeline to deploy specific resources.

### Manual Deployment

```bash
# Deploy to Dev
./deploy.sh dev

# Deploy to UAT
./deploy.sh uat

# Deploy to Prod
./deploy.sh prod
```

## Support

For issues or questions, please contact the Infrastructure Team.
