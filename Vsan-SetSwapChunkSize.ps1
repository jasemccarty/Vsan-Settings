<#==========================================================================
Script Name: Vsan-SetSwapChunkSize.ps1
Created on: 12/12/2017 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script will go through each host in a designated cluster and 
set /Mem/SwapExtendChunkSizeInMB to either 0 or 65536

Used to mitigate KB 2150316
https://kb.vmware.com/kb/2150316

Syntax is:
To Set to Max
Vsan-SetSwapChunkSize.ps1 -ClusterName <ClusterName> -ChunkSize max
To Set to Default
Vsan-SetSwapChunkSize.ps1 -ClusterName <ClusterName> -ChunkSize default

.Notes
This is only applicable to ESXi hosts with vSAN 6.5 or greater
#>

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)]
  [string]$ClusterName,

  [Parameter(Mandatory = $true)]
  [ValidateSet('max','default')]
  [String]$ChunkSize
)

# Must be connected to vCenter Server 1st
# Connect-VIServer

# Get the Cluster Name
$Cluster = Get-Cluster -Name $ClusterName

# Check to ensure we have either enable or disable, and set our values/text
Switch ($ChunkSize) {
	"max" { 
		$ChunkSizeValue = "0"
		$ChunkSizeText = "ChunkSize set to Max"
		}
	"default" {
		$ChunkSizeValue = "65536"
		$ChunkSizeText  = "ChunkSize set to Default" 
		}
	default {
		write-host "Please include the parameter -ChunkSize max or -ChunkSize default"
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
		
        	# Make sure a version 6.5.0 host is being checked
		If ($esxmajor -eq "6.5.0") {
			  
				# Get the current setting for SwapExtendChunkSizeInMB
				$ChunkSizeSetting = Get-AdvancedSetting -Entity $ESXHost -Name "Mem.SwapExtendChunkSizeInMB"

				# If the chunk size is different than the requested setting, set them to the opposite
				If($ChunkSizeSetting.value -ne $ChunkSizeValue){

					# Show that host is being updated
					Write-Host "Updating Swap ChunkSize Setting for $ESXHost"
					$ChunkSizeSetting | Set-AdvancedSetting -Value $ChunkSizeValue -Confirm:$false
                
				} else {

					# Show that the host is already set to the value requested
					Write-Host "$ESXhost is already configured for $ChunkSizeText"
		     }
			  
		}

	}	
	
} else {
	
	Write-Host "vSAN Not Enabled on Cluster $ClusterName: Exiting"
	Exit
	
}
