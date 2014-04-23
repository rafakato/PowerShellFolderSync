<#
.SYNOPSIS
Create a configuration transformation
 
.DESCRIPTION
This script runs an ASP.NET configuration transformation, given a source
configuration and transformation file.  MSBuild.exe is assumed to be in
the path, and Visual Studio 2012 should be installed.  Modify the path to
Microsoft.Web.Publishing.Tasks.dll if a different version of Visual Studio
is installed.
 
.PARAMETER SourceFile
The source file to use for transformations
 
.PARAMETER TransformFile
The transformations to apply to the source file
 
.PARAMETER OutputFile
Where to write the resulting output
 
.EXAMPLE
Create-WebConfigTransform -SourceFile C:\path\to\project\Web.config -TransformFile C:\path\to\project\Web.Debug.config -OutputFile c:\temp\transformed.xml
 
.LINK
http://msdn.microsoft.com/en-us/library/dd465326.aspx
#>
Function Create-WebConfigTransform {
  param(
      [Parameter(Mandatory=$true)]
      [ValidateScript({Test-Path $_})]
      [string]$SourceFile,
   
      [Parameter(Mandatory=$true)]
      [ValidateScript({Test-Path $_})]
      [string]$TransformFile,
   
      [Parameter(Mandatory=$true)]
      [string]$OutputFile
  )
   
  # set up output filenames
  $WorkDir = Join-Path ${env:temp} "work-${PID}"
  $SourceWork = Join-Path $WorkDir (Split-Path $SourceFile -Leaf)
  $TransformWork = Join-Path $WorkDir (Split-Path $TransformFile -Leaf)
  $OutputWork = Join-Path $WorkDir (Split-Path $OutputFile -Leaf)
  $AssemblyPath = (Get-Item -Path $PSScriptRoot"\Microsoft.Web.Publishing.Tasks.dll" -Verbose).FullName
   
  # create a working directory and copy files into place
  New-Item -Path ${WorkDir} -Type Directory
  Copy-Item $SourceFile $WorkDir
  Copy-Item $TransformFile $WorkDir
   
  # write the project build file
  $BuildXml = @"
<Project ToolsVersion="4.0" DefaultTargets="TransformWebConfig" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <UsingTask TaskName="TransformXml"
             AssemblyFile="$($AssemblyPath)"/>
  <Target Name="TransformWebConfig">
    <TransformXml Source="${SourceWork}"
                  Transform="${TransformWork}"
                  Destination="${OutputWork}"
                  StackTrace="true" />
  </Target>
</Project>
"@
  $BuildXmlWork = Join-Path $WorkDir "build.xml"
  $BuildXml | Out-File $BuildXmlWork
 
  # call msbuild
  & $PSScriptRoot\MSBuild.exe $BuildXmlWork
 
  # copy the output to the desired location
  Copy-Item $OutputWork $OutputFile
 
  # clean up
  Remove-Item $WorkDir -Recurse -Force
}