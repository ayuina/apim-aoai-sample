param apimName string
param aiLoggerName string
param aoaiName string

var aoaiSpec = loadTextContent('./apim-openai-interface.json')
var policySpec = loadTextContent('./apim-openai-policy.xml')
var aoaikeyNamedValueRef = 'AzureOpenAIKey'

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apimName

  resource aiLogger 'loggers' existing = {
    name: aiLoggerName
  }
}

resource aoai 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aoaiName
}

resource nv 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = {
  parent: apim
  name: 'NV-AzureOpenAIKey'
  properties: {
    displayName: aoaikeyNamedValueRef
    value: aoai.listKeys().key1
    secret: true
  }
}

resource openaiApis 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: apim
  name: 'OpenAI-${json(aoaiSpec).info.version}'
  properties: {
    path: 'openai'
    subscriptionRequired: true
    protocols: [
      'https'
    ]
    type: 'http'
    format: 'openapi'
    serviceUrl: '${aoai.properties.endpoint}openai'
    subscriptionKeyParameterNames: {
      header: 'api-key'
    }
    value: aoaiSpec
  }

  resource policy 'policies' = {
    name: 'policy'
    properties: {
      format: 'rawxml'
      value: policySpec
    }
  }

  resource diag 'diagnostics' = {
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
  }}
