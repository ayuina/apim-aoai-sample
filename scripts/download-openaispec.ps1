
$targets = @(
    '2022-12-01', 
    '2023-05-15', 
    '2022-03-01-preview', 
    '2022-06-01-preview', 
    '2023-03-15-preview', 
    '2023-06-01-preview', 
    '2023-07-01-preview', 
    '2023-08-01-preview')

$outputRoot = "$PSScriptRoot/../infra/openaispec"
if(!(Test-Path $outputRoot)) {
    mkdir $outputRoot
}

$targets | foreach {
    $version = $_
    $status = $version.EndsWith('-preview') ? 'preview' : 'stable'
    $url = "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/${status}/${version}/inference.json"
    $output = "${outputRoot}/${version}.json"

    Write-Host "Downloading ${version} specification"
    $res = Invoke-WebRequest -Uri $url 
    $temp = ConvertFrom-Json $res.Content
 
    Write-Verbose "overwrite endpoint to import api management. this value doesn't exists, but will be overwritten when bicep deployment"
    $defaultEndpoint = $temp.servers.variables.endpoint.default
    $tempAoaiUrl = "https://${defaultEndpoint}/openai"
    $temp.servers | Add-Member -NotePropertyName "url" -NotePropertyValue $tempAoaiUrl -Force

    Write-Verbose "saving to ${output}"
    $temp | ConvertTo-Json -Depth 100 | Out-File -FilePath $output -Force
}