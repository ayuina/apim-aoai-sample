# Call OpenAI Service via API Management

Azure OpenAI を API Management で保護する構成を、IaC で一括デプロイするためのサンプルです。

## はじめに

[こちらのリファレンスアーキテクチャ](https://learn.microsoft.com/ja-jp/azure/architecture/ai-ml/openai/architecture/log-monitor-azure-openai)に記述されている通り、
以下の理由から API Management を介して Azure OpenAI Service を利用することがあります。

- Azure OpenAI Service 単体では出力できるログに制限がある
- OpenAI サービス用の API キーをすべてのクライアントアプリケーションで共有する

構成する方法は[こちら](https://learn.microsoft.com/en-us/semantic-kernel/deploy/use-ai-apis-with-api-management)に記載があるのですが、何度も手作業で構築するのが面倒なので自動化に挑戦してみました。

## 概要

![overview](./images/overview.png)

- Azure OpenAI Service
- Azure API Management
    - Azure OpenAI Service をバックエンドとする API 定義
- Azure Application Insights
    - API Management 上で実行される各種 API のログ出力先
- Azure Log Analytics
    - Azure OpenAI および API Management のリソースログ（診断ログ）の出力先
    - Application Insights のワークスペースとしても利用

## Open AI の仕様書をダウンロードする

API Management にインポートするための OpenAPI 仕様をダウンロードするスクリプトは以下のようになります。
本リポジトリにも[ダウンロード済みのもの](./infra/modules/apim-openai-interface.json)が含めてありますので、API 仕様のバージョンを確認して変更不要であればこの手順は飛ばしても構いません。

バージョンを変更したい場合は下記のスクリプトを適宜修正して実行してください。
利用可能な API のバージョンについては [リファレンス](https://learn.microsoft.com/ja-jp/azure/ai-services/openai/reference)を参照してください。

```powershell
$version = '2023-07-01-preview'
$status = $version.EndsWith('-preview') ? 'preview' : 'stable'
$output = './infra/modules/openai-interface.json'

Write-Host "Download OpenAI specification version: $version"
$specUrl = "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/${status}/${version}/inference.json"
$temp = (Invoke-WebRequest -Uri $specUrl).Content | ConvertFrom-Json

Write-Verbose "overwrite endpoint to import api management. this value doesn't exists, but will be overwritten when bicep deployment"
$defaultEndpoint = $temp.servers.variables.endpoint.default
$tempAoaiUrl = "https://${defaultEndpoint}/openai"
$temp.servers | Add-Member -NotePropertyName "url" -NotePropertyValue $tempAoaiUrl -Force
$temp | ConvertTo-Json -Depth 100 | Out-File -FilePath $output -Force
```

## テンプレートのデプロイ

各種 Azure リソース、および先ほどダウンロードしておいた OpenAI 互換の API を API Management にインポートします。

```powershell
az login

$subscription = '<your subscription id>'
az account set -s $subscription

$region = 'japaneast'
$prefix = 'demo0904'
$rg = "${prefix}-rg"

az group create -n $rg -l $region
az deployment group create -f ./infra/main.bicep -g $rg -p prefix=$prefix region=$region aoaiRegion=$region
```


## 参考情報

- [Implement logging and monitoring for Azure OpenAI models](https://learn.microsoft.com/ja-jp/azure/architecture/ai-ml/openai/architecture/log-monitor-azure-openai)
- [Protect your Azure OpenAI API keys with Azure API Management](https://learn.microsoft.com/en-us/semantic-kernel/deploy/use-ai-apis-with-api-management)
- [Azure OpenAI Service REST API reference](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference)
- [Sample APIs for Azure API Management](https://github.com/Azure-Samples/api-management-sample-apis)
- [BICEP-Automate deployment of API Management and its components](https://vinniejames.medium.com/bicep-automate-deployment-of-api-management-and-its-components-26e4b8aee28)
