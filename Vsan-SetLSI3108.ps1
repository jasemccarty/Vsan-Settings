<#==========================================================================
Script Name: Vsan-SetLSI3108.ps1
Created on: 3/9/2016 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script set advanced settings for LSI3108 Controllers per KB2144936 (https://kb.vmware.com/kb/2144936)

.Notes

#>

# Must be connected to vCenter Server 1st
# Connect-VIServer

# Get each cluster managed by vCenter Server
Foreach ($Cluster in (Get-Cluster |Sort Name)){

    # Display the Current Cluster
    Write-Host Cluster: $($Cluster.name)
    
    # Cycle through each ESXi Host in the cluster
    Foreach ($ESXHost in ($Cluster |Get-VMHost |Sort Name)){
    
      # Get the current setting for diskIoTimeout
      $IOTIMEOUT = Get-AdvancedSetting -Entity $ESXHost -Name "LSOM.diskIoTimeout"
                  
                  # If the IO Timeout doesn't align with KB2135494, set the correct value
                  If($IOTIMEOUT.value -ne "100000"){

                      # Show that host is being updated
                      Write-Host "Updating LSOM Disk IO Timeout Setting for $ESXHost"
                      $IOTIMEOUT | Set-AdvancedSetting -Value 100000 -Confirm:$false
                } else {
			                # Show that the host is already set for the right timeout
			                Write-Host "$esx is already configured for the proper timeout"
		            }
		            
      # Get the current setting for diskIoRetryFactor
      $IORETRYFACTOR = Get-AdvancedSetting -Entity $ESXHost -Name "LSOM.diskIoRetryFactor"
                  
                  # If the IO RetryFactor doesn't align with KB2135494, set the correct value
                  If($IORETRYFACTOR.value -ne "4"){

                      # Show that host is being updated
                      Write-Host "Updating LSOM Disk IO Retry Factor Setting for $ESXHost"
                      $IORETRYFACTOR | Set-AdvancedSetting -Value 4 -Confirm:$false
                } else {
			                # Show that the host is already set for the right retry factor
			                Write-Host "$esx is already configured for the proper retry factor"
		            }		            
		            
    }
}
