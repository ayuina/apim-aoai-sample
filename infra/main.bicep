targetScope='subscription'

param environmentName string
param region string
param aoaiRegion string = ''

var postfix = toLower(uniqueString(subscription().id, region, environmentName))
var rgName = 'rg-${environmentName}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: region
}

module monitor './modules/monitor.bicep' = {
  name: 'monitor'
  scope: rg
  params:{
    postfix: postfix
    region: region
  }
}

module aoai './modules/openai.bicep' = {
  name: 'aoai'
  scope: rg
  params:{
    postfix: postfix
    aoaiRegion: !empty(aoaiRegion) ? aoaiRegion : region
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module apim './modules/apim-svc.bicep' = {
  name: 'apim'
  scope: rg
  params:{
    postfix: postfix
    region: region
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module aoai_api './modules/apim-openai-apidef.bicep' = {
  name: 'aoai_api'
  scope: rg
  params:{
    apimName: apim.outputs.apiManagementName
    aiLoggerName: apim.outputs.appinsightsLoggerName
    aoaiName: aoai.outputs.aoaiAccountName
  }
}

output API_MANAGEMENT_ENDPOINT string = 'https://${apim.outputs.apiManagementName}.azure-api.net'
output AZURE_OPENAI_ENDPOINT string = 'https://${aoai.outputs.aoaiAccountName}.openai.azure.com'

