param postfix string
param aoaiRegion string
param logAnalyticsName string

var aoaiName = 'aoai-${aoaiRegion}-${postfix}'
var aoaiModelName = 'gpt-35-turbo'
var aoaiModelDeploy = 'g35t'
var aoaiModelVersion = '0613'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsName
}

resource aoai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aoaiName
  location: aoaiRegion
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: aoaiName
    publicNetworkAccess: 'Enabled'
  }
}

resource chatgpt 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: aoai
  name: aoaiModelDeploy
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: aoaiModelName
      version: aoaiModelVersion
    }
  }
}

resource aoaiDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${aoai.name}-diag'
  scope: aoai
  properties: {
    workspaceId: logAnalytics.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: null
        categoryGroup: 'Audit'
        enabled: true
      }
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
          category: 'AllMetrics'
          enabled: true
          timeGrain: null
      }
    ]
  }
}

output aoaiAccountName string = aoai.name

