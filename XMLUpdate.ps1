#Update XML Script
#Script to update a single value in an XML. In the example below, it is switching a value from
#True to False.
#The script uses local paths, but can easily be run via PSEXEC to execute on many computers at once.
#The output will display the existing value, and then read the XML again to display the changed
#value.
#Written by Matthew Amalino
Set-ExecutionPolicy RemoteSigned

$XmlToChange = '[PATH OF XML]'

[xml]$xml = New-Object System.Xml.XmlDocument
[xml]$xml = Get-Content $XmlToChange
Write-Host "------------------------------------------------------------------"
Write-Host "Finding Value in $XmlToChange"
Write-Host "------------------------------------------------------------------"
$xml.Configuration.Key.Value | ? {$_.Name -eq '[VALUE TO UPDATE]'}
Write-Host ""
Write-Host ""
Write-Host "-----------------------"
Write-Host "Updating Value"
Write-Host "-----------------------"
$obj = $xml.Configuration.Key.Value | ? {$_.Name -eq '[VALUE TO UPDATE]'}
$obj | % {
    $_."#text" = "[NEW ENTRY - ex. TRUE or FALSE]"
}

Write-Host ""
Write-Host ""
Write-Host "--------------"
Write-Host "Saving Changes"
Write-Host "--------------"
$xml.Save($XmlToChange)

Write-Host ""
Write-Host ""
Write-Host "------------------------------------"
Write-Host "Reading XML Again to Confirm Changes"
Write-Host "------------------------------------"
$xml.Configuration.Key.Value | ? {$_.Name -eq '[VALUE TO UPDATE]'}
