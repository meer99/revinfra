# Quick Reference Guide

## File Structure

```
library/
├── module/                              # Reusable Bicep modules (10 modules)
│   ├── resourceGroup.bicep              # Resource Group (subscription scope)
│   ├── managedIdentity.bicep            # User-assigned Managed Identity
│   ├── logAnalyticsWorkspace.bicep      # Log Analytics Workspace
│   ├── containerRegistry.bicep          # Azure Container Registry (Premium)
│   ├── containerAppsEnvironment.bicep   # Container Apps Environment (internal)
│   ├── containerAppJob1.bicep           # Container App Job for caj-bill-{env}
│   ├── containerAppJob2.bicep           # Container App Job for caj-data-{env}
│   ├── sqlServer.bicep                  # Azure SQL Server
│   ├── sqlDatabase.bicep                # Azure SQL Database
│   └── privateEndpoint.bicep            # Private Endpoint (reusable)
├── variable/
│   ├── tags.json                        # Common resource tags
│   ├── variable.json                    # Shared variables (names, location)
│   └── parameters.json                  # Environment-specific parameters
├── main.bicep                           # Subscription-level orchestrator
├── main-resources.bicep                 # Resource group-level deployments
├── deploy.sh                            # Deployment script
├── azure-pipeline.yml                   # Azure DevOps CI/CD pipeline
├── README.md                            # Main documentation
├── DEPLOYMENT_GUIDE.md                  # Detailed deployment guide
└── QUICK_REFERENCE.md                   # This file
```

## Resource Naming Convention

| Resource | Pattern | Dev Example | UAT Example | Prod Example |
|----------|---------|-------------|-------------|--------------|
| Resource Group | `rg-rebc-{env}` | rg-rebc-dev | rg-rebc-uat | rg-rebc-prod |
| Managed Identity | `mi-rebc-{env}` | mi-rebc-dev | mi-rebc-uat | mi-rebc-prod |
| Container Registry | `acraetestrebc{env}` | acraetestrebcdev | acraetestrebcuat | acraetestrebcprod |
| Container Apps Env | `cae-rebc-{env}` | cae-rebc-dev | cae-rebc-uat | cae-rebc-prod |
| Container App Job (Bill) | `caj-bill-{env}` | caj-bill-dev | caj-bill-uat | caj-bill-prod |
| Container App Job (Data) | `caj-data-{env}` | caj-data-dev | caj-data-uat | caj-data-prod |
| SQL Server | `sql-rebc-{env}` | sql-rebc-dev | sql-rebc-uat | sql-rebc-prod |
| SQL Database | `db-rebc-{env}` | db-rebc-dev | db-rebc-uat | db-rebc-prod |
| Log Analytics | `log-rebc-{env}` | log-rebc-dev | log-rebc-uat | log-rebc-prod |
| Private Endpoint (ACR) | `pe-cr-{env}` | pe-cr-dev | pe-cr-uat | pe-cr-prod |
| Private Endpoint (CAE) | `pe-cae-{env}` | pe-cae-dev | pe-cae-uat | pe-cae-prod |
| Private Endpoint (SQL) | `pe-sql-{env}` | pe-sql-dev | pe-sql-uat | pe-sql-prod |

## Common Commands

### Deployment

```bash
# Deploy to specific environment
cd library
./deploy.sh dev    # or uat, or prod

# Manual deployment
az deployment sub create \
  --location australiaeast \
  --template-file main.bicep \
  --parameters environment=dev \
  --name deploy-rebc-dev-$(date +%Y%m%d)
```

### Validation

```bash
# Validate Bicep syntax
az bicep build --file main.bicep

# Validate deployment
az deployment sub validate \
  --location australiaeast \
  --template-file main.bicep \
  --parameters environment=dev

# What-If analysis
az deployment sub what-if \
  --location australiaeast \
  --template-file main.bicep \
  --parameters environment=dev
```

### Container Registry

```bash
# Login
az acr login --name acraetestrebcdev

# List images
az acr repository list --name acraetestrebcdev

# Push image
docker tag myapp:latest acraetestrebcdev.azurecr.io/myapp:latest
docker push acraetestrebcdev.azurecr.io/myapp:latest
```

### SQL Database

```bash
# List databases
az sql db list --server sql-rebc-dev --resource-group rg-rebc-dev

# Connect (requires private access or VPN)
sqlcmd -S sql-rebc-dev.database.windows.net -U sqladmin -P <password> -d db-rebc-dev
```

### Container App Jobs

```bash
# List jobs
az containerapp job list --resource-group rg-rebc-dev

# Start a job manually
az containerapp job start --name caj-bill-dev --resource-group rg-rebc-dev

# View job execution history
az containerapp job execution list --name caj-bill-dev --resource-group rg-rebc-dev
```

### Resource Management

```bash
# List all resources in environment
az resource list --resource-group rg-rebc-dev --output table

# Get resource group info
az group show --name rg-rebc-dev

# Export template
az group export --name rg-rebc-dev > exported-template.json

# Delete environment (careful!)
az group delete --name rg-rebc-dev --yes
```

## Configuration Files

### variable/parameters.json

Controls which resources are deployed per environment:

