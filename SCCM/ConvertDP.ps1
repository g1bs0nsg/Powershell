<#
.SYNOPSIS
    Converts a standard DP to Pull or vice versa
.DESCRIPTION
    Uses ConfigMgr cmdlets to convert distribution points between standard and pull
.PARAMETER DP
    FQDN of the DP you wan tto convert.
.PARAMETER Source
    FQDN of the server that content will be pulled from.
.PARAMETER EnablePullDP
    Specify this switch to convert from standard to pull dp.
.PARAMETER DisablePullDP
    Specify this switch to convert from pull to standard dp.
.EXAMPLE
    .\ConvertDP.ps1 -DP server.yourdomain.com -Source source.yourdomain.com -EnablePullDP
.NOTES
    Allows to quickly convert distribution points from pull to standard and vice versa.
#>

[CmdletBinding()]
Param (
[Parameter(Mandatory=$true)]
$DP,
[Parameter(Mandatory=$true)]
$Source,
[switch]$EnablePullDP,
[switch]$DisablePullDP
)

# Set the current location
Push-Location

# Import Configuration Manager module
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)

# Set location to ConfigMgr drive
$CMDrive = Get-PSDrive -PSProvider CMSite
Set-Location "$($CMDrive):"

If ($EnablePullDP) {
    Set-CMDistributionPoint -SiteSystemServerName $DP -EnablePullDP $true -SourceDistributionPoint $Source
}

If ($DisablePullDP) {
    Set-CMDistributionPoint -SiteSystemServerName $DP -EnablePullDP $false
}

Pop-Location

# Opens up the pulldp_install.log to monitor progress, set to proper path for your DPs
& cmtrace "\\$DP\D$\SMS_DP$\sms\logs\pulldp_install.log"