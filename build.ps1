# Buildung solution is the same as for XmCloud Build, copied here to check package content in the branch
# https://dev.azure.com/Sitecore-PD/Products/_git/XmCloud.Builds.Pipelines?version=GBmaster&path=/XMCloudDockerBuild/Docker/build-solution/scripts/BuildSolution.ps1

function RemoveExistingPlugins {
  $sitecoreJson = Get-Content ./sitecore.json | ConvertFrom-Json
  $sitecoreJson = $sitecoreJson | Select-Object * -ExcludeProperty plugins
  $sitecoreJson | ConvertTo-Json -Depth 32 | Out-File ./sitecore.json -Force
}

function  InitializeSitecoreJson {
  # Make sure Sitecore cli is installed in build folder
  $cliNugetRepo = "http://nuget1dk1/nuget/10.3.0_master"

  try {
    dotnet nuget list source | ForEach-Object {if ($_ -match $cliNugetRepo) { $NuGetSourceExists = $true}}

    if (-not $NuGetSourceExists) {
        dotnet nuget add source -n __SitecoreCLI $cliNugetRepo
    }

    dotnet tool update sitecore.cli
    dotnet sitecore init

    dotnet nuget list source
    RemoveExistingPlugins

    dotnet sitecore plugin add -n Sitecore.DevEx.Extensibility.ResourcePackage
  }
  catch {
    Write-Host "Build terminated due to failure restoreing tools"
    throw
  }
  finally {
    if (-not $NuGetSourceExists) {
      dotnet nuget remove source __SitecoreCLI
    }
  }
}

$configuration="Release"
$buildRoot = "$PSScriptRoot\artifacts"
if (Test-Path $buildRoot) {
  Remove-Item -Path $buildRoot -Recurse -Force
}

Write-Host "Building solution, publish artifacts folder is - '$buildRoot\deploy'"

$msBuildPath = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe
if (-not (Test-Path $msBuildPath)) {
  throw "Can not find MSBuild"
}

Write-output "Building solution..."
$solutionFilePath = ".\XMCloudTestBuild.sln"
&$msBuildPath -m -v:n $solutionFilePath /p:Configuration=$configuration /p:ResolveNugetPackages=false /p:DeployOnBuild=True /p:DeployDefaultTarget=WebPublish /p:WebPublishMethod=FileSystem /p:PublishUrl="$buildRoot\deploy"

if ($LASTEXITCODE -ne 0) {
  throw "Build terminated due to failure"
}

# build the item as resources file
InitializeSitecoreJson

$xmcBuildFile = Get-ChildItem -Path $PSScriptRoot -Recurse -Filter xmcloud.build.json

Write-Output "Creating items as resources"
dotnet sitecore itemres create -o "$buildRoot\items\slnitems"

if ($LASTEXITCODE -ne 0) {
  throw "Build terminated due to failure"
}

if (Test-Path "$buildRoot\items\items.core.*.*") {
  New-Item -ItemType Directory "$buildRoot\deploy\App_Data\Items\Core" -Force | Out-Null
  Copy-Item -Path "$buildRoot\items\items.core.*.*" "$buildRoot\deploy\app_data\items\core" -Force
}

if (Test-Path "$buildRoot\items\items.master.*.*") {
  New-Item -ItemType Directory "$buildRoot\deploy\App_Data\Items\Master" -Force | Out-Null
  Copy-Item -Path "$buildRoot\items\items.master.*.*" "$buildRoot\deploy\app_data\items\master"  -Force
}
