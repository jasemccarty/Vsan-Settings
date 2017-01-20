<#==========================================================================
Script Name: Set-VSANThickSwap.ps1
Created on: 2/21/2016 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script will go through each host in a cluster set /VSAN/SwapThickProvisionDisabled to Thick Provisioned Swap Files (Default)

.Notes
This is only applicable to ESXi hosts with Virtual SAN 6.2 or greater
#>

# Must be connected to vCenter Server 1st
# Connect-VIServer

# Get each cluster managed by vCenter Server
Foreach ($Cluster in (Get-Cluster |Sort Name)){

    # Display the Current Cluster
    Write-Host Cluster: $($Cluster.name)
    
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

                  # Get the current setting for SwapThickProvisionDisabled
                  $SwapThickProvisionDisabled = Get-AdvancedSetting -Entity $ESXHost -Name "VSAN.SwapThickProvisionDisabled"
                  
                  # If Swaps are Thick, set them to thin
                  If($SwapThickProvisionDisabled.value -ne "0"){

                      # Show that host is being updated
                      Write-Host "Updating VM Swap Thick Setting for $ESXHost"
                      $SwapThickProvisionDisabled | Set-AdvancedSetting -Value 0 -Confirm:$false
                } else {

			                # Show that the host is already set for Thick Swap Files
			                Write-Host "$esx is already configured for Thick Swap Files"
		            }
		    }        
	    }
    }
}
