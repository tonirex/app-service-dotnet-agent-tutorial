
This sample .NET app demonstrates Azure App Service deployment slots, error simulation, and integration with the Azure SRE (Site Reliability Engineering) Agent for AI-assisted troubleshooting.

## Overview

- **Simulates HTTP 500 errors** in a controlled way, using the `INJECT_ERROR` app setting.
- **Tracks button clicks** and throws an error after several clicks when error injection is enabled.
- **Works with Azure App Service deployment slots**, making it easy to test failures without affecting production.
- **Secure deployment** using GitHub Actions with OpenID Connect (OIDC) for identity-based authentication.

## How it Works

- **Normal Mode:** The main page shows a counter and two buttons: **Refresh** and **Reset Counter**.
- **Error Simulation:** If you set the `INJECT_ERROR` app setting to `1`, clicking "Refresh" 6 times will trigger an HTTP 500 error.
- **Slots:** Run in parallel (e.g., staging vs. production) to test error scenarios safely.

## Deployment

This repository uses **secure, identity-based deployment** to Azure App Service via GitHub Actions:

- ✅ **No publish profiles or shared secrets** - uses OpenID Connect (OIDC) for authentication
- ✅ **Azure AD/Entra ID authentication** - leverages federated credentials
- ✅ **FTP and SCM basic authentication disabled** - enforces identity-based access only
- ✅ **Least-privilege access** - uses role-based access control (RBAC)

### Setting Up Deployment

See **[OIDC_SETUP.md](OIDC_SETUP.md)** for detailed instructions on:
1. Configuring Azure AD application and service principal
2. Setting up federated credentials for GitHub Actions
3. Configuring required GitHub secrets
4. Disabling basic authentication on App Service
5. Validating the secure deployment

### Quick Deployment Steps

1. **Configure Azure AD and OIDC** (one-time setup):
   - Follow the steps in [OIDC_SETUP.md](OIDC_SETUP.md)
   - Add required secrets to GitHub repository

2. **Deploy infrastructure to disable basic auth**:
   ```bash
   az deployment group create \
     --resource-group sre-demo-rg \
     --template-file infrastructure/disable-basic-auth.bicep \
     --parameters infrastructure/disable-basic-auth.parameters.json
   ```

3. **Push to main branch** - GitHub Actions will automatically build and deploy

## Files

| File                          | Description                            |
|-------------------------------|----------------------------------------|
| Program.cs                    | Main app logic and web server setup    |
| appsettings.json              | App configuration (default)            |
| appsettings.Development.json  | Development environment config         |
| SreAgentMemoryDemo.csproj     | Project file                           |
| SreAgentMemoryDemo.http       | HTTP request samples                   |
| infrastructure/               | Bicep templates for Azure resources    |
| .github/workflows/            | GitHub Actions workflows for CI/CD     |
| OIDC_SETUP.md                 | Guide for setting up OIDC auth         |
| LICENSE                       | License for this sample                |
| README.md                     | Project documentation (this file)      |

## Security Features

This repository implements security best practices:

- **Identity-based authentication**: Uses Azure AD OIDC instead of publish profiles
- **No stored secrets**: Short-lived tokens are issued on-demand via OIDC
- **Basic auth disabled**: FTP and SCM endpoints require Azure AD authentication
- **RBAC enforcement**: Deployment uses service principal with least-privilege permissions
- **Audit trail**: All deployments are logged in Azure AD and GitHub Actions
