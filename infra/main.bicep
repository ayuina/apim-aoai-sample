
param region string = resourceGroup().location
param aoaiRegion string = resourceGroup().location
param targetVersions array = ['2023-07-01-preview']

var postfix = toLower(uniqueString(subscription().id, region, resourceGroup().name))
var aoaiSpecDocs = [
  loadTextContent('./openaispec/2022-03-01-preview.json')
  loadTextContent('./openaispec/2022-06-01-preview.json')
  loadTextContent('./openaispec/2022-12-01.json')
  loadTextContent('./openaispec/2023-03-15-preview.json')
  loadTextContent('./openaispec/2023-05-15.json')
  loadTextContent('./openaispec/2023-06-01-preview.json')
  loadTextContent('./openaispec/2023-07-01-preview.json')
  loadTextContent('./openaispec/2023-08-01-preview.json')
]
var targetSpecs = filter(aoaiSpecDocs, spec => contains(targetVersions, json(spec).info.version))

module monitor './modules/monitor.bicep' = {
  name: 'monitor'
  params:{
    postfix: postfix
    region: region
  }
}

module aoai './modules/openai.bicep' = {
  name: 'aoai'
  params:{
    postfix: postfix
    aoaiRegion: aoaiRegion
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module apim './modules/apim-svc.bicep' = {
  name: 'apim'
  params:{
    postfix: postfix
    region: region
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module aoai_api './modules/apim-openai-apidef.bicep' = {
  name: 'aoai_api'
  params:{
    apimName: apim.outputs.apiManagementName
    targetVersionSpecs: targetSpecs
    aiLoggerName: apim.outputs.appinsightsLoggerName
    aoaiName: aoai.outputs.aoaiAccountName
  }
}

output API_MANAGEMENT_ENDPOINT string = 'https://${apim.outputs.apiManagementName}.azure-api.net'
output AZURE_OPENAI_ENDPOINT string = 'https://${aoai.outputs.aoaiAccountName}.openai.azure.com'
output AZURE_OPENAI_GPT_MODEL_DEPLOYMENT object = aoai.outputs.gptModelDeployment
