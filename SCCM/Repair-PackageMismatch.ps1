<#
.SYNOPSIS
    Compares packages on two DPs and corrects any differences that are found.
.DESCRIPTION
    Used to resolve content validation and replication issues.  Compare the contents of PackageID.INI and Datalib folders
    on one known good DP and one that is suspected to have an issue.  If differences are found the INI and Datalib folders
    will be corrected on the bad DP.
.PARAMETER gooddp
    FQDN of the known good distribution point to compare against.
.PARAMETER baddp
    FQDN of the distribution point having validation or replication issues on a package.
.PARAMETER packageid
    PackageID of the content that is experiencing an issue on the bad distribution point.
.EXAMPLE
    .\Repair-PackageMismatch.ps1 -gooddp yourserver.domain.com -baddp badserver.domain.com -packageid COD12345
.NOTES
    Useful for repairing INI and Datalib folder mismatches that can prevent content replication entirely, or cause
    validation to fail. Be sure to set the paths for your environment, all of my distribution points have a D:\ drive
    that contains the SCCMContentLib folder. YMMV.
#>

[CmdletBinding()]
Param (
[Parameter(Mandatory=$true)]
$gooddp,
[Parameter(Mandatory=$true)]
$baddp,
[Parameter(Mandatory=$true)]
$packageid
)

# Collect package information from each DP

$goodlocation = "\\$($gooddp)\D$\SCCMContentLib\PkgLib\$($packageid).INI"
$badlocation = "\\$($baddp)\D$\SCCMContentLib\PkgLib\$($packageid).INI"

$goodini = Get-Content -Path $goodlocation
$badini = Get-Content -Path $badlocation

# Compare Contents and get strings that are only in the bad ini 
$badfiles = Compare-Object $goodini $badini | Where-Object {$_.SideIndicator -eq "=>"} | Select-Object -ExpandProperty InputObject

# Check to see if badfiles contains data, and replace the file contents if it does
If ($badfiles) {

    Write-Output "The following files must be removed from the DataLib folder on $baddp"
    $badfiles

    Clear-Content -Path $badlocation
    $goodini | Set-Content -Path $badlocation   
    
    # Run Get-Content again to refresh the data and compare to verify no more differences
    $badini = Get-Content -Path $badlocation
    $result = Compare-Object $goodini $badini

        If ($result) {
        
            Write-Output "$goodlocation and $badlocation still don't match, please manually remediate"
            Exit 1

        } Else {

            Foreach ($file in $badfiles) {
                
                # Remove the = from the end of each file string
                $file = $file.Replace('=','')

                # Check to see if the file exists in the DataLib, and delete if so
                If (Test-Path -Path "\\$($baddp)\D$\SCCMContentLib\DataLib\$($file)") {
                
                    Write-Output "$file exists on $baddp, deleting..."
                    Try {
                    
                        Remove-Item -Path "\\$($baddp)\D$\SCCMContentLib\DataLib\$($file)" -Recurse

                    } Catch {
                    
                        Write-Output "An error was encountered while attempting to delete $file, please manually remediate"
                    }
                
                }
                # Check to see if an INI for the file existsin DataLib, and delete if so
                If (Test-Path -Path "\\$($baddp)\D$\SCCMContentLib\DataLib\$($file).INI") {
                
                    Write-Output "$($file).INI exists on $baddp, deleting..."
                    Try {
                    
                        Remove-Item -Path "\\$($baddp)\D$\SCCMContentLib\DataLib\$($file).INI" -Recurse

                    } Catch {
                    
                        Write-Output "An error was encountered while attempting to delete $($file).INI, please manually remediate"
                    }
                
                }
            }

        }
} Else {

    Write-Output "There are no differences between $goodlocation and $badlocation"

}
