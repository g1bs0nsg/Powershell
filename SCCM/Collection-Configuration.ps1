<#

.SYNOPSIS
   Script to check collection configuration to verify which ones have incremental updates enabled vs. scheduled
   updates.  The frequency of updates, and when the last membership change was to allow evaluation of current
   scheduling and update as necessary to ease the load on site server. 

.DESCRIPTION
   This script shows the number of collections with Auto incremental update in Config Mgr 2012 environment
   It also displays which collections and the current member count Microsoft best practice states that this should not exceed 200

   
.EXAMPLE
   .\Collection-Configuration.ps1 

.EXAMPLE
   .\Collection-Configuration.ps1 

#>



# Import Configuration Manager module
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)

# Set the current location
Push-Location

# Set location to ConfigMgr drive
$CMDrive = Get-PSDrive -PSProvider CMSite
Set-Location "$($CMDrive):"

# Pull a list of all SCCM collections to work with later
$AllCollections = Get-CMDeviceCollection

# Initialize array to contain results
$CollectionStatus = @()

# Create a custom object for each collection returned

Foreach ($collection in $AllCollections) {

    # Create a switch statement to quantify the Refresh Type
        $RefreshType = $collection.RefreshType

        $RefreshTypeDescription = switch ($RefreshType) {
            "1" {"Manual Updates Only"}
            "2" {"Scheduled Updates Only"}
            "4" {"Incremental Updates Only"}
            "6" {"Scheduled and Incremental Updates"}
        }
    # Identify the limiting collection
    $LimitingCollection = Get-CMDeviceCollection -Id $collection.LimitToCollectionID | Select-Object -ExpandProperty Name

    # Convert RefreshSchedule to useful information
    $RefreshSchedule = $collection.RefreshSchedule

    If ($RefreshSchedule.DaySpan -ne "0") {
        $RefreshSchedule = "Every $($RefreshSchedule.DaySpan) Days"
        } ElseIf ($RefreshSchedule.HouseSpan -ne "0") {
            $RefreshSchedule = "Every $($RefreshSchedule.HourSpan) Hours"        
        }


    # Create the custom object
    $obj = [pscustomobject] @{
                "Name" = $collection.Name;
                "ID" = $collection.CollectionID;
                "LastUpdate" = $collection.LastMemberChangeTime;
                "RefreshType" = $RefreshTypeDescription;
                "Members" = $collection.MemberCount;
                "LimitingCollection" = $LimitingCollection;
                "RefreshTime" = $collection.RefreshSchedule.StartTime;
                "RefreshFrequency" = $RefreshSchedule
            }
    # Add the custom object to CollectionStatus
    $CollectionStatus += $obj
}

Pop-Location

$CollectionStatus | Export-Csv -Path "C:\temp\CollectionStatus.csv" -NoTypeInformation