param apimName string
param aoaiName string

var aoaiSpec = loadTextContent('./apim-openai-interface.json')
var policySpec = loadTextContent('./apim-openai-policy.xml')
var aoaikeyNamedValueRef = 'AzureOpenAIKey'

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apimName
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
      header: 'Ocp-Apim-Subscription-Key'
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
}
