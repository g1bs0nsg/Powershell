Function Get-SCCMPolicy {
<#
.SYNOPSIS
    Triggers SCCM policy retrieval on one or more computers
.DESCRIPTION
    Uses Windows Management Instrumentation (WMI) to trigger Machine Policy Retrieval
    and Evaluation Cycle, Application Deployment Evaluation Cycle, or Software Updates
    Deployment Evaluation Cycle on one or more computers
.PARAMETER MP
    When this switch is specified, a machine policy retrieval and evaluation cycle 
    will be triggered on the selected computer(s)
.PARAMETER AP
    When this switch is specified, an application deployment evaluation cycle will be
    triggered on the selected computer(s)
.PARAMETER UP
    When this switch is specified, a software updates deployment evaluation cycle will
    be triggered on the selected computer(s)
.EXAMPLE
    Get-SCCMPolicy -ComputerName SERVER1 -mp
.EXAMPLE
    Get-SCCMPolicy -ComputerName SERVER1,SERVER2,SERVER3 -ap
.EXAMPLE
    Get-Content computers.txt | Get-SCCMPolicy -up
.NOTES
    Alias for Get-SCCMPolicy is gsp
#>
     [CmdletBinding()]
     Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [string[]]$computername,
        [switch]$mp,
        [switch]$ap,
        [switch]$up
    )

PROCESS{
ForEach ($computer in $computername) {

if ($mp.IsPresent) {
 $trigger = '{00000000-0000-0000-0000-000000000021}'
 Write-Host "Executing Machine Policy Retrieval and Evaluation Cycle on $computer" }
elseif ($ap.IsPresent) {
 $trigger = '{00000000-0000-0000-0000-000000000121}' 
 Write-Host "Executing Application Deployment Evaluation Cycle on $computer"}
elseif ($up.IsPresent) {
 $trigger = '{00000000-0000-0000-0000-000000000108}'
 Write-Host "Executing Software Updates Deployment Evaluation Cycle on $computer" }
else { Write-Host "Please specify a command switch of -mp (Machine Policy), -ap (Application Policy), or -up (Software Updates Policy)"
 Break}

$WMIPath = "\\" + $Computer + "\root\ccm:SMS_Client"
$SMSwmi = [wmiclass]$WMIPath
[Void]$SMSwmi.TriggerSchedule($trigger) 
    }
  }
}