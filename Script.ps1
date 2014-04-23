Import-Module -Name ".\Lib\Load-Config.psm1" 3> $null
Import-Module -Name ".\Lib\Create-WebConfigTransform.psm1" 3> $null

Load-Config ".\Script.config"

#Create-WebConfigTransform -SourceFile ".\Web.config" -TransformFile ".\Web.Homologacao.config" -OutputFile ".\Transformed.config"

$basePath = $appSettings["BasePath"]
$localSource = $appSettings["Source"]
$remoteDestination = $appSettings["Source"]

Write-Host "These folders will be synced:"
foreach($destinationPath in $appSettings["Destinations"]){
    Write-Host "-" ("`"{0}{1}`"" -f $basePath,$localSource) "to" ("`"{0}{1}`"" -f $destinationPath,$remoteDestination)
}

$copyArgs = @("/S", "/E")
if($appSettings["ExcludeFiles"] -ne ""){
    $copyArgs += "/XF"
    $copyArgs += $appSettings["ExcludeFiles"]
}

$confirm = Read-Host "Confirm (y/n)"

if($confirm.ToLower() -eq "y"){
    foreach($destination in $appSettings["Destinations"]){
        $source = ("{0}{1}" -f $basePath,$localSource)
        $dest = ("{0}{1}" -f $destination,$remoteDestination)
        Write-Host "Syncing >" $source "to" $dest

        Write-Host $configFileName

        robocopy $source $dest $copyArgs > $null

        if($appSettings["TransformFile"] -ne ""){
            $configFileName = $source+"Web.config"
            $transformFileName = $source+$appSettings["TransformFile"]
            $outputFileName = $dest+"Web.config"
            Create-WebConfigTransform -SourceFile $configFileName -TransformFile $transformFileName -OutputFile $outputFileName > $null
        }
    }
}

Write-Host "Done!"
Start-Sleep -Second 1