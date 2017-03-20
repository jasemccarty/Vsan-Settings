<#==========================================================================
Script Name: Vsan-SetSwapFiles.ps1
Created on: 8/3/2016 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script will go through each host in a designated cluster and 
set /VSAN/SwapThickProvisionDisabled to either Thin or Space Reserved (Thick)

Syntax is:
To Set Thin Swap Files 
Vsan-SetSwapFiles.ps1 -ClusterName <ClusterName> -VMSwap thin
To turn DedupeScan Off
Vsan-SetSwapFiles.ps1 -ClusterName <ClusterName> -VMSwap thick

.Notes
This is only applicable to ESXi hosts with Virtual SAN 6.2 or greater
#>

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)]
  [string]$ClusterName,

  [Parameter(Mandatory = $true)]
  [ValidateSet('thin','thick')]
  [String]$VMSwap
)

# Must be connected to vCenter Server 1st
# Connect-VIServer

# Get the Cluster Name
$Cluster = Get-Cluster -Name $ClusterName

# Check to ensure we have either enable or disable, and set our values/text
Switch ($VMSwap) {
	"thin" { 
		$VMS = "1"
		$VMSTEXT = "VM Swap Files set to Thin"
		}
	"thick" {
		$VMS = "0"
		$VMSTEXT  = "VM Swap Files set to Thick (Object Space Reserved)" 
		}
	default {
		write-host "Please include the parameter -VMSwap thin or -VMSwap thick"
		exit
		}
	}
    
    # Display the Cluster
    Write-Host Cluster: $($Cluster.name)

# If the Cluster has VSAN Enabled, then proceed
if ($Cluster.VsanEnabled){ 

	# Cycle through each ESXi Host in the cluster
	Foreach ($ESXHost in ($Cluster |Get-VMHost |Sort Name)){
		
		# Grab EsxCLI content to check for proper host version
		$esxcli = Get-EsxCli -VMHost $ESXHost

		# Grab the major host version
		$esxmajor = $esxcli.system.version.get().version
			
		# Grab the update version
		$esxupdate = $esxcli.system.version.get().update
		
        	# Make sure a version 6.0.0 host is being checked
		If ($esxmajor -eq "6.0.0" -or $esxmajor -eq "6.5.0") {

			# Make sure the host is ESXi 6.0.0 Update 2
              		If ($esxupdate -gt "1" -or $esxmajor -eq "6.5.0") {
			  
				# Get the current setting for SwapThickProvisionDisabled
				$SwapThickProvisionDisabled = Get-AdvancedSetting -Entity $ESXHost -Name "VSAN.SwapThickProvisionDisabled"

				# If Swaps are Thick, set them to thin
				If($SwapThickProvisionDisabled.value -ne $VMS){

					# Show that host is being updated
					Write-Host "Updating VM Swap Files Setting for $ESXHost"
					$SwapThickProvisionDisabled | Set-AdvancedSetting -Value $VMS -Confirm:$false
                
				} else {

					# Show that the host is already set for Thin Swap Files
					Write-Host "$esx is already configured for $VMSTEXT"
		        	}			  
			  
			  }
			  
		}

	}	
	
} else {
	
	Write-Host "VSAN Not Enabled: Exiting"
	Exit
	
}
