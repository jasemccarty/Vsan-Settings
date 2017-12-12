<#==========================================================================
Script Name: Vsan-SetSwapChunkSize.ps1
Created on: 12/12/2017 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script will go through a single host, or each host in a designated cluster, 
and set /Mem/SwapExtendChunkSizeInMB to either 0 or 65536

Used to mitigate KB 2150316
https://kb.vmware.com/kb/2150316

Works with PowerCLI 6.5.4 and vSAN 6.6

Syntax is:
To Set to Max
Vsan-SetSwapChunkSize.ps1 -Target <Target> -Type <cluster/host> -ChunkSize max
To Set to Default
Vsan-SetSwapChunkSize.ps1 -Target <Target> -Type <cluster/host> -ChunkSize default

.Notes
This is only applicable to ESXi hosts with vSAN 6.5 or greater
#>

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)]
  [string]$Target,
    
  [Parameter(Mandatory = $true)]
  [ValidateSet('cluster','host')]
  [String]$Type,
  
  [Parameter(Mandatory = $true)]
  [ValidateSet('max','default')]
  [String]$ChunkSize
)

# Must be connected to vCenter Server 1st
# Connect-VIServer

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
	}

Switch ($Type) {
	"cluster" {
	
		# Get the Cluster Name
		$Cluster = Get-Cluster -Name $Target
		
		# Display the Cluster
    		Write-Host Cluster: $($Cluster.name)
		
		# If the Cluster has VSAN Enabled, then proceed
		if ($Cluster.VsanEnabled){ 
		
			# Cycle through each ESXi Host in the cluster
			Foreach ($ESXHost in ($Cluster |Get-VMHost |Sort Name)){
			
				# Grab EsxCLI content to check for proper host version
				$esxcli = Get-EsxCli -VMHost $ESXHost -V2

				# Grab the major host version
				$esxmajor = $esxcli.system.version.get.invoke().version
			
				# Grab the update version
				$esxupdate = $esxcli.system.version.get.invoke().update
		
		        	# Make sure a version 6.5.0 host is being checked
				If ($esxmajor -ge "6.5.0") {
				
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
				} else {
				
					Write-Host "$ESXhost not version 6.5 or higher - Exiting"
					Exit
				}
			} 
	
		} else {
		
			Write-Host "vSAN Not Enable on Cluster $Cluster.Name - Exiting"
		}
	}
	"host" {
		# Get the Host Name
		$ESXhost = Get-VMHost -Name $Target
		
		# Display the Cluster
    		Write-Host Host: $($ESXhost.name)

			# Grab EsxCLI content to check for proper host version
			$esxcli = Get-EsxCli -VMHost $ESXHost

			# Grab the major host version
			$esxmajor = $esxcli.system.version.get.invoke().version
			
			# Grab the update version
			$esxupdate = $esxcli.system.version.get.invoke().update
		
		        # Make sure a version 6.5.0 host is being checked
			If ($esxmajor -ge "6.5.0") {
			
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
			} else {
				# Show that the host is already set to the value requested
				Write-Host "$ESXhost is not 6.5 or higher"
			}	
		}

}
