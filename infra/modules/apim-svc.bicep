param postfix string
param region string
param logAnalyticsName string
param enableManagedIdAuth bool

var apimName = 'apim-${postfix}'
var apimSku = {
  name: 'Consumption'
  capacity: 0
}
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
  sku: apimSku
  properties: {
    publisherName: 'demo'
    publisherEmail: 'demo@sample.com'
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
