using './main.bicep'

param region = 'japaneast'
param targetVersions = [
  '2023-05-15' 
  '2023-07-01-preview'
  '2023-08-01-preview'
  '2023-09-01-preview'
]
param enableManagedIdAuth = true
param apimSku = 'Consumption'
param aoaiCluster = {
  modelName: 'gpt-35-turbo'
  modelVersion: '0613'
  modelCapacity: 40
  modelDeploymentName: 'g35t'
  regions: [
    'australiaeast'
    'canadaeast'
    'eastus2'
    'francecentral'
    'japaneast'
    'northcentralus'
    'switzerlandnorth'
  ]
  enableApikeyAuth: true
}
