# Main
$errorActionPreference = 'Stop'

# Add specific step for azure
# Download Azure Transform tool
Add-type -AssemblyName "System.IO.Compression.FileSystem"
$azureTransformContainerUrl = "https://opbuildstoragesandbox2.blob.core.windows.net/azure-transform"

$AzureMarkdownRewriterToolSource = "$azureTransformContainerUrl/.optemp/AzureMarkdownRewriterTool-v5.zip"
$AzureMarkdownRewriterToolDestination = "$repositoryRoot\.optemp\AzureMarkdownRewriterTool.zip"
DownloadFile($AzureMarkdownRewriterToolSource) ($AzureMarkdownRewriterToolDestination) ($true)
$AzureMarkdownRewriterToolUnzipFolder = "$repositoryRoot\.optemp\AzureMarkdownRewriterTool"
if((Test-Path "$AzureMarkdownRewriterToolUnzipFolder"))
{
    Remove-Item $AzureMarkdownRewriterToolUnzipFolder -Force -Recurse
}
[System.IO.Compression.ZipFile]::ExtractToDirectory($AzureMarkdownRewriterToolDestination, $AzureMarkdownRewriterToolUnzipFolder)
$AzureMarkdownRewriterTool = "$AzureMarkdownRewriterToolUnzipFolder\Microsoft.DocAsCode.Tools.AzureMarkdownRewriterTool.exe"

# Create azure args file
$docsHostUriPrefix = "https://stage.docs.microsoft.com/en-us"
$azureDocumentUriPrefix = "https://azure.microsoft.com/en-us/documentation/articles"

$transformCommonDirectory = "$repositoryRoot\articles"
$transformDirectoriesToCommonDirectory = @("active-directory", "multi-factor-authentication", "remoteapp")

$azureTransformArgsJsonContent = "["
foreach($transformDirectoriyToCommonDirectory in $transformDirectoriesToCommonDirectory)
{
    if($azureTransformArgsJsonContent -ne "[")
    {
        $azureTransformArgsJsonContent += ','
    }
    $azureTransformArgsJsonContent += "{`"source_dir`": `"$transformCommonDirectory\$transformDirectoriyToCommonDirectory`""
    $azureTransformArgsJsonContent += ", `"dest_dir`": `"$transformCommonDirectory\$transformDirectoriyToCommonDirectory`""
    $azureTransformArgsJsonContent += ", `"docs_host_uri_prefix`": `"$docsHostUriPrefix/$transformDirectoriyToCommonDirectory`"}"
}
$azureTransformArgsJsonContent += "]"
$auzreTransformArgsJsonPath = $AzureMarkdownRewriterToolUnzipFolder + "\" + (Get-Date -Format "yyyyMMddhhmmss") + [System.IO.Path]::GetRandomFileName() + "-" + ".json"
$azureTransformArgsJsonContent = $azureTransformArgsJsonContent.Replace("\", "\\")
Out-File -FilePath $auzreTransformArgsJsonPath -InputObject $azureTransformArgsJsonContent -Force

# Call azure transform for every docset
echo "Start to call azure transform"
&$AzureMarkdownRewriterTool "$repositoryRoot" "$auzreTransformArgsJsonPath" "$azureDocumentUriPrefix"

# add build for docs
$buildEntryPointDestination = Join-Path $packageToolsDirectory -ChildPath "opbuild" | Join-Path -ChildPath "mdproj.builder.ps1"
& "$buildEntryPointDestination" "$repositoryRoot" "$packagesDirectory" "$packageToolsDirectory" $dependencies

exit $LASTEXITCODE
