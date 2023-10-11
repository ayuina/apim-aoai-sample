
param region string = resourceGroup().location
param aoaiRegions array = ['eastus', 'westeurope', 'uksouth']
//param aoaiRegions array = ['japaneast', 'eastus2', 'switzerlandnorth', 'australiaeast']
param targetVersions array = ['2023-05-15', '2023-07-01-preview', '2023-08-01-preview', '2023-09-01-preview']
param enableManagedIdAuth bool = true
param aoaiModelCapacity int = 40

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
  loadTextContent('./openaispec/2023-09-01-preview.json')
]
var targetSpecs = filter(aoaiSpecDocs, spec => contains(targetVersions, json(spec).info.version))

module monitor './modules/monitor.bicep' = {
  name: 'monitor'
  params:{
    postfix: postfix
    region: region
  }
}

module aoais './modules/openai.bicep' = [for aoaiRegion in aoaiRegions: {
  name: 'aoai-${aoaiRegion}'
  params:{
    postfix: '${aoaiRegion}-${postfix}'
    aoaiRegion: aoaiRegion
    logAnalyticsName: monitor.outputs.LogAnalyticsName
    enableManagedIdAuth: enableManagedIdAuth
    aoaiModelCapacity: aoaiModelCapacity
  }
}]

module apim './modules/apim-svc.bicep' = {
  name: 'apim'
  params:{
    postfix: postfix
    region: region
    enableManagedIdAuth: enableManagedIdAuth
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module auth './modules/openai-auth-apim.bicep' = [for (aoaiRegion, idx) in aoaiRegions: if(enableManagedIdAuth) {
  name: 'auth-${aoaiRegion}'
  params:{
    apimName: apim.outputs.apiManagementName
    aoaiName: aoais[idx].outputs.aoaiAccountName
  }
}]

module aoai_api './modules/apim-openai-apidef.bicep' = {
  name: 'aoai_api'
  params:{
    apimName: apim.outputs.apiManagementName
    enableManagedIdAuth: enableManagedIdAuth
    targetVersionSpecs: targetSpecs
    aiLoggerName: apim.outputs.appinsightsLoggerName
    aoaiNames: [for (aoaiRegion, idx) in aoaiRegions: aoais[idx].outputs.aoaiAccountName]
  }
}

