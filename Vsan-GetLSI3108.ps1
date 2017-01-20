<#===========================================================================
Script Name: Vsan-GetLSI3108.ps1
Created on: 3/9/2016 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script will go through each host in a cluster and read the Advanced Configuration Setting of
/LSOM/diskIoTimeout
/LSOM/diskIoRetryFactor

Specific to KB 2144936 (https://kb.vmware.com/kb/2144936)
.Notes
This is only applicable to LSI3108 controllers
#>

# Must be connected to vCenter Server 1st
# Connect-VIServer

# Get each cluster managed by vCenter Server
Foreach ($Cluster in (Get-Cluster |Sort Name)){

	# Display the Current Cluster
	Write-Host Cluster: $($Cluster.name)

	# Cycle through each ESXi Host in the cluster
	Foreach ($ESXHost in ($Cluster |Get-VMHost |Sort Name)){

				# Grab the current /LSOM/diskIoTimeout Setting
				$IOTIMEOUT = Get-AdvancedSetting -Entity $ESXHost -Name "LSOM.diskIoTimeout"

				# Grab the current /LSOM/diskIoRetryFactor Setting
				$IORETRYFACTOR = Get-AdvancedSetting -Entity $ESXHost -Name "LSOM.diskIoRetryFactor"
				
					# Display the current setting
					Write-Host " $ESXHost $IOTIMEOUT $IORETRYFACTOR "
			}
}
