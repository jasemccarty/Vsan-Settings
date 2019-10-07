Function Set-VsanClusterLicense {

    <#
    .SYNOPSIS
    Set the assigned license for a vSAN Cluster

    .DESCRIPTION
    Set the assigned license for a vSAN Cluster

    .PARAMETER License
    The vSAN license to apply to the cluster
    
    .PARAMETER Cluster
    The Type of Controller to change to  

    .EXAMPLE
    PS C:\> Set-VsanClusterLicense -License "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX" -Cluster "ClusterName"

    .NOTES
    Author                                    : Jase McCarty
    Version                                   : 0.1
    Requires                                  : PowerCLI Desktop 6.5 or higher
#>

# Set Parameters
[CmdletBinding()]Param(
[Parameter(Mandatory=$true)][String]$License,
[Parameter(Mandatory=$true)][String]$Cluster)

# Get the License Manager View and assign it to the LicenseManager variable
$LicenseManager = Get-View $global:DefaultVIServer.ExtensionData.Content.LicenseManager

# Get the LicenseAssignmentManager so a license can be assigned
$LicenseAssignmentManager= Get-View $LicenseManager.LicenseAssignmentManager

# Get the Managed Object Reference for the vSAN Cluster so the license can be applied to it.
$ClusterComputeResource = (Get-Cluster -Name $Cluster | Get-View)

# Retrieve a list of the current vSAN licenses added to vCenter
$CurrentVsanLicenses = $LicenseManager.Licenses | Where-Object {$_.EditionKey -like "vsan.*"}

# Determine whether the license is already present or not in vCenter
if ($License -in $CurrentVsanLicenses.LicenseKey) {
    # Already present, so good
    Write-Host "$License License Already Present in vCenter"
    
    } else {
    # Not present, so we need to add it to vCenter
    Write-Host "$License being added to vCenter"
    $LicenseManager.AddLicense($License,$null)
    }
# Assign the license to the vSAN Cluster 
$LicenseAssignmentManager.UpdateAssignedLicense($ClusterComputeResource.Moref.value,$License,"vSAN")

}

Set-VsanClusterLicense -License "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX" -Cluster "ClusterName"
