# revinfra

Azure Infrastructure as Code (IaC) project using Bicep modules for multi-environment deployment (Dev, UAT, Prod).

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
- **Dev**
- **UAT**
- **Prod**

## Location
All resources are deployed to **Australia East**.