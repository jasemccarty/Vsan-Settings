<#===========================================================================
Script Name: GetVSANThinSwap.ps1
Created on: 2/21/2016 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script will go through each host in a cluster and determine read the Advanced Configuration Setting
/VSAN/SwapThickProvisionDisabled 

A setting of 0 means that vSwp files are created with a 100% Object Space Reservation (default)
A setting of 1 means that vSwp files are created thin, with 0% Object Space Reservation

.Notes
This is only applicable to ESXi hosts with Virtual SAN 6.2 or greater
#>

# Must be connected to vCenter Server 1st
# Connect-VIServer

# Get each cluster managed by vCenter Server
Foreach ($Cluster in (Get-Cluster |Sort Name)){

	# Display the Current Cluster
	Write-Host ìCluster: $($Cluster.name)ì

	# Cycle through each ESXi Host in the cluster
	Foreach ($ESXHost in ($Cluster |Get-VMHost |Sort Name)){

		# Grab EsxCLI content to check for proper host version
		$esxcli = Get-EsxCli -VMHost $ESXHost

		# Grab the major host version
		$esxmajor = $esxcli.system.version.get().version

		# Grab the update version
		$esxupdate = $esxcli.system.version.get().update

		# Make sure a version 6.0.0 host is being checked
		If ($esxmajor -eq "6.0.0") {

			# Make sure the host is ESXi 6.0.0 Update 2
			If ($esxupdate -gt "1") {

				# Grab the current SwapThickProvisionDisabled Setting
				$Setting = Get-AdvancedSetting -Entity $ESXHost -Name "VSAN.SwapThickProvisionDisabled"

				If ($Setting.Value -eq "1") {
					
					# Display the current setting
					Write-Host " $ESXHost is set for Thin Swap Files "
				
				} else {

					# Display the current setting
					Write-Host " $ESXHost is set for Thick Swap Files"
				}
			}
		}
	}
}
