function Remove-Software {
<#
.SYNOPSIS
    Silently uninstalls software from a remote computer.
.DESCRIPTION
    Wildcard searches uninstall keys in the registry for matching specified software name,
    if one is found, triggers msiexec /X{ProductCode} /qn to quietly uninstall.
.PARAMETER computer
    The computer to uninstall software from.
.PARAMETER software
    The name of the software to uninstall.  Will be a wildcard search as in *software*.
.EXAMPLE
    UninstallSW.ps1 -computer COMPUTER1 -software "Flash Player"
.NOTES
    Uses somewhat broad search terms, always test first.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact="High")]
param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [string]$computer,
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [string]$software
        )

$uninstall32 = Invoke-Command -ComputerName $computer -ScriptBlock {
     Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | 
     ForEach-Object { Get-ItemProperty $_.PSPath }}
$uninstall32 = $uninstall32 | Where-Object { $_.DisplayName -like "*$software*" }

$uninstall64 = Invoke-Command -ComputerName $computer -ScriptBlock {
     Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | 
     Foreach-Object { Get-ItemProperty $_.PSPath }}
$uninstall64 = $uninstall64 | Where-Object { $_.DisplayName -like "*$software*" }

$displayname32 = $uninstall32.DisplayName
$displayname64 = $uninstall64.DisplayName

if ($uninstall64) {
$uninstall64 = $uninstall64.UninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X",""
$uninstall64 = $uninstall64.Trim()
if ($pscmdlet.ShouldProcess($displayname64)){ 
Write-Output "Uninstalling $displayname64 from $computer"
Try {
$returnval = ([WMICLASS]"\\$computer\ROOT\CIMV2:win32_process").Create("msiexec `/X $uninstall64 `/qn")
} Catch {
Write-Error "Failed to trigger the uninstallation.  Review the error message"
$_
exit
    }
   }
  }
if ($uninstall32) {
$uninstall32 = $uninstall32.UninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X",""
$uninstall32 = $uninstall32.Trim()
if ($pscmdlet.ShouldProcess($displayname32)){ 
Write-Output "Uninstalling $displayname32 from $computer"
Try {
$returnval = ([WMICLASS]"\\$computer\ROOT\CIMV2:win32_process").Create("msiexec `/X $uninstall32 `/qn")
} Catch {
Write-Error "Failed to trigger the uninstallation.  Review the error message"
$_
exit
    }
   }
}
switch ($($returnval.returnvalue)){
0 { "Uninstallation command triggered sucessfully" }
2 { "You don't have sufficient permissions to trigger the command on $Computer" }
3 { "You don't have sufficient permissions to trigger the command on $Computer" }
8 { "An unknown error has occurred" }
9 { "Path Not Found" }
9 { "Invalid Parameter"}

    }
if (!$uninstall32 -and !$uninstall64) {
Write-Host "$software not found on $computer."
   } else {
$logcheck = ""
    While(!$logcheck) {
        if($logcheck -match "Removal completed sucessfully") {
            return
        } else {
            start-sleep -Seconds 1
            [string]$logcheck = Get-EventLog -ComputerName $computer -logname Application -newest 1 | ForEach-Object {$_.message}
   }
 $success = Get-Eventlog -ComputerName $computer -LogName Application -newest 50 | ForEach-Object {$_.message} | Where-Object {$_ -match "Removal completed successfully"} | Select-Object -First 1
 Write-Host $success }
   }
}
Remove-Software