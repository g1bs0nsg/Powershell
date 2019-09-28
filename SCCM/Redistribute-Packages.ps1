<#
.SYNOPSIS
    Redistributes a list of packages on the select server.
.DESCRIPTION
    Specify a list, one packageID per line, of packages that need to be redistributed to the specified server.
.PARAMETER Server
    Distribution Point to redistribute packages to.
.EXAMPLE
    .\Redistribute-Packages.ps1 -Server SERVER1
.NOTES
    Used to quickly redistribute a set of packages to a given distribution point.
#>

Param(
  $Server
)

#Change the site Code
$SiteCode = "ABC"

# Site Server
$SiteServer = "siteserver.domain.com"

#provide the path to a list of packages to be Refreshed
$packages = Get-Content "C:\path\to\packages.txt"

foreach ($package in $packages){

#Provide the DP server Name to be refreshed ON
#host name is enough,no FQDN is required
$pkgs = Get-WmiObject -ComputerName $SiteServer -Namespace "root\SMS\Site_$($SiteCode)" -Query "Select * From SMS_DistributionPoint WHERE PackageID='$Package' and serverNALPath like '%$Server%'"

    foreach ($pkg in $pkgs){
    $pkg.RefreshNow = $true
    $pkg.Put()
    # "Pkg:" + $package + " "+ "Refreshed On" + " "+ "Server:" +$server | Out-File -FilePath C:\Scripts\server-refresh-results.txt -Append
    }
}