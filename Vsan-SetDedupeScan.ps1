<#==========================================================================
Script Name: Vsan-SetDedupeScan.ps1
Created on: 7/18/2016 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script sets advanced settings for DedupeScan on Hybrid Virtual SAN 6.2
Referenced in http://kb.vmware.com/kb/2146267

Syntax is:
To Set DedupeScan On 
Vsan-SetDedupeScan.ps1 -ClusterName <ClusterName> -DedupeScan enable
To turn DedupeScan Off
Vsan-SetDedupeScan.ps1 -ClusterName <ClusterName> -DedupeScan disable

.Notes
#>

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)]
  [string]$ClusterName,

  [Parameter(Mandatory = $true)]
  [ValidateSet('enable','disable')]
  [String]$DedupeScan
)
# Must be connected to vCenter Server 1st
# Connect-VIServer

# Get the Cluster Name
$Cluster = Get-Cluster -Name $ClusterName

# Check to ensure we have either enable or disable, and set our values/text
Switch ($DedupeScan) {
	"disable" { 
		$DDS = "0"
		$DDSTEXT = "Disabled DedupeScan"
		}
	"enable" {
		$DDS = "1"
		$DDSTEXT  = "Enabed DedupeScan" 
		}
	default {
		write-host "Please include the parameter -DedupeScan enable or -DedupeScan disable"
		exit
		}
	}
    # Display the Cluster
    Write-Host Cluster: $($Cluster.name)
    
    # Cycle through each ESXi Host in the cluster
    Foreach ($ESXHost in ($Cluster |Get-VMHost | Sort Name)){
		
	# If the Cluster has VSAN Enabled, then proceed
	if ($Cluster.VsanEnabled){
		
		# Grab each disk and check to see if it is SSD or not (Checking for All-Flash)
		$HybridDisks = Get-VsanDisk | Where-Object {-Not $_.IsSsd}

			# If we find any non-SSD disks, we'll assume a Hybrid Configuration
			if ($HybridDisks.count -gt 1) {
			
				Write-Host "Hybrid Architecture: Proceeding"
				
				# Get the current setting for lsomComponentDedupScanType
				$DedupeScanType = Get-AdvancedSetting -Entity $ESXHost -Name "LSOM.lsomComponentDedupScanType"
				
				# check to see if the value doesn't match the enable/disable parameter
				If($DedupeScanType.value -ne $DDS){
				
					# Show that host is being updated
					Write-Host "Updating LSOM DedupeScan Type Setting for $ESXHost"
														
					$DedupeScanType | Set-AdvancedSetting -Value $DDS -Confirm:$false
				} else {
					
					# Show that the host is already set for the right Dedupe Scan Type
					Write-Host "$ESXHost is already configured for $DDSTEXT"
				}
		} else {
			
			Write-Host "All-Flash Architecture: Exiting"
			Exit
		}
	} else {
		Write-Host "VSAN Not Enabled: Exiting"
		Exit
	}
}
