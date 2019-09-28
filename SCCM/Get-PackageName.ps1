<#
.SYNOPSIS
    Looks up the actual name of a PackageID
.DESCRIPTION
    Connects to WMI on Site Server and looks up proper name for a PackageID
.PARAMETER PackageID
    PackgeID to look up.
.EXAMPLE
    .\Get-PackageName.ps1 -PackageID COD12345
.NOTES
    Useful for quickly finding names for packages that have failed content replciation/validation.
#>

Param(
[Parameter(Mandatory=$True)]
[string]$PackageID
)

# UPDATE THESE VARIABLES FOR YOUR ENVIRONMENT
[string]$SiteServer = "siteserver.domain.com"
[string]$SiteCode = "ABC"

# Get all valid packages from the primary site server
$Namespace = "root\SMS\Site_" + $SiteCode

Get-WMIObject -ComputerName $SiteServer -Namespace $Namespace -Query "Select * from SMS_ObjectContentExtraInfo" | Where-Object {$_.PackageID -eq $PackageID} | Select-Object SoftwareName,PackageID