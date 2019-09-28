<#
 
.SYNOPSIS  
Resets the state of the Pull DP and deletes data from various WMI classes related to Pull DP. You need to run this script as Administrator.

.DESCRIPTION 
This script deletes the data from following WMI classes:
- CCM_DTS_JobEx
- CCM_DTS_JobItemEx
- SMS_PullDPState
- SMS_PullDPContentState
- SMS_PullDPNotification (optional)

The script also checks and reports the count of BITS Jobs. 

.PARAMETER ComputerName 
(Optional) Name of the Pull DP. You can leave this blank for local machine.

.PARAMETER KeepPullDPNotifications
(Optional) Use this switch  if you want to keep the job notifications from SMS_PullDPNotification class.

.PARAMETER WhatIf
(Optional) Use this switch to see how many instances will be deleted.

.EXAMPLE 
Reset-PullDPState -WhatIf
This command checks how many Pull PD jobs will get deleted when running the script

.EXAMPLE
Reset-PullDPState
This command resets the Pull DP related WMI classes along with the Pull DP job Notification XML's

.EXAMPLE
Reset-PullDPState -KeepPullDPNotifications
This command resets the Pull DP related WMI classes without deleting the Pull DP job Notification XML's

.NOTES
07/28/2016 - Version 1.0 - Initial Version of the script

#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$false)]
   [string]$ComputerName = $env:COMPUTERNAME,
	
   [Parameter(Mandatory=$false)]
   [switch]$KeepPullDPNotifications,

   [Parameter(Mandatory=$false)]
   [switch]$WhatIf
)

$LogFile = Join-Path (Split-Path $SCRIPT:MyInvocation.MyCommand.Path -Parent) "Reset-PullDPState.log"
$ErrorActionPreference = "SilentlyContinue"

Function Write-Log {
    Param(
      [string] $text,
      [switch] $NoWriteHost,
      [switch] $IsErrorMessage,
      [switch] $WhatIfMode
    )    

    $timestamp = Get-Date -Format "MM-dd-yyyy HH:mm:ss"    
    "$timestamp $text" | Out-File -FilePath $LogFile -Append

    if ($WhatIfMode) {
        Write-Host $text -ForegroundColor Yellow
        return
    }
    
    if (-not $NoWriteHost) {
        if ($IsErrorMessage) {
            Write-Host $text -ForegroundColor Red
        }
        else {
            Write-Host $text -ForegroundColor Cyan
        }
    }
}

Function Delete-WmiInstances {
    Param(
        [string] $Namespace,
        [string] $ClassName,
        [string] $Filter = $null,
        [string] $Property1,
        [string] $Property2 = "",
        [string] $Property3 = ""
    )

    $success = 0
    $failed = 0
    $counter = 0

    Write-Host ""
    Write-Log "$ClassName - Connecting to WMI Class on $ComputerName"
    if ($Filter -eq $null) {
        $Instances = Get-WmiObject -ComputerName $ComputerName -Namespace $Namespace -Class $ClassName -ErrorVariable WmiError -ErrorAction SilentlyContinue
    }
    else {
        $Instances = Get-WmiObject -ComputerName $ComputerName -Namespace $Namespace -Class $ClassName -Filter $Filter -ErrorVariable WmiError -ErrorAction SilentlyContinue
    }    

    if ($WmiError.Count -ne 0) {
        Write-Log "    $ClassName - Failed to connect. Error: $($WmiError[0].Exception.Message)" -IsErrorMessage
        $WmiError.Clear()
    }
    else {
        $total = ($Instances | Measure-Object).Count

        if ($WhatIf) {
            Write-Log "    (What-If Mode) $total instances will be deleted" -WhatIfMode
        }
        else {
            if ($total -ne $null -and $total -ne 0) {
                Write-Log "    $ClassName - Found $total instances"
                foreach($instance in $Instances) {
                    
                    $instanceText = "$Property1 $($instance.$Property1)"

                    if ($Property2 -ne "") {
                        $instanceText += ", $Property2 $($instance.$Property2)"
                    }

                    if ($Property3 -ne "") {
                        $instanceText += ", $Property3 $($instance.$Property3)"
                    }

                    Write-Log "    Deleting instance for $instanceText" -NoWriteHost
                    $counter += 1

                    $percentComplete = "{0:N2}" -f (($counter/$total) * 100)
		            Write-Progress -Activity "Deleting instances from $ClassName" -Status "Deleting instance #$counter/$total - $instanceText" -PercentComplete $percentComplete -CurrentOperation "$($percentComplete)% complete"
        
                    Remove-WmiObject -InputObject $instance -ErrorVariable DeleteError -ErrorAction SilentlyContinue
                    if ($DeleteError.Count -ne 0) {
                        Write-Log "    Failed to delete instance. Error: $($DeleteError[0].Exception.Message)" -NoWriteHost -IsErrorMessage
                        $DeleteError.Clear()
                        $failed += 1
                    }
                    else {
                        $success += 1
                    }
                }

                Write-Log "    $ClassName - Deleted $success instances. Failed to delete $failed instances."
            }
            else {
                Write-Log "    $ClassName - Found 0 instances."
            }
        }
    }
}

