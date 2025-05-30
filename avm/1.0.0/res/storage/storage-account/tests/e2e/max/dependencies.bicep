@description('Optional. The location to deploy resources to.')
param location string = resourceGroup().location

@description('Required. The name of the Virtual Network to create.')
param virtualNetworkName string

@description('Required. The name of the Managed Identity to create.')
param managedIdentityName string

var addressPrefix = '10.0.0.0/16'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'defaultSubnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 20, 0)
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'custom-private-subnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 20, 1)
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'custom-private-subnet-2'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 20, 2)
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  dependsOn: [
    virtualNetwork
  ]

  resource virtualNetworkLinks 'virtualNetworkLinks@2024-06-01' = {
    name: '${virtualNetwork.name}-vnetlink'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: virtualNetwork.id
      }
      registrationEnabled: false
    }
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

@description('The resource ID of the created Virtual Network Default Subnet.')
output defaultSubnetResourceId string = virtualNetwork.properties.subnets[0].id

@description('The resource ID of the 2nd created Virtual Network Subnet.')
output customSubnet1ResourceId string = virtualNetwork.properties.subnets[1].id

@description('The resource ID of the 3rd created Virtual Network Subnet.')
output customSubnet2ResourceId string = virtualNetwork.properties.subnets[2].id

@description('The principal ID of the created Managed Identity.')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('The resource ID of the created Managed Identity.')
output managedIdentityResourceId string = managedIdentity.id

@description('The resource ID of the created Private DNS Zone.')
output privateDNSZoneResourceId string = privateDNSZone.id
