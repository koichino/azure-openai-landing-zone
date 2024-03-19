@description('Location for all resources.')
@allowed([
  'australiaeast'
  'canadaeast'
  'eastus'
  'eastus2'
  'francecentral'
  'japaneast'
  'northcentralus'
  'southcentralus'
  'swedencentral'
  'switzerlandnorth'
  'uksouth'
  'westeurope'
  'westus'
])
param locations string[] = ['canadaeast','northcentralus','southcentralus']
param model string = 'gpt-35-turbo'
param modelVersion string = '0125'

@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
//param aoaiServiceName string 
//param aoaiServiceName array
param aoaiServiceName string = 'koichino-aoaibicep'

//param deployments array = []

var sku = 'S0'
var capacity = 1
param scaleType string = 'Standard' //  'Standard' or 'Manual'

@batchSize(1)
resource cognitiveService 'Microsoft.CognitiveServices/accounts@2023-05-01' = [for location in locations: {
  name: '${aoaiServiceName}-${location}'
  location: location
  sku: {
    name: sku
  }
  kind: 'OpenAI'
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}
]

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' =  [for (location,i) in locations: {
  name: model
  parent: cognitiveService[i]
  sku: {
    name: scaleType
    capacity: capacity
  }
  properties: {
    model: {      
      format: 'OpenAI'
      name: model
      version: modelVersion
    }
  }
  }
]
