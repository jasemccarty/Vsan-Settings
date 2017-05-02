<#==========================================================================
Script Name: Vsan-EncryptionRekey.ps1
Created on: 5/2/2017 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script will go through each host in a designated cluster and 
set /VSAN/SwapThickProvisionDisabled to either Thin or Space Reserved (Thick)

This requires PowerCLI 6.5.1 and has been tested on vSAN 6.6

.SYNTAX
Vsan-EncryptionRekey.ps1 -vCenter <VCENTER> -ClusterName <CusterName> -ReKey <shallow,deep> -ReducedRedundancy <enable>

#>

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)]
  [string]$vCenter,

  [Parameter(Mandatory = $True)]
  [String]$ClusterName,

  [Parameter(Mandatory = $False)]
  [String]$User,

  [Parameter(Mandatory = $False)]
  [String]$Password,

  [Parameter(Mandatory = $True)]
  [ValidateSet('shallow','deep')]
  [String]$ReKey,
  
  [Parameter(Mandatory = $false)]
  [ValidateSet('enable')]
  [String]$ReducedRedundancy
  
)
# Make sure that the ReKey action is specified
Switch ($ReKey) {
	"shallow" { 
		$RekeyAction = $false
		$RekeyText  = "Default (local) Read Caching"
		$RR = $false
		}
	"deep" {
		$RekeyAction = $true
		$RekeyText  = "Forced Warm Cache" 
		If ($ReducedRedundancy -eq "enabled") {
			$RR = $true }
		else {
			$RR = $false
			}
		}
	default {
		write-host "Please include the parameter -REKEY shallow or -REKEY deep"
		exit
		}
	}

# Connect to vCenter Server
#Connect-VIServer $vCenter -user $User -password $Password

# Get the Cluster 
$Cluster = Get-Cluster -Name $ClusterName

# Get the vSAN Cluster Configuration
$VsanVcClusterConfig = Get-VsanView -Id "VsanVcClusterConfigSystem-vsan-cluster-config-system"

# Get Encryption State
$EncryptedVsan = $VsanVcClusterConfig.VsanClusterGetConfig($Cluster.ExtensionData.MoRef).DataEncryptionConfig

# If vSAN is enabled and it is Encrypted
If($Cluster.vSanEnabled -And $EncryptedVsan.EncryptionEnabled){
	
  # Echo task being performed
  Write-Host "Starting $ReKey ReKey of vSAN Cluster $Cluster"

  # Execute the rekeying task
	$ReKeyTask = $VsanVcClusterConfig.VsanEncryptedClusterRekey_Task($Cluster.ExtensionData.MoRef,$ReKeyAction,$RR)

}