Function Check-BITSJobs {
    
    $DisplayName = "BITS Jobs"

    Write-Host ""
    Write-Log "$DisplayName - Gettting jobs on $ComputerName"
    Import-Module BitsTransfer
    $Instances = Get-BitsTransfer -AllUsers -Verbose -ErrorVariable BitsError -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -eq 'CCMDTS Job'}

    if ($BitsError.Count -ne 0) {
        Write-Log "    $DisplayName - Failed to get jobs. Error: $($BitsError[0].Exception.Message)" -IsErrorMessage
        $BitsError.Clear()
    }
    else {
        $total = ($Instances | Measure-Object).Count
        Write-Log "    $DisplayName - Found $total jobs"

        if ($total -gt 0) {
            Write-Log "    $DisplayName - This script cannot delete these jobs."
            Write-Log "    If necessary, run 'bitsadmin /reset /allusers' command under SYSTEM account (using psexec.exe) to delete the BITS Jobs."
        }
    }
}


Write-Host ""
Write-Log "### Script Started ###"

if ($WhatIf) {
    Write-Host ""
    Write-Log "*** Running in What-If Mode" -WhatIfMode    
}

$DPNamespace = "root\SCCMDP"
$DTSNamespace = "root\CCM\DataTransferService"

Delete-WmiInstances -Namespace $DTSNamespace -ClassName "CCM_DTS_JobEx" -Filter "NotifyEndpoint like '%PullDP%'" -Property1 "ID"
Delete-WmiInstances -Namespace $DTSNamespace -ClassName "CCM_DTS_JobItemEx" -Property1 "JobID"
Delete-WmiInstances -Namespace $DPNamespace -ClassName "SMS_PullDPState" -Property1 "PackageID" -Property2 "PackageVersion" -Property3 "PackageState"
Delete-WmiInstances -Namespace $DPNamespace -ClassName "SMS_PullDPContentState" -Property1 "PackageKey" -Property2 "ContentId" -Property3 "ContentState"

if ($KeepPullDPNotifications) {
    Write-Host ""
    Write-Log "SMS_PullDPNotification - Skipped because KeepPullDPNotifications switch was used."    
}
else {
    Delete-WmiInstances -Namespace $DPNamespace -ClassName "SMS_PullDPNotification" -Property1 "PackageID" -Property2 "PackageVersion"
}

if ($ComputerName -eq $env:COMPUTERNAME) {
    Check-BITSJobs
}
else {
    Write-Host ""
    Write-Log "BITS Jobs - Skipped since script is running against a remote computer."
}

Write-Host ""
Write-Log "### Script Ended ###"
Write-Host "### Check $LogFile for more details. ###" -ForegroundColor Cyan
Write-Host ""