
param region string = resourceGroup().location
param targetVersions array
param enableManagedIdAuth bool
param apimSku string
param apimPublisherEmail string
param apimPublisherName string
param aoaiCluster object


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

module aoais './modules/openai.bicep' = [for aoaiRegion in aoaiCluster.regions: {
  name: 'aoai-${aoaiRegion}'
  params:{
    postfix: '${aoaiRegion}-${postfix}'
    aoaiRegion: aoaiRegion
    logAnalyticsName: monitor.outputs.LogAnalyticsName
    enableApikeyAuth: aoaiCluster.enableApikeyAuth
    modelName: aoaiCluster.modelName
    modelVersion: aoaiCluster.modelVersion
    modelCapacity: aoaiCluster.modelCapacity    
    modelDeploymentName: aoaiCluster.modelDeploymentName
  }
}]

module apim './modules/apim-svc.bicep' = {
  name: 'apim'
  params:{
    postfix: postfix
    region: region
    enableManagedIdAuth: enableManagedIdAuth
    logAnalyticsName: monitor.outputs.LogAnalyticsName
    apimSku: apimSku
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
  }
}

module auth './modules/openai-auth-apim.bicep' = [for (aoaiRegion, idx) in aoaiCluster.regions : if(enableManagedIdAuth) {
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
    aoaiNames: [for (aoaiRegion, idx) in aoaiCluster.regions: aoais[idx].outputs.aoaiAccountName]
  }
}

output APIM_NAME string = apim.outputs.apiManagementName

