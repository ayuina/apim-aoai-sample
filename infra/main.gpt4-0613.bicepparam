using './main.bicep'

param region = 'japaneast'
param targetVersions = [
  '2023-08-01-preview'
  '2023-09-01-preview'
]
param enableManagedIdAuth = true
param apimSku = 'Consumption'
param aoaiCluster = {
  modelName: 'gpt-4'
  modelVersion: '0613'
  modelCapacity: 10
  modelDeploymentName: 'g4'
  regions: [
    //'australiaeast'
    'canadaeast'
    //'eastus'
    //'eastus2'
    //'francecentral'
    //'japaneast'
    'swedencentral'
    'switzerlandnorth'
    //'uksouth'
  ]
  enableApikeyAuth: true
}
