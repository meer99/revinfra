# ClickOps to Bicep Migration Guide

This guide explains the step-by-step process for migrating Azure resources that were deployed manually through the Azure Portal (ClickOps) to Infrastructure as Code (IaC) using the Bicep templates in this repository — keeping everything identical.

## Overview

The goal is to bring 13 existing Azure resources under Bicep management so that all future changes are made through code, not the portal. The Bicep templates will be configured to match the current state of the resources exactly.

> **Note:** The current Bicep modules do not manage private endpoints. If your ClickOps resources have private endpoints configured, those will remain as-is and are not affected by the Bicep deployment. Additional modules would need to be added in the future to manage private endpoints through code.

## Prerequisites

### Tools Required

- **Azure CLI** (latest version) — [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Bicep CLI** (latest version) — installed automatically with Azure CLI, or run `az bicep install`

### Access Required

- **Read access** to the Azure subscription where the 13 resources are deployed (to export current configuration)
- **Contributor** (or equivalent) role on the subscription for the Bicep deployment
- Access to this repository to update configuration files

## What We Need from You

Before starting the migration, we need the following information for each of the 13 resources:

| # | Information Needed | How to Get It |
|---|---|---|
| 1 | **Resource names** (exact names of all 13 resources) | Azure Portal → each resource → Overview |
| 2 | **Resource Group name(s)** | Azure Portal → Resource Groups |
| 3 | **Azure region/location** | Azure Portal → each resource → Overview |
| 4 | **SKU/Tier** for each resource (e.g., Container Registry SKU, SQL Database tier) | Azure Portal → each resource → Pricing tier / Properties |
| 5 | **Tags** applied to each resource | Azure Portal → each resource → Tags |
| 6 | **SQL Server admin credentials** (login username; password will need to be provided securely) | Azure Portal → SQL Server → Properties |
| 7 | **Container image** used in Container App Jobs | Azure Portal → Container App Job → Containers |
| 8 | **Networking configuration** (public access enabled/disabled, private endpoints) | Azure Portal → each resource → Networking |
| 9 | **Managed Identity details** (user-assigned identity name, which resources use it) | Azure Portal → Managed Identities |
| 10 | **Log Analytics Workspace** retention and SKU settings | Azure Portal → Log Analytics → Usage and estimated costs |
| 11 | **Container Apps Environment** workload profiles | Azure Portal → Container Apps Environment → Workload profiles |
| 12 | **Subscription ID and name** | Azure Portal → Subscriptions |
| 13 | **Any resource-specific settings** (TLS version, collation, zone redundancy, etc.) | Azure Portal → each resource → Configuration / Properties |

## Step-by-Step Migration Process

### Step 1: Export Current Resource Configuration

For each of the 13 resources, export their current configuration using the Azure CLI. This ensures the Bicep templates match the portal-deployed resources exactly.

```bash
# Login to Azure
az login

# Set the subscription
az account set --subscription "<subscription-id>"

# Export each resource to JSON (example for a resource group's resources)
az group export --name "<resource-group-name>" --output json > exported-resources.json
```

You can also export individual resources:

```bash
# Export a specific resource
az resource show --ids "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/<provider>/<type>/<name>" --output json
```

**Example commands for each resource type:**

```bash
# Resource Group
az group show --name "rg-rebc-dev" --output json

# Managed Identity
az identity show --name "mi-rebc-dev" --resource-group "rg-rebc-dev" --output json

# Log Analytics Workspace
az monitor log-analytics workspace show --workspace-name "log-rebc-dev" --resource-group "rg-rebc-dev" --output json

# Container Registry
az acr show --name "acraetestrebcdev" --resource-group "rg-rebc-dev" --output json

# Container Apps Environment
az containerapp env show --name "cae-rebc-dev" --resource-group "rg-rebc-dev" --output json

# Container App Jobs
az containerapp job show --name "caj-bill-dev" --resource-group "rg-rebc-dev" --output json
az containerapp job show --name "caj-data-dev" --resource-group "rg-rebc-dev" --output json

# SQL Server
az sql server show --name "sql-rebc-dev" --resource-group "rg-rebc-dev" --output json

# SQL Database
az sql db show --name "db-rebc-dev" --server "sql-rebc-dev" --resource-group "rg-rebc-dev" --output json
```

### Step 2: Compare Exported Config with Bicep Templates

Compare the exported JSON properties against the Bicep module parameters in `library/module/` to verify the templates match:

| Resource | Bicep Module | Key Properties to Compare |
|---|---|---|
| Resource Group | `module/resourceGroup.bicep` | name, location, tags |
| Managed Identity | `module/managedIdentity.bicep` | name, location, tags |
| Log Analytics Workspace | `module/logAnalyticsWorkspace.bicep` | name, sku, retentionInDays |
| Container Registry | `module/containerRegistry.bicep` | name, sku, publicNetworkAccess, adminUserEnabled |
| Container Apps Environment | `module/containerAppsEnvironment.bicep` | name, workloadProfiles, zoneRedundant |
| Container App Job (Bill) | `module/containerAppJob1.bicep` | name, containerImage, cpu, memory, triggerType |
| Container App Job (Data) | `module/containerAppJob2.bicep` | name, containerImage, cpu, memory, triggerType |
| SQL Server | `module/sqlServer.bicep` | name, minimalTlsVersion, publicNetworkAccess |
| SQL Database | `module/sqlDatabase.bicep` | name, sku, maxSizeBytes, collation |

### Step 3: Update Configuration Files

Update the configuration files in `library/variable/` to match the existing resources exactly:

1. **`variable/variable.json`** — Set the correct name patterns and location
2. **`variable/tags.json`** — Set the exact tags currently on the resources
3. **`variable/parameters.json`** — Set per-environment parameters (SKUs, credentials, deploy flags)

See the current files for the expected structure and fields.

### Step 4: Validate with What-If (Dry Run)

Before deploying, run a **what-if** operation. This shows what Bicep *would* do without making any changes. The goal is to see **no changes** — meaning the templates match the existing resources.

```bash
cd library

# The Bicep templates load configuration from variable/*.json via loadJsonContent().
# The only external parameter needed is the environment name.
az deployment sub what-if \
    --location australiaeast \
    --template-file main.bicep \
    --parameters environment="dev"
```

**Interpreting the output:**

- ✅ **No change** — The resource already matches the template (this is what we want)
- ⚠️ **Modify** — A property differs; update the Bicep template or parameters to match
- ❌ **Create** — The resource doesn't exist yet; verify the name is correct
- ❌ **Delete** — A resource would be removed; this should not happen with this setup

Iterate on Steps 2–3 until the what-if output shows **no changes** for all resources.

### Step 5: Deploy with Bicep

Once the what-if confirms no changes, deploy to bring the resources under Bicep management:

```bash
# Deploy to Dev first
./deploy.sh dev

# After verifying Dev, deploy to UAT
./deploy.sh uat

# Finally, deploy to Prod
./deploy.sh prod
```

Or use the Azure DevOps pipeline (`azure-pipeline.yml`) — select the target environment when triggering the pipeline manually.

### Step 6: Verify Post-Deployment

After deployment, verify that:

1. All resources still exist and are unchanged in the Azure Portal
2. Applications and services using these resources are working normally
3. Future changes can be made by updating the Bicep templates and redeploying

```bash
# Verify resources exist
az resource list --resource-group "rg-rebc-dev" --output table
```

## Can We Do This?

**Yes.** Bicep deployments are **incremental by default**, meaning:

- Resources defined in the template that **already exist** with matching properties are left **unchanged**
- Resources defined in the template that **differ** from the existing state are **updated** to match
- Resources that are **not in the template** are **left alone** (not deleted)

This makes it safe to "adopt" existing ClickOps resources into Bicep management without recreating or disrupting them.

## Important Notes

- **Always run `what-if` before deploying** to verify no unintended changes
- **Deploy to Dev first**, validate, then move to UAT and Prod
- **SQL passwords** in `parameters.json` must match the existing SQL Server credentials; otherwise the deployment will attempt to update them
- **Private endpoints** are not managed by the current Bicep modules (see the note in the Overview section). Existing private endpoints in the portal are left untouched by the deployment
- **Do not change resource names** in the configuration — they must match exactly to adopt the existing resources

## Summary

| Step | Action | Tool/Command |
|---|---|---|
| 1 | Export current resource config | `az resource show` / `az group export` |
| 2 | Compare with Bicep templates | Manual comparison |
| 3 | Update `variable/` config files | Edit JSON files |
| 4 | Dry run (what-if) | `az deployment sub what-if` |
| 5 | Deploy | `./deploy.sh <env>` or Azure DevOps pipeline |
| 6 | Verify | Azure Portal + `az resource list` |
