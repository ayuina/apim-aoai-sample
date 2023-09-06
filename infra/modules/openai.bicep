param postfix string
param aoaiRegion string
param logAnalyticsName string

var aoaiName = 'aoai-${postfix}'

// https://learn.microsoft.com/ja-jp/azure/ai-services/openai/concepts/models#gpt-35-models
var modelRegionMap = {
  australiaeast: { model: 'gpt-35-turbo', deploy: 'g35t', version: '0613' }
  canadaeast: { model: 'gpt-35-turbo', deploy: 'g35t', version: '0613' }
  eastus: { model: 'gpt-35-turbo', deploy: 'g35t', version: '0613' }
  eastus2: { model: 'gpt-35-turbo', deploy: 'g35t', version: '0613' }
  francecentral: { model: 'gpt-35-turbo', deploy: 'g35t', version: '0613' }
  japaneast: { model: 'gpt-35-turbo', deploy: 'g35t', version: '0613' }
  northcentralus: { model: 'gpt-35-turbo', deploy: 'g35t', version: '0613' }
  switzerlandnorth: { model: 'gpt-35-turbo', deploy: 'g35t', version: '0613' }
  uksouth: { model: 'gpt-35-turbo', deploy: 'g35t', version: '0613' }
  southcentralus: { model: 'gpt-35-turbo', deploy: 'g35t', version: '0301' }
  westeurope: { model: 'gpt-35-turbo', deploy: 'g35t', version: '0301' }
}

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
  name: modelRegionMap[aoaiRegion].deploy
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelRegionMap[aoaiRegion].model
      version: modelRegionMap[aoaiRegion].version
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
output gptModelDeployment object = modelRegionMap[aoaiRegion]

