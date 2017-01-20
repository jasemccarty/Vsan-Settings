<#==========================================================================
Script Name: Vsan-GetDedupeScan.ps1
Created on: 7/18/2016 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script gets advanced settings for DedupeScan

Syntax is:
Vsan-GetDedupeScan.ps1 -ClusterName <ClusterName>

.Notes
#>

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)]
  [string]$ClusterName
)
# Must be connected to vCenter Server 1st
# Connect-VIServer

# Get the Cluster Name
$Cluster = Get-Cluster -Name $ClusterName

# Display the Cluster
Write-Host Cluster: $($Cluster.name)
    
# Cycle through each ESXi Host in the cluster
Foreach ($ESXHost in ($Cluster |Get-VMHost | Sort Name)){
		
	if ($Cluster.VsanEnabled){
		$HybridDisks = Get-VsanDisk | Where-Object {-Not $_.IsSsd}
		if ($HybridDisks.count -gt 1) {
			
			# If we find any non-SSD disks, we'll assume a Hybrid Configuration
			Write-Host "Hybrid Architecture: Proceeding"
				
			# Grab the current /LSOM/lsomComponentDedupScanType
			$DedupeScanType = Get-AdvancedSetting -Entity $ESXHost -Name "LSOM.lsomComponentDedupScanType"
				
			# Display the current setting
			Write-Host "$ESXHost $DedupeScanType"
		} else {
					
			Write-Host "All-Flash Architecture: Exiting"
			Exit
		}
		
	} else {
		
		Write-Host "VSAN Not Enabled: Exiting"
		Exit
	}
}
