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
Vsan-SetTsoLro.ps1 vCenter <vCenterName> -ClusterName <ClusterName> -TSOLRO <enable/disable>

.Notes

#>

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)]
  [string]$vCenter,

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
	
Connect-VIServer $vCenter

# Get the Cluster Name
$Cluster = Get-Cluster -Name $ClusterName

    # Display the Cluster
    Write-Host Cluster: $($Cluster.name)
    
    # Check to make sure we are dealing with a vSAN cluster
    # Uncomment this If block if only using on a vSAN cluster
    #If($Cluster.VsanEnabled){

        # Cycle through each ESXi Host in the cluster
    	Foreach ($ESXHost in ($Cluster |Get-VMHost |Sort Name)){
		
		$TSOState  = Get-AdvancedSetting -Entity $ESXHost -Name "Net.UseHwTSO"
		$TSO6State = Get-AdvancedSetting -Entity $ESXHost -Name "Net.UseHwTSO6"
		$LROState  = Get-AdvancedSetting -Entity $ESXHost -Name "Net.TcpipDefLROEnabled"

		# Display the Host this is being performed on
		Write-Host "Host:" $ESXHost
			
		If($TSOState.value -ne $TSOLROVALUE){
			# Show that host is being updated
			Write-Host "On $ESXHost $TSOLROTEXT" -foregroundcolor red -backgroundcolor white
			$TSOState | Set-AdvancedSetting -Value $TSOLROVALUE -Confirm:$false
			Write-Host "A reboot of host $ESXHost is required for the UseHwTSO setting change to take effect" -foregroundcolor white -backgroundcolor red
		} 
		If($TSO6State.value -ne $TSOLROVALUE){
			# Show that host is being updated
			Write-Host "On $ESXHost $TSOLROTEXT" -foregroundcolor red -backgroundcolor white
			$TSO6State | Set-AdvancedSetting -Value $TSOLROVALUE -Confirm:$false
			Write-Host "A reboot of host $ESXHost is required for the UseHwTSO6 setting change to take effect" -foregroundcolor white -backgroundcolor red
		} 
		If($LROState.value -ne $TSOLROVALUE){
			# Show that host is being updated
			Write-Host "On $ESXHost $TSOLROTEXT" -foregroundcolor red -backgroundcolor white
			$LROState | Set-AdvancedSetting -Value $TSOLROVALUE -Confirm:$false
			Write-Host "A reboot of host $ESXHost is required for the TcpipDefLROEnabled setting change to take effect" -foregroundcolor white -backgroundcolor red
		} 

		Write-Host " "

    	}
		            
    #}
