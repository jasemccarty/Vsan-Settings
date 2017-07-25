<#==========================================================================
Script Name: Vsan-EncryptionReport.ps1
Created on: 7/20/2017 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script will perform a basic vSAN Encryption Report
This requires PowerCLI 6.5.1 and has been tested on vSAN 6.6

.SYNTAX
Vsan-EncryptionReport.ps1 -vCenter <VCENTER> -ClusterName <CusterName>

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
  [String]$Password

)
# Connect to vCenter Server
Connect-VIServer $vCenter -user $User -password $Password

# Get the Cluster Object for the Cluster Specified
$Cluster = Get-Cluster -Name $ClusterName

# Setup our VsanView objects 
# vSAN Cluster Configuration
$VVCC = Get-VsanView -Id "VsanVcClusterConfigSystem-vsan-cluster-config-system"
# vSAN Cluster Health
$VCHS = Get-VsanView -Id VsanVcClusterHealthSystem-vsan-cluster-health-system

#Setup some reporting placeholders
$BadDiskCount=0;$GoodDiskCount=0;$BadHostCount=0;$GoodHostCount

# Get Encryption State
$EncryptedVsan = $VVCC.VsanClusterGetConfig($Cluster.ExtensionData.MoRef).DataEncryptionConfig

# If vSAN is enabled and it is Encrypted
If($Cluster.vSanEnabled -And $EncryptedVsan.EncryptionEnabled){
	
  # Echo task being performed
  Write-Host "$Cluster is Encrypted"

  #Grab our Encryption Health Information
  $EncryptionHealth = $VCHS.VsanQueryVcClusterHealthSummary($Cluster.ExtensionData.MoRef,$null,$null,$null,@('encryptionHealth'),$null,"defaultView").EncryptionHealth 
  
  #Print the basics
  Write-Host "vSAN Encryption Results"
  Write-Host "*******************************************************************"
  Write-Host "Overall/Config" 
  Write-Host "Overall Health:                        " $EncryptionHealth.OverallHealth -foregroundcolor $EncryptionHealth.OverallHealth
  Write-Host "Config Health:                         " $EncryptionHealth.ConfigHealth -foregroundcolor $EncryptionHealth.ConfigHealth
  Write-Host "*******************************************************************"

  #Print KMS Health Info overall
  Write-Host "KMS"
  Write-Host "KMS Health:                            " $EncryptionHealth.KmsHealth -foregroundcolor $EncryptionHealth.KmsHealth  

  #Print vCenter KMS Health Info overall 
  Write-Host "*******************************************************************"
  Write-Host "vCenter Results"
  Write-Host "vCenter KMS Provider:                       " $EncryptionHealth.VcKmsResult.KmsProviderId -foregroundcolor $EncryptionHealth.VcKmsResult.Health
  Write-Host "vCenter KMS Health:                         " $EncryptionHealth.VcKmsResult.Health -foregroundcolor $EncryptionHealth.VcKmsResult.Health
  Write-Host "vCenter KMS Client Certificate Health:      " $EncryptionHealth.VcKmsResult.ClientCertHealth -foregroundcolor $EncryptionHealth.VcKmsResult.ClientCertHealth 
  Write-Host "vCenter KMS Client Certificate Expire Date: " $EncryptionHealth.VcKmsResult.ClientCertExpireDate -foregroundcolor $EncryptionHealth.VcKmsResult.ClientCertHealth 

  #Print Host Results
  Write-Host "*******************************************************************"  
  Write-Host "Host Results"

  #Enumerate Host Results and sort by the Hostname   
  Foreach ($VsanHost in $EncryptionHealth.HostResults | Sort-Object Hostname) {
  
	$HostError=$false
	Write-Host "    "$VsanHost.Hostname -foregroundcolor $VsanHost.OverallKmsHealth
	
	#Print Host Overall KMS Health - Good for determining issues with Host/KMS connectivity
	If ($VsanHost.OverallKmsHealth -eq "green") {
		Write-Host "     Overall KMS Health:            " $VsanHost.OverallKmsHealth -foregroundcolor $VsanHost.OverallKmsHealth

		} else {
		Write-Host "     Overall KMS Health:            " $VsanHost.OverallKmsHealth -foregroundcolor $VsanHost.OverallKmsHealth
		Write-Host "                  Issue:            " $VsanHost.EncryptionIssues -foregroundcolor $VsanHost.OverallKmsHealth
		$HostError = $True
		}
	#Print AES-NI state
	If ($VsanHost.Aesnienabled -eq $true) {
		Write-Host "     AES-NI Enabled:                " $VsanHost.Aesnienabled -foregroundcolor green
	} else {
		Write-Host "     AES-NI Enabled:                " $VsanHost.Aesnienabled -foregroundcolor red
		$HostError = $True
	}
	
	Write-Host "     *******************************************************************"  
		
	# Grab our disk results per host
	$DiskResults = ($EncryptionHealth.HostResults |Where-Object {$_.Hostname -eq $VsanHost.Hostname}).DiskResults
	# Print the total number of vSAN disks available (locked disks with not be returned)
	Write-Host "     "$DiskResults.Count" Total Disks" 

	# Determine how many disks have zero encryption issues
	$DiskResultsNI =  $DiskResults |Where-Object {$_.EncryptionIssues -eq $null}

	# Determine how many disks have encryption issues
	$DiskResultsEI =  $DiskResults |Where-Object {$_.EncryptionIssues -ne $null}
 
	# Enumerate the disks that do not have any encryption issues
	If ($DiskResultsNI.Count -gt 0) {
		Write-Host "     "$DiskResultsNI.Count" Disks without Encryption Issues" 
		Write-Host " 	 DekGenerationID  Name"
		Foreach ($DiskHealthNI in $DiskResultsNI) {
			Write-Host "        "$DiskHealthNI.DiskHealth.DekGenerationID"              "$DiskHealthNI.DiskHealth.Name -foregroundcolor green
			$GoodDiskCount=$GoodDiskCount+1
		}
	}		
	
	
	# Enumerate the disks that have any encryption issues
	If ($DiskResultsEI.Count -gt 0) {
		Write-Host "     "$DiskResultsEI.Count" Disks with Encryption Issues" 
		Write-Host " 	 DekGenerationID  Name                       Encryption Issue"
		$HostError=$true
		Foreach ($DiskHealthEI in $DiskResultsEI) {
			Write-Host "        "$DiskHealthEI.DiskHealth.DekGenerationID"              "$DiskHealthEI.DiskHealth.Name "     "  $DiskHealthEI.EncryptionIssues -foregroundcolor red 
			$BadDiskCount=$BadDiskCount+1
			}
	}		
	If ($HostError -eq $true) {
		$BadHostCount = $BadHostCount+1 
	} else {
		$GoodHostCount = $GoodHostCount+1
	}
	Write-Host "     *******************************************************************" 


  }	
	Write-Host "     *******************************************************************" 
	Write-Host "     Summary" 
	Write-Host "     *******************************************************************" 
  
  Write-Host "     Total Hosts with issues:                  " $BadHostCount -foregroundcolor red
	Write-Host "     Total Hosts without issues:               " $GoodHostCount -foregroundcolor green
	Write-Host "     Total Disks with issues:                  " $BadDiskCount -foreground red
	Write-Host "     Total Disks without issues:               " $GoodDiskCount -foreground green
}
