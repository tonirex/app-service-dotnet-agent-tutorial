# Setting Up OIDC Authentication for GitHub Actions

This guide explains how to configure OpenID Connect (OIDC) authentication for GitHub Actions to deploy to Azure App Service without using publish profiles or other shared secrets.

## Overview

OIDC allows GitHub Actions to authenticate directly to Azure using short-lived tokens, eliminating the need for storing long-lived credentials as secrets. This is more secure and aligns with identity-based authentication best practices.

## Prerequisites

- Azure subscription with appropriate permissions
- GitHub repository with the code to deploy
- Azure CLI installed (for setup steps)

## Step 1: Create an Azure AD Application and Service Principal

1. **Create an Azure AD Application:**
   ```bash
   az ad app create --display-name "GitHub-OIDC-my-sre-app-tr"
   ```

2. **Note the Application (Client) ID** from the output. You'll need this later.

3. **Create a Service Principal for the application:**
   ```bash
   az ad sp create --id <APPLICATION_ID>
   ```

4. **Note the Object ID** of the service principal.

## Step 2: Configure Federated Credentials for GitHub

Configure the Azure AD application to trust tokens from GitHub Actions:

```bash
az ad app federated-credential create \
  --id <APPLICATION_ID> \
  --parameters '{
    "name": "GitHub-OIDC-my-sre-app-tr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:tonirex/app-service-dotnet-agent-tutorial:ref:refs/heads/main",
    "description": "GitHub Actions OIDC for main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

**Important:** Replace `tonirex/app-service-dotnet-agent-tutorial` with your actual GitHub organization/username and repository name.

### For Pull Requests (Optional)

If you want to deploy from pull requests, add another federated credential:

```bash
az ad app federated-credential create \
  --id <APPLICATION_ID> \
  --parameters '{
    "name": "GitHub-OIDC-PR",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:tonirex/app-service-dotnet-agent-tutorial:pull_request",
    "description": "GitHub Actions OIDC for pull requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

## Step 3: Assign Permissions to the Service Principal

Grant the service principal permission to deploy to the App Service:

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Assign the "Website Contributor" role to the service principal for the App Service
az role assignment create \
  --role "Website Contributor" \
  --assignee <SERVICE_PRINCIPAL_OBJECT_ID> \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/sre-demo-rg/providers/Microsoft.Web/sites/my-sre-app-tr"
```

Alternatively, assign at the resource group level:

```bash
az role assignment create \
  --role "Website Contributor" \
  --assignee <SERVICE_PRINCIPAL_OBJECT_ID> \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/sre-demo-rg"
```

## Step 4: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add the following repository secrets:

   - `AZURE_CLIENT_ID`: The Application (Client) ID from Step 1
   - `AZURE_TENANT_ID`: Your Azure AD Tenant ID (get it with `az account show --query tenantId -o tsv`)
   - `AZURE_SUBSCRIPTION_ID`: Your Azure Subscription ID (get it with `az account show --query id -o tsv`)

**Note:** These are not secrets in the traditional sense—they're identifiers. The actual authentication happens via OIDC token exchange.

## Step 5: Update GitHub Actions Workflow

The workflows in `.github/workflows/` have been updated to use OIDC authentication. Key changes:

```yaml
deploy:
  permissions:
    id-token: write  # Required for OIDC
    contents: read

  steps:
    - name: Login to Azure
      uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v3
      with:
        app-name: 'my-sre-app-tr'
        package: .
        # No publish-profile needed!
```

## Step 6: Disable Basic Authentication on App Service

Deploy the Bicep template to disable FTP and SCM basic authentication:

```bash
# Login to Azure
az login

# Deploy the template
az deployment group create \
  --resource-group sre-demo-rg \
  --template-file infrastructure/disable-basic-auth.bicep \
  --parameters infrastructure/disable-basic-auth.parameters.json
```

Or use Azure CLI directly:

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

## Step 7: Verify Configuration

1. **Test the GitHub Actions workflow:**
   - Push a commit to the main branch
   - Monitor the workflow run in GitHub Actions
   - Verify that it authenticates and deploys successfully

2. **Verify basic authentication is disabled:**
   ```bash
   # Check FTP basic auth status
   az resource show \
     --resource-group sre-demo-rg \
     --name ftp \
     --namespace Microsoft.Web \
     --resource-type basicPublishingCredentialsPolicies \
     --parent sites/my-sre-app-tr \
     --query properties.allow
   
   # Check SCM basic auth status
   az resource show \
     --resource-group sre-demo-rg \
     --name scm \
     --namespace Microsoft.Web \
     --resource-type basicPublishingCredentialsPolicies \
     --parent sites/my-sre-app-tr \
     --query properties.allow
   ```
   
   Both should return `false`.

## Step 8: Clean Up Old Secrets

After verifying that OIDC authentication works:

1. Remove the old publish profile secrets from GitHub:
   - `AZUREAPPSERVICE_PUBLISHPROFILE_C4289D4AE87543A8B4C761C9DC2FE523`
   - `AZUREAPPSERVICE_PUBLISHPROFILE_C1A8AD9F02224C0DA39CD59AB81C185B`

2. Reset the publish profile in Azure App Service (optional, for defense in depth):
   ```bash
   az webapp deployment list-publishing-profiles \
     --resource-group sre-demo-rg \
     --name my-sre-app-tr \
     --query "[0].userPWD" -o tsv
   ```

## Troubleshooting

### Error: "Failed to authenticate"
- Verify the federated credential subject matches exactly: `repo:OWNER/REPO:ref:refs/heads/BRANCH`
- Check that the service principal has the necessary permissions
- Ensure the workflow has `id-token: write` permission

### Error: "Cannot access App Service"
- Verify role assignments with: `az role assignment list --assignee <SERVICE_PRINCIPAL_OBJECT_ID>`
- Ensure the service principal has at least "Website Contributor" role

### Basic authentication still enabled
- Check that the Bicep deployment succeeded
- Verify settings in Azure Portal under **Configuration** → **General settings** → **Basic Auth Publishing Credentials**

## Benefits of OIDC Authentication

✅ **No stored secrets**: Eliminates risk of credential leakage  
✅ **Short-lived tokens**: Tokens expire quickly, reducing attack window  
✅ **Identity-based**: Uses Azure AD for authentication and authorization  
✅ **Fine-grained access**: RBAC controls what the identity can do  
✅ **Audit trail**: All actions are logged in Azure AD  
✅ **Compliant**: Aligns with zero-trust and least-privilege principles  

## References

- [Configure OpenID Connect in Azure](https://learn.microsoft.com/azure/developer/github/connect-from-azure)
- [GitHub Actions OIDC with Azure](https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Azure App Service Deployment Best Practices](https://learn.microsoft.com/azure/app-service/deploy-best-practices)
- [Disable Basic Authentication in App Service](https://learn.microsoft.com/azure/app-service/configure-basic-auth-disable)
