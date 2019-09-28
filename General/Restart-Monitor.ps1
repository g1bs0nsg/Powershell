<#
.SYNOPSIS
    Monitors reboot progress of a computer.
.DESCRIPTION
    Monitors the reboot progress of a computer and will update when it is again available
    to connect via RDP.
.PARAMETER computer
    Name of the computer to be monitored.
.PARAMETER timeout
    Maximum time (in minutes) to run before the script aborts.
.EXAMPLE
    .\Restart-Monitor.ps1 -computer yourcomputer -timeout 5
.NOTES
    Pings the computer to monitor the up/down state, but then checks to see that
    \\computer\C$ is accessible.  This ensures that you will be able to connect with 
    RDP, whereas sometimes connection is still unavailable when the machine initially
    starts to ping again after a reboot.
#>
Function Restart-Monitor {
   Param (
   [Parameter(ValueFromPipeline=$False,Mandatory=$True)]
    [string]$computer,
   [Parameter(ValueFromPipeline=$False,Mandatory=$False)]
    [int]$timeout=5
)
$MAX_PINGTIME = $timeout * 60
$max_iterations = $MAX_PINGTIME/5


Function Ping-Host {
$status = Get-WmiObject -Class Win32_PingStatus -Filter "Address='$computer'"
if( $status.statuscode -eq 0) {
    return 1
} else {
    return 0
    }

}
If(Ping-Host $computer) {
    Write-Host "$computer is online; Waiting for it to go offline" -foregroundcolor "green"
    $status = "Online"
for ($i=0; $i -le $max_iterations; $i++) {
    if (!(Ping-Host $computer)) {
        break
    }
Start-Sleep -Seconds 5
if($i -eq $max_iterations) {
    Write-Host "$computer never went down in last $timeout minutes" -foregroundcolor "red"
    Write-Host "Check that reboot was initiated properly" -foregroundcolor "red"
    Return
        }
    }
Write-Host "$computer is offline now; monitoring for online status" -foregroundcolor "yellow"
} else {
    Write-Host "$computer is offline; monitoring for online status" -foregroundcolor "yellow"
    $status = "Offline"
}
for ($i=0; $i -le $max_iterations; $i++) {
    if ((Test-Path \\$computer\C$)) {
        break
        }
Start-Sleep -Seconds 5
    if ($i -eq $max_iterations) {
        Write-Host "$computer never came back online in last $MAX_PINGTIME seconds" -foregroundcolor "red"
        Write-Host "Check that nothing is preventing startup" -foregroundcolor "red"
    Return
    }
   }
Write-Host "$computer is now back online" -foregroundcolor "green"
}
