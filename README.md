# Running the Example

## Prerequisites

* .NET Framework 4.8 SDK
* Visual Studio 2019

### Sollution description
TestWebApp project is a project that will be build during CLI upload to XM Cloud env. Artifatcs that will be produced during publishing of this project will be pushed to the XM Cloud instance.

To check what will be included into deployment artifacts:
 1. Go to root folder
 2. Run build.ps1
 3. Generated artifacts can be found here \artifacts\deploy

To include files into deploy artifact, those should be referenced as content in TestWebApp.csproj file, e.g.:
  <ItemGroup>
    <Content Include="App_Config\**" />
    <Content Include="App_Data\**" />
    <Content Include="bin\**" />
  </ItemGroup>
