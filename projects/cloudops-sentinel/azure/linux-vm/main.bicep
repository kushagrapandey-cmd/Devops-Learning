targetScope = 'resourceGroup'
param location string = resourceGroup().location
param adminUsername string = 'labadmin'
@secure()
param sshPublicKey string
@description('Your public IPv4 /32. Deploy helper validates it.')
param operatorCidr string
param vmSize string = 'Standard_B2s'
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'sentinel-linux-nsg'
  location: location
  properties: {
    securityRules: [{
      name: 'OperatorSSH'
      properties: {
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '22'
        sourceAddressPrefix: operatorCidr
        destinationAddressPrefix: '*'
      }
    }]
  }
}
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'sentinel-linux-vnet'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.42.0.0/16'] }
    subnets: [{ name: 'app', properties: { addressPrefix: '10.42.1.0/24' } }]
  }
}
resource pip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'sentinel-linux-ip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}
resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: 'sentinel-linux-nic'
  location: location
  properties: {
    networkSecurityGroup: { id: nsg.id }
    ipConfigurations: [{
      name: 'primary'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: { id: '${vnet.id}/subnets/app' }
        publicIPAddress: { id: pip.id }
      }
    }]
  }
}
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'sentinel-linux'
  location: location
  tags: { project: 'cloudops-sentinel', purpose: 'linux-lab' }
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: 'sentinel-linux'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: { publicKeys: [{ path: '/home/${adminUsername}/.ssh/authorized_keys', keyData: sshPublicKey }] }
      }
    }
    storageProfile: {
      imageReference: { publisher: 'Canonical', offer: 'ubuntu-24_04-lts', sku: 'server', version: 'latest' }
      osDisk: { createOption: 'FromImage', managedDisk: { storageAccountType: 'Standard_LRS' }, deleteOption: 'Delete' }
    }
    networkProfile: { networkInterfaces: [{ id: nic.id }] }
  }
}
output publicIp string = pip.properties.ipAddress
output vmName string = vm.name
