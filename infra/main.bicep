
param prefix string
param region string
param aoaiRegion string

module monitor './modules/monitor.bicep' = {
  name: 'monitor'
  params:{
    prefix: prefix
    region: region
  }
}

module aoai './modules/openai.bicep' = {
  name: 'aoai'
  params:{
    prefix: prefix
    aoaiRegion: aoaiRegion
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module apim './modules/apim-svc.bicep' = {
  name: 'apim'
  params:{
    prefix: prefix
    region: region
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module aoai_api './modules/apim-openai-apidef.bicep' = {
  name: 'aoai_api'
  params:{
    apimName: apim.outputs.apiManagementName
    aiLoggerName: apim.outputs.appinsightsLoggerName
    aoaiName: aoai.outputs.aoaiAccountName
  }
}

