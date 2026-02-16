# REBC Infrastructure Library

This directory contains modular Bicep templates for deploying Azure infrastructure across multiple environments (Dev, UAT, Prod).

## Directory Structure

```
library/
├── module/                              # Reusable Bicep modules
│   ├── resourceGroup.bicep              # Resource Group module
│   ├── virtualNetwork.bicep             # Virtual Network module
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
├── parameters.bicep                     # Parameter loader
├── deploy.sh                            # Deployment script
└── azure-pipeline.yml                   # Azure DevOps pipeline

```

## Resources Deployed

### Core Infrastructure
- **Resource Group**: `rg-rebc-{env}`
- **Managed Identity**: `mi-rebc-{env}` (User-assigned)
- **Log Analytics Workspace**: `log-rebc-{env}`

### Container Infrastructure
- **Container Registry**: `acraetestrebc{env}` (Premium SKU, private access only)
- **Container Apps Environment**: `cae-rebc-{env}` (Internal-only, private access)
- **Container App Job - Bill**: `caj-bill-{env}`
- **Container App Job - Data**: `caj-data-{env}`

### Database Infrastructure
- **SQL Server**: `sql-rebc-{env}` (Private access only)
- **SQL Database**: `db-rebc-{env}` (Standard S0, 10 DTUs, 5GB)

### Network Infrastructure
- **Network Resource Group**: `rg-network-{env}`
- **Virtual Network**: `vnet-rebc-{env}` with subnet `snet-rebc`
- **Private Endpoint - Container Registry**: `pe-cr-{env}`
- **Private Endpoint - Container Apps Environment**: `pe-cae-{env}`
- **Private Endpoint - SQL Server**: `pe-sql-{env}`

All private endpoints connect to the subnet `snet-rebc` within the deployed virtual network.

## Prerequisites

### Azure Resources (Must Exist)
- **Subscription**: rebcsubtest

### Tools Required
- Azure CLI (latest version)
- Bicep CLI (latest version)
- Bash shell (for deployment script)

## Configuration

### Environment Parameters

The `parameters.json` file contains configuration for all three environments. Each environment has the following configurable options:

- **Deployment flags**: Control which resources to deploy (including network resources)
- **SQL credentials**: Administrator login and password
- **VNet address prefixes**: Address space for the virtual network and subnet
- **Container image**: Docker image to use for Container App Jobs

### Tags

Common tags are defined in `tags.json` and automatically applied to all resources:
- Project: REBC
- ManagedBy: Infrastructure Team
- CostCenter: IT-001
- Department: Infrastructure
- Environment: {env} (added dynamically)

## Deployment

### Option 1: Using the Deployment Script (Recommended)

```bash
# Navigate to the library directory
cd library

# Deploy to Dev
./deploy.sh dev

# Deploy to UAT
./deploy.sh uat

# Deploy to Prod
./deploy.sh prod
```

The script will:
1. Show a What-If analysis
2. Ask for confirmation
3. Deploy the infrastructure

### Option 2: Manual Deployment

```bash
# Deploy to Dev
az deployment sub create \
  --location australiaeast \
  --template-file main.bicep \
  --parameters environment=dev \
  --name deploy-rebc-dev-$(date +%Y%m%d-%H%M%S)

# Deploy to UAT
az deployment sub create \
  --location australiaeast \
  --template-file main.bicep \
  --parameters environment=uat \
  --name deploy-rebc-uat-$(date +%Y%m%d-%H%M%S)

# Deploy to Prod
az deployment sub create \
  --location australiaeast \
  --template-file main.bicep \
  --parameters environment=prod \
  --name deploy-rebc-prod-$(date +%Y%m%d-%H%M%S)
```

### Option 3: Azure DevOps Pipeline

The pipeline is configured with three stages:
- **Dev**: Deploys automatically on commit to main/develop
- **UAT**: Deploys after Dev with approval gate
- **Prod**: Deploys after UAT with approval gate

To use the pipeline:
1. Create environments in Azure DevOps: dev, uat, prod
2. Configure approval gates for UAT and Prod
3. Update the `azureServiceConnection` variable with your service connection name
4. Commit the pipeline to your repository

## Post-Deployment Tasks

### Pushing Images to Container Registry

After deployment, you can push Docker images to the Container Registry:

```bash
# 1. Build your Docker image
docker build -t myapp:latest .

# 2. Get the registry login server (from deployment output)
REGISTRY_NAME="acraetestrebc{env}"
ACR_LOGIN_SERVER="${REGISTRY_NAME}.azurecr.io"

# 3. Tag the image for ACR
docker tag myapp:latest ${ACR_LOGIN_SERVER}/myapp:latest

# 4. Login to ACR
az acr login --name ${REGISTRY_NAME}

# 5. Push the image
docker push ${ACR_LOGIN_SERVER}/myapp:latest
```

**Note**: Since the Container Registry has public access disabled, you must push from:
- A machine with access to the private endpoint, OR
- Using Azure CLI with appropriate permissions

### Accessing Private Resources

To access resources with private endpoints:
1. Connect from a VM within the same VNet
2. Use Azure Bastion or VPN to access the VNet
3. Ensure DNS resolution is configured for private endpoints

## Validation

### Validate Bicep Templates

```bash
# Validate all templates
az bicep build --file main.bicep

# Validate deployment for specific environment
az deployment sub validate \
  --location australiaeast \
  --template-file main.bicep \
  --parameters environment=dev
```

### What-If Analysis

```bash
# See what changes will be made
az deployment sub what-if \
  --location australiaeast \
  --template-file main.bicep \
  --parameters environment=dev
```

## Security Features

- **Private Endpoints**: All critical resources use private endpoints
- **No Public Access**: Container Registry, SQL Server, and Container Apps Environment have public access disabled
- **Managed Identity**: Resources use user-assigned managed identity for authentication
- **TLS 1.2**: SQL Server requires minimum TLS version 1.2
- **Premium SKU**: Container Registry uses Premium SKU for enhanced security features

## Troubleshooting

### Common Issues

1. **VNet/Subnet Not Found**
   - Ensure `deployNetworkResourceGroup` and `deployVirtualNetwork` are `true` in parameters.json
   - Verify VNet address prefixes don't conflict with existing networks

2. **Deployment Fails on Private Endpoint**
   - Verify the subnet is not used by other services
   - Check that the subnet has enough available IP addresses

3. **Container Apps Environment Deployment Timeout**
   - This resource can take 10-15 minutes to deploy
   - The deployment is asynchronous and will complete eventually

4. **Cannot Push to Container Registry**
   - Verify you have access to the private endpoint
   - Use `az acr login` with appropriate credentials

## Contributing

When adding new resources:
1. Create a new module in the `module/` directory
2. Add the module reference in `main.bicep`
3. Update `parameters.json` with necessary parameters
4. Update this README with documentation

## Support

For issues or questions, please contact the Infrastructure Team.

## License

Copyright © 2026 REBC Infrastructure Team
