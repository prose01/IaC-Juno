targetScope='subscription'

@description('Name of the App Service.')
@minLength(5)
@maxLength(30)
param projectName string

@description('The name of the environment. This must be DEV, TEST, or PROD.')
@allowed([
  'DEV'
  'TEST'
  'PROD'
])
param environmentType string

@description('App Service Plan Sku. Default is P1v2 or P2v2 for Production.')
param appServicePlanSkuName string = (environmentType == 'PROD') ? 'P2v2' : 'P1v2'

@description('Additional app settings for App Service.')
param additionalAppSettings object = {}

@description('Location. Default is northeurope.')
param location string = 'northeurope'

@description('App Service Plan Instances. Default is 1.')
@minValue(1)
@maxValue(10)
param appServicePlanInstanceCount int = 1

var tags = {
  '${projectName}': environmentType
}

// Start by creating a new Resource Goup
resource newRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'RG-${projectName}-${environmentType}'
  location: location
  tags: tags
}

// module deployed new appService Plan
module appServicePlan 'br/modules:appserviceplan:2022-08-16' = {
  name: 'appServicePlan'
  scope: newRG
  params: {
    projectName: projectName
    environmentType: environmentType
    appServicePlanSkuName: appServicePlanSkuName
    appServicePlanInstanceCount: appServicePlanInstanceCount
    location: location
    tags: tags
  }
}

// module deployed new appService
module appService 'br/modules:appservice:2023-05-12' = {
  name: 'appService'
  scope: newRG
  params: {    
    projectName: '${projectName}API'
    environmentType: environmentType
    appServicePlanID: appServicePlan.outputs.appServicePlanID
    // virtualNetworkSubnetId: virtualNetworks.outputs.subnetId1
    additionalAppSettings: additionalAppSettings
    location: location
    tags: tags
  }
}
