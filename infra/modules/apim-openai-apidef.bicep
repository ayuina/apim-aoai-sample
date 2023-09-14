param apimName string
param targetVersionSpecs array
param aiLoggerName string
param aoaiNames array
param enableManagedIdAuth bool

var authModeNVRef = 'AOAIAuthMode'
// var aoaikeyNamedValueRef = 'AzureOpenAIKey'
// var aoaiEndpointNamedValueRef = 'AzureOpenAIEndpoint'
var allapipolicy = loadTextContent('./apim-openai-policy.xml')

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apimName

  resource aiLogger 'loggers' existing = {
    name: aiLoggerName
  }
}

resource aoaiCluster 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = [for aoaiName in aoaiNames: {
  name: aoaiName
}]

// for each openai service

// resource nvApikeys 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = [for (aoaiName, idx) in aoaiNames: {
//   parent: apim
//   name: 'NV-${aoaiName}-Key'
//   properties: {
//     displayName: '${aoaikeyNamedValueRef}-${idx}'
//     value: enableManagedIdAuth ? '    ' :  aoaiCluster[idx].listKeys().key1
//     secret: true
//   }
// }]

// resource nvBackends 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = [for (aoaiName, idx) in aoaiNames: {
//   parent: apim
//   name: 'NV-${aoaiName}-Endpoint'
//   properties: {
//     displayName: '${aoaiEndpointNamedValueRef}-${idx}'
//     value: '${aoaiCluster[idx].properties.endpoint}openai' 
//     secret: false
//   }
// }]

resource authModeNV 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = {
  parent: apim
  name: authModeNVRef
  properties: {
    displayName: authModeNVRef
    value: enableManagedIdAuth ? 'ManagedIdentity' : 'ApiKey'
  }
}

resource backendOpenAIs 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = [for (aoaiName, idx) in aoaiNames: {
  parent: apim
  name: 'OpenAI-${idx}'
  properties: {
    title: 'OpenAI-${idx}'
    description: 'OpenAI-${idx}'
    protocol: 'http'
    url: '${aoaiCluster[idx].properties.endpoint}openai'
    credentials: {
      header: enableManagedIdAuth ? null : {
        'api-key': aoaiCluster[idx].listKeys().key1
      }
    }
  }
}]

// for single api definition 

resource aoaiVS 'Microsoft.ApiManagement/service/apiVersionSets@2023-03-01-preview' = {
  parent: apim
  name: 'OpenAI'
  properties: {
    displayName: 'Azure OpenAI'
    versioningScheme: 'Query'
    versionQueryName: 'api-version'
  }
}

resource aoaiApis 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = [for (spec, idx) in targetVersionSpecs: {
  parent: apim
  name: 'OpenAI-${json(spec).info.version}'
  properties: {
    path: 'openai'
    subscriptionRequired: true
    protocols: [
      'https'
    ]
    type: 'http'
    format: 'openapi'
    serviceUrl: 'https://dummyEndpoint.sample.com/openai'
    subscriptionKeyParameterNames: {
      header: 'api-key'
    }
    value: spec
    apiVersionSetId: aoaiVS.id
    apiVersion: json(spec).info.version
  }
}]

resource allOperationPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = [for (spec, idx) in targetVersionSpecs: {
  parent: aoaiApis[idx]
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: allapipolicy
  }
}]

resource appinsDiag 'Microsoft.ApiManagement/service/apis/diagnostics@2023-03-01-preview' = [for (spec, idx) in targetVersionSpecs: {
  parent: aoaiApis[idx]
  name: 'applicationinsights'
  properties: {
    loggerId: apim::aiLogger.id
    alwaysLog: 'allErrors'
    logClientIp: true
    verbosity: 'verbose'
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
    frontend: {
      request: {
        body: { bytes: 8192 }
        headers:['Referer', 'X-Forwarded-For', 'api-key', 'Authorization']
      }
      response: {
        body: { bytes: 8192 }
        headers:['x-ms-region', 'openai-model', 'openai-processing-ms']
      }
    }
    backend: {
      request: {
        body: { bytes: 8192 }
        headers:['Referer', 'X-Forwarded-For', 'api-key', 'Authorization']
      }
      response: {
        body: { bytes: 8192 }
        headers:['x-ms-region', 'openai-model', 'openai-processing-ms']
      }
    }
  }
}]
