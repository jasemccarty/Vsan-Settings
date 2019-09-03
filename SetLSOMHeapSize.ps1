<#==========================================================================
Script Name: SetLSOMHeapSize.ps1
Created on: 3 SEP 2019
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script sets LSOM Heap Size Settings for ESXi Hosts, per KB Article: https://kb.vmware.com/kb/2150566

Syntax is:
SetLSOMHeapSize.ps1 -VIServer <vCenter/ESXiHost> -HeapSize <value> -ClusterName <ClusterName>

.Notes

#>

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)]
  [string]$VIServer,

  [Parameter(Mandatory=$False)]
  [string]$ClusterName,

  [Parameter(Mandatory = $true)]
  [ValidateSet(256,1023,2047)]
  [Int]$HeapSize

)
	
Function SetLSOMHeapSize{
Param ([string]$ESXHost,[Int]$HeapSizeVal)
				
	$CurrentHeapSize  = Get-AdvancedSetting -Entity $ESXHost -Name "LSOM.heapSize"

	# Display the Host this is being performed on
	Write-Host "Host:" $ESXHost

	# If any of these are set to the opposite, toggle the setting
	If($CurrentHeapSize.value -ne $HeapSize){
		# Show that host is being updated
		Write-Host "On $ESXHost the LSOM Heap Size is $CurrentHeapSize " -foregroundcolor red -backgroundcolor white
		$CurrentHeapSize | Set-AdvancedSetting -Value $HeapSize -Confirm:$false

		Write-Host "A reboot of host $ESXHost is required for the updates to take effect" -foregroundcolor white -backgroundcolor red 
	}  else {
		Write-Host "On $ESXHost the LSOM Heap Size is already set to $HeapSize" -ForegroundColor green
		Write-Host "A reboot of host $ESXHost is not required as no updates have been made" -foregroundcolor green 
	}		
	Write-Host " "
}
	
# If the ClusterName variable is passed, it is expected that the Server used will be a vCenter Server
If ($ClusterName) {
				
	# Get the Cluster Name
	$Cluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue
				
	# Display the Cluster
	Write-Host Cluster: $($Cluster.name)
			
	# Cycle through each ESXi Host in the cluster
	Foreach ($ESXHost in ($Cluster |Get-VMHost | Sort-Object "Name")){
		
		# Execute the funtion to get/set the Rx Dispatch Queue settings
		SetLSOMHeapSize -ESXHost $ESXHost -HeapSize $HeapSize		
	}
} else {
		# Execute the funtion to get/set the LSOM Heap Size settings
		SetLSOMHeapSize -ESXHost (Get-VMHost $VIServer) -HeapSize $HeapSize
} 
