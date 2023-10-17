param postfix string
param region string
param logAnalyticsName string
param enableManagedIdAuth bool
param apimSku string
param publisherName string
param publisherEmail string

var apimName = 'apim-${postfix}'
var apimid = enableManagedIdAuth ? { type: 'SystemAssigned' } : null
var appInsightsName = 'appi-${apimName}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsName
}

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: region
  kind: 'web'
  properties:{
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource apiman 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apimName
  location: region
  sku: {
    name: apimSku
    capacity: apimSku == 'Consumption' ? 0 : 1
  }
  properties: {
    publisherName: publisherName
    publisherEmail: publisherEmail
  }
  identity: apimid

  resource ailogger 'loggers' = {
    name: '${appInsightsName}-logger'
    properties: {
      loggerType: 'applicationInsights'
      resourceId: appinsights.id
      credentials: {
        instrumentationKey: appinsights.properties.InstrumentationKey
      }
    }
  }
}

resource apimDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${apiman.name}-diag'
  scope: apiman
  properties: {
    workspaceId: logAnalytics.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
      {
        category: 'WebSocketConnectionLogs'
        enabled: true
      }
    ]
    metrics: [
      {
         category: 'AllMetrics'
         enabled: true
      }
    ]
  }
}

output apiManagementName string = apiman.name
output appinsightsLoggerName string = apiman::ailogger.name
