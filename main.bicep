// must parameter
param allowedIps array = []

// optional parameters
param vnetName string = 'vnet-bastion'
param addressPrefix string = '192.168.100.0/24'
param bastionSubnetPrefix string = '192.168.100.0/26'
param vmSubnetPrefix string = '192.168.100.128/26'
param vmSubnetName string = 'snet-vms'

param nsgBastionName string = 'nsg-bastion'
param bastionName string = 'bas-test'
param bastionPipName string = 'pip-bastion'
param natGwName string = 'nat-test'
param natGwPipName string = 'pip-nat'
param nsgVmsName string = 'nsg-vms'

// variables
var bastionSubnetName = 'AzureBastionSubnet'

// existing resources
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  parent: virtualNetwork
  name: bastionSubnetName
}

// virtual network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefixes: [
            bastionSubnetPrefix
          ]
          networkSecurityGroup: {
            id: bastionNsg.id
          }
        }
      }
      {
        name: vmSubnetName
        properties: {
          addressPrefixes: [
            vmSubnetPrefix
          ]
          networkSecurityGroup: {
            id: vmsNsg.id
          }
          natGateway: {
            id: natGw.id
          }
        }
      }
    ]
  }
}

// network security group
resource vmsNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: nsgVmsName
  location: resourceGroup().location
  properties: {
    securityRules: []
  }
}

resource bastionNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: nsgBastionName
  location: resourceGroup().location
  properties: {
    securityRules: [
      // Inbound rules
      {
        name: 'AllowHttpsInbound'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          priority: 120
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          sourcePortRanges: []
          sourceAddressPrefixes: allowedIps
          destinationAddressPrefixes: []
          sourceApplicationSecurityGroups: []
          destinationApplicationSecurityGroups: []
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          priority: 130
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowzureLoadBalancerInbound'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          priority: 140
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInbound'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          priority: 150
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          direction: 'Inbound'
          access: 'Deny'
          priority: 4000
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      // Outbound rules
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          direction: 'Outbound'
          access: 'Allow'
          priority: 100
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          direction: 'Outbound'
          access: 'Allow'
          priority: 110
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionCommunicationOutbound'
        properties: {
          direction: 'Outbound'
          access: 'Allow'
          priority: 120
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'AllowHttpOutbound'
        properties: {
          direction: 'Outbound'
          access: 'Allow'
          priority: 130
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '80'
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          direction: 'Outbound'
          access: 'Deny'
          priority: 4000
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// bastion
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: bastionPipName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: bastionName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    disableCopyPaste: false
    enableFileCopy: true
    enableIpConnect: false
    enableKerberos: false
    enableShareableLink: true
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
    scaleUnits: 2
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

// nat gateway
resource natGwPublicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: natGwPipName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource natGw 'Microsoft.Network/natGateways@2024-01-01' = {
  name: natGwName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natGwPublicIp.id
      }
    ]
    idleTimeoutInMinutes: 4
  }
}
