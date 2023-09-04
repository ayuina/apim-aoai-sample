targetScope = 'subscription'

param prefix string
param region string
param aoaiRegion string

var rgName = '${prefix}-rg'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: region
}

module monitor './modules/monitor.bicep' = {
  scope: rg
  name: 'monitor'
  params:{
    prefix: prefix
    region: region
  }
}

module aoai './modules/openai.bicep' = {
  scope: rg
  name: 'aoai'
  params:{
    prefix: prefix
    aoaiRegion: aoaiRegion
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module apim './modules/apim-svc.bicep' = {
  scope: rg
  name: 'apim'
  params:{
    prefix: prefix
    region: region
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module aoai_api './modules/apim-openai-api.bicep' = {
  scope: rg
  name: 'aoai_api'
  params:{
    apimName: apim.outputs.apiManagementName
    aoaiName: aoai.outputs.aoaiAccountName
  }
}

