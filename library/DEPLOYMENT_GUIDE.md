# Deployment Guide

This guide provides step-by-step instructions for deploying the REBC infrastructure across different environments.

## Prerequisites

### Required Tools
- **Azure CLI** (version 2.50.0 or later)
  ```bash
  az --version
  ```
- **Bicep CLI** (version 0.20.0 or later)
  ```bash
  az bicep version
  ```
- **Bash shell** (Linux, macOS, or WSL on Windows)
- **jq** (for JSON parsing in deploy script)
  ```bash
  sudo apt-get install jq  # Ubuntu/Debian
  brew install jq          # macOS
  ```

### Azure Prerequisites
- Active Azure subscription
- Appropriate permissions to create resources
- Existing Virtual Network and Subnets:
  - Resource Group: `rg-net`
  - VNet: `vnet-internal`
  - Subnet: `snet-cae` (delegated to `Microsoft.App/environments`, used exclusively by Container Apps Environment)
  - Subnet: `snet-pe` (used for private endpoints — Container Registry, Container Apps Environment, SQL Server)
- Resource group where the VNet resides (configured per environment in `parameters.json`)

## Configuration

### 1. Review Parameters

Edit `library/variable/parameters.json` to configure each environment:

```json
{
  "dev": {
    "deployResourceGroup": true,
    "deployManagedIdentity": true,
    ...
    "sqlAdministratorLogin": "sqladmin",
    "sqlAdministratorLoginPassword": "YourSecurePassword!",
    "existingVnetResourceGroup": "rg-net"
  }
}
```

**Important Security Note**: In production, store sensitive values like passwords in Azure Key Vault and reference them in the deployment, rather than storing them in plain text.

### 2. Review Tags

Edit `library/variable/tags.json` to set organization-specific tags:

```json
{
  "Project": "REBC",
  "ManagedBy": "Infrastructure Team",
  "CostCenter": "IT-001",
  "Department": "Infrastructure"
}
```

### 3. Customize Resource Names

Edit `library/variable/variable.json` if you need to change resource name patterns:

```json
{
  "location": "australiaeast",
  "namePatterns": {
    "resourceGroup": "rg-rebc",
    "managedIdentity": "mi-rebc",
    ...
  }
}
```

## Deployment Options

### Option 1: Using Deploy Script (Recommended)

The deploy script provides:
- Pre-deployment validation
- What-If analysis
- Confirmation prompts
- Detailed output
- Post-deployment instructions

```bash
cd library

# Deploy to Dev
./deploy.sh dev

# Deploy to UAT
./deploy.sh uat

# Deploy to Prod
./deploy.sh prod
```

The script will:
1. Check Azure login status
2. Validate the Bicep template
3. Show what changes will be made (What-If)
4. Ask for confirmation
5. Deploy the infrastructure
6. Display deployment outputs

### Option 2: Manual Azure CLI Deployment

```bash
cd library

# Login to Azure
az login

# Set the subscription (if you have multiple)
az account set --subscription "rebcsubtest"

# Validate the template
az deployment sub validate \
  --location australiaeast \
  --template-file main.bicep \
  --parameters environment=dev

# What-If analysis (preview changes)
az deployment sub what-if \
  --location australiaeast \
  --template-file main.bicep \
  --parameters environment=dev

# Deploy
az deployment sub create \
  --location australiaeast \
  --template-file main.bicep \
  --parameters environment=dev \
  --name deploy-rebc-dev-$(date +%Y%m%d-%H%M%S)
```

### Option 3: Azure DevOps Pipeline

1. **Setup Prerequisites**:
   - Create service connection in Azure DevOps
   - Create environments: `dev`, `uat`, `prod`
   - Configure approval gates for UAT and Prod

2. **Configure Pipeline**:
   - Update `azureServiceConnection` variable in `azure-pipeline.yml`
   - Push the code to your repository
   - Create a new pipeline pointing to `azure-pipeline.yml`

3. **Run Pipeline**:
   - Pipeline triggers automatically on commits to `main` or `develop` branches
   - Manual trigger available in Azure DevOps UI
   - Stages: Dev → UAT (with approval) → Prod (with approval)

## Post-Deployment Tasks

### 1. Verify Deployment

```bash
# Check resource group
az group show --name rg-rebc-dev

# List all resources in the resource group
az resource list --resource-group rg-rebc-dev --output table

# Check specific resources
az acr show --name acraetestrebcdev
az sql server show --name sql-rebc-dev --resource-group rg-rebc-dev
```

### 2. Push Container Image to Registry

After deployment, push your Docker images to the Container Registry:

```bash
# Variables
ENVIRONMENT="dev"
REGISTRY_NAME="acraetestrebc${ENVIRONMENT}"
IMAGE_NAME="myapp"
IMAGE_TAG="v1.0.0"

# Build your Docker image
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

# Login to ACR
az acr login --name ${REGISTRY_NAME}

# Tag image for ACR
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}

# Push image
docker push ${REGISTRY_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
```

**Note**: Since the Container Registry has public access disabled, you must push from:
- A machine with access to the private endpoint, OR
- Use Azure CLI authentication with appropriate permissions

### 3. Configure Container App Jobs

Update the Container App Jobs to use your custom image:

