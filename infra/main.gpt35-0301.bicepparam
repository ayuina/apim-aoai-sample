using './main.bicep'

param region = 'eastus'
param targetVersions = [
  '2023-05-15' 
  '2023-07-01-preview'
  '2023-08-01-preview'
  '2023-09-01-preview'
]
param enableManagedIdAuth = true
param apimSku = 'StandardV2'
param aoaiCluster = {
  modelName: 'gpt-35-turbo'
  modelVersion: '0301'
  modelCapacity: 40
  modelDeploymentName: 'g35t'
  regions: ['eastus', 'westeurope', 'uksouth', 'southcentralus']
  enableApikeyAuth: true
}
