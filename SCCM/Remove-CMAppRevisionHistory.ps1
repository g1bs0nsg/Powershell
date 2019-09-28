<#
.SYNOPSIS
    Removes revision history from a specified application.
.DESCRIPTION
    Completely removes all revision history from the specified application.
.PARAMETER Application
    Name of the application that you want to remove revision history from.
.EXAMPLE
    .\Remove-CMAppRevisionHistory.ps1 -Application YourAppHere
.NOTES
    Good to use before releasing an app to production to get rid of any testing revisions.
#>

[CmdletBinding()]
Param (
[Parameter(Mandatory=$True)]
[string]$Application
)

# Set the current location
Push-Location

# Import Configuration Manager module
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)

# Set location to ConfigMgr drive
$CMDrive = Get-PSDrive -PSProvider CMSite
Set-Location "$($CMDrive):"

$cmApps = Get-CMApplication -Name $Application
foreach ($cmApp in $cmApps)
{
	$cmAppRevision = $cmApp | Get-CMApplicationRevisionHistory
	for ($i = 0;$i -lt $cmAppRevision.Count-1;$i++) { Remove-CMApplicationRevisionHistory -name $cmApp.LocalizedDisplayName -revision $cmAppRevision[$i].CIVersion -force }
}

# Return to original location
Pop-Location