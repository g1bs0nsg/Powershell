<#
.SYNOPSIS
    Searches ConfigMgr for the specified object and returns the location.
.DESCRIPTION
    Searches ConfigMgr for applications/packages/collections/etc and returns their location.
.PARAMETER InstanceKey
    What you want to look for.  Can be collection, package, application, configuration item, etc... just enter the name.
.EXAMPLE
    .\Get-ObjectLocation.ps1 -InstanceKey "Some Application"
.NOTES
    Useful for finding things buried in folders.
#>

param (
    [string]$InstanceKey
)

$SiteCode = "ABC"
$SiteServer = "siteserver.domain.com"

# Set the current location
Push-Location

# Import Configuration Manager module
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)

# Set location to ConfigMgr drive
$CMDrive = Get-PSDrive -PSProvider CMSite
Set-Location "$($CMDrive):"

$InstanceKey = Get-CMDeviceCollection -Name $InstanceKey | Select-Object -ExpandProperty CollectionID

    $ContainerNode = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT ocn.* FROM SMS_ObjectContainerNode AS ocn JOIN SMS_ObjectContainerItem AS oci ON ocn.ContainerNodeID=oci.ContainerNodeID WHERE oci.InstanceKey='$InstanceKey'"
    if ($ContainerNode -ne $null) {
        $ObjectFolder = $ContainerNode.Name
        if ($ContainerNode.ParentContainerNodeID -eq 0) {
            $ParentFolder = $false
        }
        else {
            $ParentFolder = $true
            $ParentContainerNodeID = $ContainerNode.ParentContainerNodeID
        }
        while ($ParentFolder -eq $true) {
            $ParentContainerNode = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT * FROM SMS_ObjectContainerNode WHERE ContainerNodeID = '$ParentContainerNodeID'"
            $ObjectFolder =  $ParentContainerNode.Name + "\" + $ObjectFolder
            if ($ParentContainerNode.ParentContainerNodeID -eq 0) {
                $ParentFolder = $false
            }
            else {
                $ParentContainerNodeID = $ParentContainerNode.ParentContainerNodeID
            }
        }
        $ObjectFolder = "Root\" + $ObjectFolder
        Write-Output $ObjectFolder
    }
    else {
        $ObjectFolder = "Root"
        Write-Output $ObjectFolder
    }

Pop-Location