```bash
# Update Container App Job image
az containerapp job update \
  --name caj-bill-dev \
  --resource-group rg-rebc-dev \
  --image ${REGISTRY_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
```

### 4. Connect to SQL Database

To connect to the SQL Server (which has public access disabled):

```bash
# From a VM in the same VNet or via VPN/Bastion
sqlcmd -S sql-rebc-dev.database.windows.net -U sqladmin -P YourPassword -d db-rebc-dev
```

Or use Azure Data Studio / SQL Server Management Studio with the same connection details.

### 5. Grant Access to Resources

Grant appropriate permissions to the managed identity:

```bash
# Example: Grant Container Registry pull permissions to managed identity
MANAGED_IDENTITY_ID=$(az identity show \
  --name mi-rebc-dev \
  --resource-group rg-rebc-dev \
  --query principalId -o tsv)

az role assignment create \
  --assignee ${MANAGED_IDENTITY_ID} \
  --role AcrPull \
  --scope $(az acr show --name acraetestrebcdev --query id -o tsv)
```

## Troubleshooting

### Common Issues

#### 1. Resource Group Already Exists
If the resource group already exists and you get an error:
- Set `deployResourceGroup: false` in parameters.json for that environment
- Ensure the resource group name matches the expected pattern

#### 2. VNet/Subnet Not Found
```
Error: The Resource 'Microsoft.Network/virtualNetworks/vnet-internal' under resource group 'rg-net' was not found.
```

**Solution**: 
- Verify the VNet and Subnet exist
- Update `existingVnetResourceGroup` in parameters.json
- Ensure the names in variable.json match your existing resources

#### 3. Insufficient Permissions
```
Error: The client does not have authorization to perform action
```

**Solution**:
- Ensure you have `Owner` or `Contributor` role on the subscription
- For private endpoint creation, you need `Network Contributor` on the subnet

#### 4. Container Apps Environment Deployment Timeout
Container Apps Environment can take 10-15 minutes to deploy.

**Solution**: Be patient, this is expected behavior. The deployment will complete.

#### 5. Cannot Push to Container Registry
```
Error: unauthorized: authentication required
```

**Solution**:
- Use `az acr login --name <registry-name>`
- Ensure you're authenticated to Azure CLI
- Check that you have access to the private endpoint or are using Azure authentication

### Getting Deployment Logs

```bash
# List recent deployments
az deployment sub list --output table

# Get deployment details
az deployment sub show \
  --name deploy-rebc-dev-20260216-123456 \
  --query properties.error

# Get detailed error messages
az deployment sub operation list \
  --name deploy-rebc-dev-20260216-123456 \
  --query "[?properties.provisioningState=='Failed'].{Resource:properties.targetResource.resourceName, Error:properties.statusMessage.error.message}"
```

## Maintenance

### Updating Resources

To update existing resources:

1. Modify the Bicep templates or parameters
2. Run validation: `az bicep build --file main.bicep`
3. Run What-If to see changes: `az deployment sub what-if ...`
4. Deploy the changes using the deploy script

### Destroying Resources

To remove all resources for an environment:

```bash
# Delete the entire resource group
az group delete --name rg-rebc-dev --yes --no-wait
```

**Warning**: This will delete ALL resources in the resource group. Ensure you have backups if needed.

### Backup and Recovery

#### SQL Database Backup
Azure SQL Database has automatic backups enabled by default.

To restore:
```bash
az sql db restore \
  --dest-name db-rebc-dev-restored \
  --resource-group rg-rebc-dev \
  --server sql-rebc-dev \
  --name db-rebc-dev \
  --time "2026-02-16T10:00:00Z"
```

#### Container Registry Images
Images in ACR are highly available. For additional safety:
- Use geo-replication (Premium SKU feature)
- Maintain image backups in another registry or storage

## Best Practices

1. **Always validate before deploying**:
   ```bash
   az deployment sub validate --location australiaeast --template-file main.bicep --parameters environment=dev
   ```

2. **Use What-If before production deployments**:
   ```bash
   az deployment sub what-if --location australiaeast --template-file main.bicep --parameters environment=prod
   ```

3. **Test in Dev first**: Always test changes in Dev environment before promoting to UAT/Prod

4. **Use Key Vault for secrets**: Don't store passwords in parameters.json in production

5. **Tag everything**: Ensure all resources have proper tags for cost tracking

6. **Monitor deployments**: Use Azure Monitor and Log Analytics to track resource health

7. **Document changes**: Keep a changelog of infrastructure modifications

## Security Considerations

- **Private Endpoints**: All critical resources use private endpoints
- **No Public Access**: Container Registry, SQL Server, and Container Apps have public access disabled
- **Managed Identity**: Use managed identity instead of passwords where possible
- **TLS 1.2**: SQL Server enforces minimum TLS 1.2
- **Network Security**: Resources are isolated within the VNet
- **RBAC**: Use Azure Role-Based Access Control for granular permissions

## Support

For issues or questions:
- Check the troubleshooting section above
- Review Azure deployment logs
- Contact the Infrastructure Team

## Additional Resources

- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Azure SQL Database Documentation](https://learn.microsoft.com/en-us/azure/azure-sql/)
- [Azure Private Link Documentation](https://learn.microsoft.com/en-us/azure/private-link/)
