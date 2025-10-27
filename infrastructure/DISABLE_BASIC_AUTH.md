# Quick Reference: Disable Basic Authentication

This file provides quick CLI commands for disabling FTP and SCM basic authentication on Azure App Service.

## Using Bicep Template (Recommended)

Deploy the Bicep template to both app services:

```bash
# For my-sre-app-tr
az deployment group create \
  --resource-group sre-demo-rg \
  --template-file infrastructure/disable-basic-auth.bicep \
  --parameters appServiceName=my-sre-app-tr

# For my-sre-app-tr123986 (if needed)
az deployment group create \
  --resource-group sre-demo-rg \
  --template-file infrastructure/disable-basic-auth.bicep \
  --parameters appServiceName=my-sre-app-tr123986
```

## Using Azure CLI Directly

Alternatively, use direct Azure CLI commands:

### For my-sre-app-tr

```bash
# Disable FTP basic authentication
az resource update \
  --resource-group sre-demo-rg \
  --name ftp \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --parent sites/my-sre-app-tr \
  --set properties.allow=false

# Disable SCM basic authentication
az resource update \
  --resource-group sre-demo-rg \
  --name scm \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --parent sites/my-sre-app-tr \
  --set properties.allow=false
```

### For my-sre-app-tr123986

```bash
# Disable FTP basic authentication
az resource update \
  --resource-group sre-demo-rg \
  --name ftp \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --parent sites/my-sre-app-tr123986 \
  --set properties.allow=false

# Disable SCM basic authentication
az resource update \
  --resource-group sre-demo-rg \
  --name scm \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --parent sites/my-sre-app-tr123986 \
  --set properties.allow=false
```

## Verification

Check the status of basic authentication policies:

```bash
# Check FTP basic auth status for my-sre-app-tr
az resource show \
  --resource-group sre-demo-rg \
  --name ftp \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --parent sites/my-sre-app-tr \
  --query properties.allow

# Check SCM basic auth status for my-sre-app-tr
az resource show \
  --resource-group sre-demo-rg \
  --name scm \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --parent sites/my-sre-app-tr \
  --query properties.allow
```

Both commands should return `false` when basic authentication is disabled.

## Using Azure Portal

You can also verify/configure this in the Azure Portal:

1. Navigate to your App Service
2. Go to **Configuration** → **General settings**
3. Scroll to **Platform settings**
4. Find **Basic Auth Publishing Credentials**
5. Set **SCM Basic Auth Publishing Credentials** to **Off**
6. Set **FTP Basic Auth Publishing Credentials** to **Off**
7. Click **Save**

## Rollback (Emergency Only)

If you need to temporarily re-enable basic authentication:

```bash
# Re-enable FTP basic authentication
az resource update \
  --resource-group sre-demo-rg \
  --name ftp \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --parent sites/my-sre-app-tr \
  --set properties.allow=true

# Re-enable SCM basic authentication
az resource update \
  --resource-group sre-demo-rg \
  --name scm \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --parent sites/my-sre-app-tr \
  --set properties.allow=true
```

⚠️ **Important:** After re-enabling, immediately rotate any credentials used and resume remediation.
