<#
.SYNOPSIS
    Reports free space on a computer, clears temp files, and if it is a VM will expand disk if necessary.
.DESCRIPTION
    Checks the C:\ drive on a computer and reports back free space.  Will clear out C:\windows\temp 
    and C:\windows\ccmcache directories.  If it is a virtual machine, will connect to vcenter 
    and verify that disk size is what is specified and increase it if not. Finally will report 
    freespace again with all changes applied.
.PARAMETER computer
    Name of the computer/VM to check.
.EXAMPLE
    .\VM-FreeSpace.ps1 -computer COMPUTER1
.NOTES
    Make sure to set drive letters, vcenter server, and disk sizes appropriately for your environment.
#>

[CmdletBinding()]
Param (
[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
$computer
)

$temp = "\\$($computer)\C$\Windows\Temp"
$ccmcache = "\\$($computer)\C$\Windows\ccmcache"

If ( Test-Connection -ComputerName $computer -Count 1 -ErrorAction SilentlyContinue ) {

    Try {
        $freespace = [math]::Round((Get-WmiObject -ComputerName $computer -class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" } | Select-Object -ExpandProperty FreeSpace ) / 1GB)
    } Catch {
        Write-Output "Unable to determine disk free space, the error encountered was: $_"
        Exit
    }

   Write-Output "Beginning Disk Space Free $freespace GB"

   Write-Output "Clearing Temp files"

   Try {
   Get-ChildItem -Path $temp | Select-Object -ExpandProperty FullName | ForEach-Object { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue}
   } Catch {
        Write-Output "Unable to clear Temp files, the error encountered was: $_"
   }
   Write-Output "Clearing SCCM Cache"
   Try {
        $cache = Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent"

        $cache | Remove-WmiObject

        Get-ChildItem -Path $ccmcache | Select-Object -ExpandProperty FullName | ForEach-Object { Remove-Item $_ -Recurse -Force -ErrorAction STOP}
    } Catch {
        Write-Output "Unable to clear SCCM cache, the error encountered was $_"
    }

   $endfreespace = [math]::Round((Get-WmiObject -ComputerName $computer -class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" } | Select-Object -ExpandProperty FreeSpace ) / 1GB)

   Write-Output "Ending Disk Space Free $endfreespace GB"

} Else {

   Write-Output "$computer is not currently accessible"
   Exit

}

If (((Get-WmiObject -ComputerName $computer -class Win32_ComputerSystem).Manufacturer) -like "*VMWare*") {

$VMServer = "vCenterServer"

If (!(Test-Path vi:)) {
Connect-VIServer $VMServer | Out-Null
}

Try {
$drivesize = (Get-HardDisk -VM $computer -ErrorAction STOP | Select-Object -ExpandProperty CapacityGB)
Write-Output "VM $computer has a disk size of $drivesize"
} Catch {
Write-Output "Unable to query disk size, the error encountered was: $_"
Exit
}
    If ($drivesize -lt 100) {

        Write-Output "VM $computer has a disk size of $drivesize, increasing to 100 GB"
        Set-HardDisk -HardDisk (Get-HardDisk -VM $computer) -CapacityGB 100 -Confirm:$false
    }

}