<#==========================================================================
Script Name: Set-PnicTsoLro.ps1
Created on: 12/15/2016 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script sets TSO/LRO Settings for Physical Nics

Syntax is:
To enable/disable TSO/LRO on pNics
Set-PnicTsoLro.ps1 -ClusterName <ClusterName> -TSOLRO <enable/disable>

.Notes

#>

# Set our Parameters
[CmdletBinding()]Param(


  [Parameter(Mandatory=$True)]
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
	
#Connect-VIServer $vCenter

# Get the Cluster Name
$Cluster = Get-Cluster -Name $ClusterName

    # Display the Cluster
    Write-Host Cluster: $($Cluster.name)
    
    # Check to make sure we dealing with a vSAN cluster
    If($Cluster.VsanEnabled){

        # Cycle through each ESXi Host in the cluster
    	Foreach ($ESXHost in ($Cluster |Get-VMHost |Sort Name)){
		
			$TSOState = Get-AdvancedSetting -Entity $ESXHost -Name "Net.UseHwTSO"
			$LROState = Get-AdvancedSetting -Entity $ESXHost -Name "Net.TcpipDefLROEnabled"

			Write-Host "Host:" $ESXHost
			#Write-Host "TSO $TSOState.Value"
			#Write-Host "LRO $LROState.Value"
			
			If($TSOState.value -ne $TSOLROVALUE){

				# Show that host is being updated
				Write-Host "On $ESXHost $TSOLROTEXT" -foregroundcolor red -backgroundcolor white
				$TSOState | Set-AdvancedSetting -Value $TSOLROVALUE -Confirm:$false
				$LROState | Set-AdvancedSetting -Value $TSOLROVALUE -Confirm:$false 
				
				Write-Host "A reboot of host $ESXHost is required for these settings to take effect" -foregroundcolor white -backgroundcolor red

            } else {

				# Show that the host is already set for the right value
				Write-Host "On $ESXHost $TSOLROTEXT already" -foregroundcolor black -backgroundcolor green
			
			}
			Write-Host " "

		}
		            
    }
