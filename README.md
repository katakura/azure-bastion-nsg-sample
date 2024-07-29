# azure-bastion-nsg-sample

このrepositoryは以下のURLに記載のあるAzure Bastionへの接続にNetwork Security Group(NSG)を適用して動作の検証を行うための Bicep コードを公開しています。

This repository publishes Bicep code designed to apply Network Security Group (NSG) rules to Azure Bastion for the purpose of testing connectivity. The code is related to connecting to Azure Bastion as described in the following URL

[https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg](https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg)

使い方は以下の通りです。

This is how it is used.

```sh
r="rg-bastion-test"
az group create -n $r -l japaneast
az deployment group create -g $r --template-file main.bicep --parameters main.bicepparam
```

必要に応じて main.bicepparam 内の allowedIps パラメータを修正し、接続元IPアドレスを記述します（複数記述可能）

Bastion で接続する仮想マシンは、このテンプレートでは作成しません。

snet-vms サブネット内に任意の仮想マシンを追加でデプロイしてください。（Public IPは不要です）

Modify the allowedIps parameter within main.bicepparam as needed and specify the source IP addresses for connectivity (multiple entries are possible).

This template does not create the virtual machines that connect via Bastion.

Please deploy any desired virtual machines within the snet-vms subnet (public IP is not required).
