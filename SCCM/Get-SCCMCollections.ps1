<#
.SYNOPSIS
    Returns all ConfigMgr collections that a computer is a member of.
.DESCRIPTION
    Queries site server to return all collections that a computer is a member of.
.PARAMETER ComputerName
    One or more computers to look up.
.EXAMPLE
    .\Get-SCCMCollections.ps1 -ComputerName SERVER1,SERVER2
.NOTES
    Quickly get a list of all collections a computer is a member of.
#>

Param(
     [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
     [string[]]$ComputerName
    )

ForEach ($computer in $ComputerName) {

$Collections = (Get-WmiObject -ComputerName W12-SCCM01 `
                -Namespace root/SMS/site_CFR `
                -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection where name = '$computer' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID").Name


$Collections | Sort-Object
}