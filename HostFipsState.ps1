Function Get-VMHostFipsState {
	<#
	.SYNOPSIS
	This function gets the FIPS 140-2 Current State
	.DESCRIPTION
  This function gets the FIPS 140-2 Current State
  .PARAMETER VMHost
	The ESXi hostname of the ESXi host
	.PARAMETER Service
  Which Service

	.EXAMPLE
	PS C:\> Get-VMHostFipsState -VMHost <VMHost> -Item <ssh/rhttpproxy/blank>

	.NOTES
	Author                                    : Jase McCarty
	Version                                   : 0.1
	==========Tested Against Environment==========
	VMware vSphere Hypervisor(ESXi) Version   : 6.7
	VMware vCenter Server Version             : 6.7
	PowerCLI Version                          : PowerCLI 10
	PowerShell Version                        : PowerShell Core 6.0.2
	#>
	
	# Set our Parameters
	[CmdletBinding()]Param(
	[Parameter(Mandatory=$true)][String]$VMHost,
	[Parameter(Mandatory=$false)][String]$Service
	)

    # Get the ESX Host
    $ESXHost = Get-VMHost -Name $VMHost

	# Create an EsxCli variable for the host
	$VMHostEsxCli = Get-EsxCli -VMHost $ESXHost -V2 
					
    # Get the current System/Security/FIPS140 State
    $FipsState = $VMHostEsxCli.system.security.fips140
    
    Switch ($Service) {
        "ssh" {
                If ($FipsState.ssh.get.invoke().enabled -eq $true) {
                    Write-Host "Host $VMHost has FIPS 140-2 Mode Enabled for SSH" -ForegroundColor "Green"
                } else {
                    Write-Host "Host $VMHost does not have FIPS 140-2 Mode Enabled for SSH" -ForegroundColor "Red"
                }
            }
            "rhttpproxy" {
                If ($FipsState.rhttpproxy.get.invoke().enabled -eq $true) {
                    Write-Host "Host $VMHost has FIPS 140-2 Mode Enabled for rhttpproxy" -ForegroundColor "Green"
                } else {
                    Write-Host "Host $VMHost does not have FIPS 140-2 Mode Enabled for rhttpproxy" -ForegroundColor "Red"
                }
            }
            default {
                If ($FipsState.ssh.get.invoke().enabled -eq $true) {
                    Write-Host "Host $VMHost has FIPS 140-2 Mode Enabled for SSH" -ForegroundColor "Green"
                } else {
                    Write-Host "Host $VMHost does not have FIPS 140-2 Mode Enabled for SSH" -ForegroundColor "Red"
                }
                If ($FipsState.rhttpproxy.get.invoke().enabled -eq $true) {
                    Write-Host "Host $VMHost has FIPS 140-2 Mode Enabled for rhttpproxy" -ForegroundColor "Green"
                } else {
                    Write-Host "Host $VMHost does not have FIPS 140-2 Mode Enabled for rhttpproxy" -ForegroundColor "Red"
                }
            }
    }
}
