<#==========================================================================
Script Name: Vsan-SetTsoLro.ps1
Created on: 12/15/2016 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script sets TSO/LRO Settings for Physical NICs

KB 2126909 
PSOD w/ESXi 5.x/6.5 when using Intel X710 NICs
https://kb.vmware.com/kb/2126909

Syntax is:
To enable/disable TSO/LRO on pNics
Vsan-SetTsoLro.ps1 -VIServer <vCenter/ESXiHost> -TSOLRO <enable/disable> -ClusterName <ClusterName>

.Notes

#>

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)]
  [string]$VIServer,

  [Parameter(Mandatory=$False)]
  [string]$ClusterName,

  [Parameter(Mandatory = $true)]
  [ValidateSet('enable','disable')]
  [String]$TSOLRO

)

# Check to ensure we have either enable or disable, and set our values/text
Switch ($TSOLRO) {
	"disable" { 
		$TSOLROVALUE = "0"
		$TSOLROTEXT  = "TSO/LRO is Disabled"
		}
	"enable" {
		$TSOLROVALUE = "1"
		$TSOLROTEXT  = "TSO/LRO is Enabled" 
		}
	default {
		write-host "Please include the parameter -TSOLRO enable or -TSOLRO disabled"
		exit
		}
	}
	
function SetTsoLro{
Param ([string]$ESXHost,[String]$TSOLRO)

				# Get the Host
				$ESXHost = $VIServer 
				
				$TSOState  = Get-AdvancedSetting -Entity $ESXHost -Name "Net.UseHwTSO"
				$TSO6State = Get-AdvancedSetting -Entity $ESXHost -Name "Net.UseHwTSO6"
				$LROState  = Get-AdvancedSetting -Entity $ESXHost -Name "Net.TcpipDefLROEnabled"

				# Display the Host this is being performed on
				Write-Host "Host:" $ESXHost

				# If any of these are set to the opposite, toggle the setting
				If($TSOState.value -ne $TSOLROVALUE -or $TSO6State.value -ne $TSOLROVALUE -or $LROState.value -ne $TSOLROVALUE){
					# Show that host is being updated
					Write-Host "On $ESXHost $TSOLROTEXT" -foregroundcolor red -backgroundcolor white
					$TSOState | Set-AdvancedSetting -Value $TSOLROVALUE -Confirm:$false
					$TSO6State | Set-AdvancedSetting -Value $TSOLROVALUE -Confirm:$false
					$LROState | Set-AdvancedSetting -Value $TSOLROVALUE -Confirm:$false
					Write-Host "A reboot of host $ESXHost is required for the updates to take effect" -foregroundcolor white -backgroundcolor red 
				} 
				
				Write-Host " "

}

	
Connect-VIServer $VIServer

# Grab the VIServer Type. "vpx"  is vCenter. ESXi may be embeddedEsx or similar.
$VIServerType = $defaultviserver.ProductLine

# Depending on the which we've connected to, we'll want to operate differently
Switch ($VIServerType) {
		# If the VIServer Type is "vpx" we've connected to vCenter
		"vpx" {
		
			# If the ClusterName parameter was passed, proceed
			If($ClusterName){
				# Get the Cluster Name
				$Cluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue
				
				# Display the Cluster
				Write-Host Cluster: $($Cluster.name)
			
				# Cycle through each ESXi Host in the cluster
				Foreach ($ESXHost in ($Cluster |Get-VMHost |Sort Name)){
		
					# Execute the funtion to get/set the TSO/LRO settings
					SetTsoLro -ESXHost $ESXHost -TSOLRO $TSOLRO
		
				}
			# If the ClusterName parameter was not passed, don't proceed.
			} else {
				Write-Host "When connected to a vCenter Server, a Cluster Name is required" -foregroundcolor red -backgroundcolor white
				Write-Host "Please rerun this script with the -ClusterName parameter" -foregroundcolor red -backgroundcolor white
				Exit
			}
		}
		# If not connecting to a vCenter Server, simply run the function against the host
		default {

				# Execute the funtion to get/set the TSO/LRO settings
				SetTsoLro -ESXHost $ESXHost -TSOLRO $TSOLRO
		
		
		}

}
