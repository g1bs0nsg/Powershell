﻿<#
.SYNOPSIS
    Checks all domain controllers to verify that group membership for a computer has been fully propegated to each one.
.DESCRIPTION
    Uses Active Directory cmdlets to verify that a given computer is listed as a member in a given group on all domain controllers.
.PARAMETER ComputerName
    Specify a single computer name. Will also accept pipeline input.
.PARAMETER ADGroup
    Specify a single Active Directory group name.
.EXAMPLE
    Check-ADPropagation.ps1 -computername SERVER1 -ADGroup Group1
.NOTES
    Useful for verifying replication across large geographical distribution of domain controllers.
#>
[CmdletBinding()]
Param (
[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
[string]$computername,
[Parameter(Mandatory=$True)]
[string]$ADGroup
)
[System.Collections.ArrayList]$DCS = Get-ADDomainController -filter * | Select-Object -ExpandProperty Name | Sort-Object
$TotalDCS = $DCS.count
$counter = 0
$successcounter = 0
$propagated = @()

While ($successcounter -lt $TotalDCS) {
    Foreach ($DC in $DCS) {
        $counter++
        Write-Progress -Activity "Checking Domain Controllers" -CurrentOperation $DC -PercentComplete (($counter / $DCS.count) * 100)
        If (Get-ADComputer $computername -server $DC | Get-ADPrincipalGroupMembership | Where-Object {$_.Name -eq $ADGroup}) {
        Write-Host "Membership to $ADGroup has propagated to $DC for $computername" -ForegroundColor Green
        $successcounter++
        $propagated += $DC
        }
    } 
        foreach ($server in $propagated) {
            $DCS.Remove($server)
        }
            If ($successcounter -lt $TotalDCS) {
            Start-Sleep -Seconds 120
            $counter = 0
            }
}
Write-Host "Membership has been propagated to all available domain controllers"