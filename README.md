# revinfra

Azure Infrastructure as Code (IaC) project using Bicep modules for multi-environment deployment (Dev1, UAT, Prod).

## Overview

This repository contains modular Bicep templates for deploying Azure resources including:
- Resource Groups
- Container Registry (with private endpoint)
- Container Apps Environment (with private endpoint)
- Container App Jobs
- SQL Server & Database (with private endpoint)
- Managed Identity
- Log Analytics Workspace

## Environments
- **Dev1**
- **UAT**
- **Prod**

## Location
All resources are deployed to **Australia East**.

## Quick Start

See the [library/README.md](library/README.md) for complete documentation, deployment instructions, and usage examples.

### Deploy Infrastructure

```bash
cd library
./deploy.sh dev1    # Deploy to Dev1 environment
./deploy.sh uat    # Deploy to UAT environment
./deploy.sh prod   # Deploy to Prod environment
```

## Project Structure

```
revinfra/
├── library/                        # Bicep infrastructure library
│   ├── module/                     # Reusable Bicep modules
│   ├── variable/                   # Configuration files
│   ├── main.bicep                  # Main orchestrator
│   ├── main-resources.bicep        # Resource group scoped deployments
│   ├── deploy.sh                   # Deployment script
│   ├── azure-pipeline.yml          # Azure DevOps pipeline
│   └── README.md                   # Detailed documentation
└── README.md                       # This file
```

## Features

- ✅ Modular and reusable Bicep templates
- ✅ Multi-environment support (Dev1, UAT, Prod)
- ✅ Private endpoints for secure access
- ✅ Managed identity for authentication
- ✅ Manual deployment with Azure DevOps pipeline (environment selectable via parameter, `trigger: none`)
- ✅ Shell script for manual deployment
- ✅ Comprehensive documentation

## Contributing

This is an infrastructure-as-code repository. All changes should be:
1. Tested in Dev1 environment first
2. Validated with Bicep linter
3. Reviewed before merging to main

## License

Copyright © 2026 REBC Infrastructure Team
