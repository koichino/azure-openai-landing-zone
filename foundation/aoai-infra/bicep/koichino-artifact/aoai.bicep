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
param locations string[] = ['canadaeast','northcentralus','southcentralus'] // Only 3 regions supports gpt-3.5-turbo (0125) as of Mar 2024
param model string = 'gpt-35-turbo'
param modelVersion string = '0125'

@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param aoaiServiceName string = 'aaoaiai-bicep'

var sku = 'S0'
var capacity = 1 // REPLACE WITH YOUR DESIRED CAPACITY (should be 500)
param scaleType string = 'Standard' //  'Standard' or 'Manual'

resource cognitiveService 'Microsoft.CognitiveServices/accounts@2023-05-01' = [for location in locations: {
  name: '${aoaiServiceName}-${location}'
  location: location
  sku: {
    name: sku
  }
  kind: 'OpenAI'
  properties: {
    publicNetworkAccess: 'Disabled'
    customSubDomainName: '${aoaiServiceName}-${location}'
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

// Private endpoint for Azure OpenAI Resource

@description('Private endpoint for a Azure OpenAI Resource.')
param privateEndpointName string = 'aoai-pe'

@description('Private DNS Zone resource group name.')
param privateDNSZoneRgName string = 'bicep-rg'

@description('Vnet location.')
param vnetLocation string = 'japaneast'

@description('Vnet name.')
param vnetName string = 'vnet-aoai-bicep'

@description('Subnet name where the private endpoint should be provisioned.')
param subnetName string = 'aoai-pe-subnet'

var privateDnsZoneName = 'privatelink.openai.azure.com'

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
    name: vnetName
    location: vnetLocation
    properties: {
      addressSpace: {
        addressPrefixes: [
          '10.0.0.0/16'
        ]
      }
      subnets: [
        {
          name: subnetName
          properties: {
            addressPrefix: '10.0.1.0/24'
          }
        }
      ]
    }
  }



resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: vnet
  name: subnetName  
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = [for (location,i) in locations:{
  name: '${privateEndpointName}-${location}'
  location: vnetLocation
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-${location}'
        properties: {
          privateLinkServiceId: cognitiveService[i].id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  } 
}
]

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'vnetlink'
  location: 'global'
  parent: privateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}


resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = [for (location,i) in locations:{
  parent: privateEndpoint[i]
  name: 'dnsgroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${aoaiServiceName}-${location}-config'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  } 
}
]