```json
{
  "dev": {
    "deployResourceGroup": true,
    "deployManagedIdentity": true,
    "deployLogAnalyticsWorkspace": true,
    "deployContainerRegistry": true,
    "deployContainerAppsEnvironment": true,
    "deployContainerAppJobBill": true,
    "deployContainerAppJobData": true,
    "deploySqlServer": true,
    "deploySqlDatabase": true,
    "deployPrivateEndpointContainerRegistry": true,
    "deployPrivateEndpointContainerAppsEnvironment": true,
    "deployPrivateEndpointSqlServer": true,
    "sqlAdministratorLogin": "sqladmin",
    "sqlAdministratorLoginPassword": "P@ssw0rd!",
    "existingVnetResourceGroup": "rg-net",
    "containerImage": "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  }
}
```

### variable/tags.json

Common tags applied to all resources:

```json
{
  "Project": "REBC",
  "ManagedBy": "Infrastructure Team",
  "CostCenter": "IT-001",
  "Department": "Infrastructure"
}
```

### variable/variable.json

Shared configuration:

```json
{
  "location": "australiaeast",
  "subscriptionName": "rebcsubtest",
  "vnetName": "vnet-internal",
  "subnetNameCae": "snet-cae",
  "subnetNamePe": "snet-pe",
  "namePatterns": { ... }
}
```

## Module Parameters

### Common Parameters (all modules)
- `environment` - Environment name (dev, uat, prod)
- `location` - Azure region (default: australiaeast)
- `tags` - Resource tags object

### containerRegistry.bicep
- `managedIdentityId` - Managed identity resource ID
- `sku` - Registry SKU (default: Premium)

### containerAppsEnvironment.bicep
- `logAnalyticsCustomerId` - Log Analytics workspace ID
- `logAnalyticsSharedKey` - Log Analytics shared key (secure)
- `subnetId` - Subnet resource ID for VNet integration
- `internal` - Internal-only environment (default: true)

### containerAppJob1.bicep
- `environment` - Environment name (dev, uat, prod)
- `containerAppsEnvironmentId` - Container Apps Environment ID
- `managedIdentityId` - Managed identity resource ID
- `containerImage` - Docker image to run
- Hardcoded: jobName as `caj-bill-{env}`, containerName as `bill-processor`, CPU 0.25, Memory 0.5Gi, Manual trigger

### containerAppJob2.bicep
- `environment` - Environment name (dev, uat, prod)
- `containerAppsEnvironmentId` - Container Apps Environment ID
- `managedIdentityId` - Managed identity resource ID
- `containerImage` - Docker image to run
- Hardcoded: jobName as `caj-data-{env}`, containerName as `data-processor`, CPU 0.25, Memory 0.5Gi, Manual trigger

### sqlServer.bicep
- `administratorLogin` - SQL admin username
- `administratorLoginPassword` - SQL admin password (secure)
- `minimalTlsVersion` - Minimum TLS version (default: 1.2)

### sqlDatabase.bicep
- `sqlServerName` - Name of the SQL server
- `skuName` - Database SKU (default: S0)
- `skuTier` - Database tier (default: Standard)
- `capacity` - DTU capacity (default: 10)
- `maxSizeBytes` - Maximum database size (default: 5GB)

### privateEndpoint.bicep
- `privateEndpointName` - Name of the private endpoint
- `subnetId` - Subnet resource ID
- `privateLinkServiceId` - Target resource ID
- `groupIds` - Sub-resource group IDs (e.g., ['registry'], ['sqlServer'])

## Troubleshooting Quick Fixes

### Build Error: "anonymousPullEnabled not allowed"
**Fixed** - Property removed from containerRegistry.bicep

### Error: "resourceGroup is not a function"
**Fixed** - Using `az.resourceGroup()` at subscription scope

### Warning: "BCP318 - value may be null"
**Expected** - Occurs with conditional deployments, safe to ignore

### Error: "VNet not found"
- Check `existingVnetResourceGroup` in parameters.json
- Verify VNet/Subnet exist in subscription

### Error: "Insufficient permissions"
- Requires Contributor or Owner role
- Network Contributor needed for private endpoints

## Security Notes

- 🔒 All passwords should be stored in Azure Key Vault in production
- 🔒 Container Registry has public access DISABLED
- 🔒 SQL Server has public access DISABLED
- 🔒 Container Apps Environment is internal-only
- 🔒 All critical resources use private endpoints
- 🔒 Managed identity used instead of passwords where possible
- 🔒 Minimum TLS 1.2 enforced on SQL Server

## Pipeline Workflow

```
Dev Stage
  ↓ (auto)
UAT Stage
  ↓ (approval required)
Prod Stage
  ↓ (approval required)
Complete
```

Each stage:
1. Install/upgrade Bicep CLI
2. Validate template
3. Deploy infrastructure
4. Run post-deployment tests
5. (Prod only) Publish artifacts

## Quick Links

- [Main Documentation](README.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Bicep Language Reference](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure Container Apps Docs](https://learn.microsoft.com/en-us/azure/container-apps/)

## Support

- Check logs: `az deployment sub operation list --name <deployment-name>`
- Review errors: See DEPLOYMENT_GUIDE.md Troubleshooting section
- Contact: Infrastructure Team

---

**Last Updated**: 2026-02-16
**Version**: 1.0.0
