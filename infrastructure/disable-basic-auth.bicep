// Bicep template to disable FTP and SCM basic authentication for Azure App Service
// This template should be deployed to enforce identity-based authentication only

@description('The name of the App Service')
param appServiceName string

// Reference to existing App Service
resource appService 'Microsoft.Web/sites@2023-01-01' existing = {
  name: appServiceName
}

// Disable FTP basic authentication
resource ftpBasicAuthPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: appService
  name: 'ftp'
  properties: {
    allow: false
  }
}

// Disable SCM (Kudu) basic authentication
resource scmBasicAuthPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: appService
  name: 'scm'
  properties: {
    allow: false
  }
}

output ftpBasicAuthDisabled bool = !ftpBasicAuthPolicy.properties.allow
output scmBasicAuthDisabled bool = !scmBasicAuthPolicy.properties.allow
