param aoaiName string
param apimName string

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apimName
}

resource aoai 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aoaiName
}

resource openaiContributor 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: 'a001fd3d-188f-4b5d-821b-7da978bf7442'
}

resource openaiContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' =  {
  scope: aoai
  name: guid(subscription().subscriptionId, resourceGroup().name, apim.id, openaiContributor.id)
  properties: {
    roleDefinitionId: openaiContributor.id
    principalId: apim.identity.principalId
  }
}
