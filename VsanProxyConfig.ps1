Function Get-VsanProxyConfig {

    <#
    .SYNOPSIS
    Get the Proxy Configurations for vSAN Clusters attached to vCenter

    .DESCRIPTION
    Get the Proxy Configurations for vSAN Clusters attached to vCenter
    
    .PARAMETER Cluster
    The name of the vSAN Cluster 

    .EXAMPLE
    PS C:\> Get-VsanProxyConfig -Cluster "ClusterName"

    .NOTES
    Author                                    : Jase McCarty
    Version                                   : 0.1
    Requires                                  : PowerCLI 11.0 or Higher
#>

# Set Parameters
[CmdletBinding()]Param([Parameter(Mandatory=$true)][String]$Cluster)

# Get the Cluster Object
$VsanCluster = Get-Cluster -Name $Cluster

# Setup the vSAN View
$vchs = Get-VsanView -Id VsanVcClusterHealthSystem-vsan-cluster-health-system

Write-Host "   "

# Write which cluster we are working on
Write-Host "vSAN Proxy Information for Cluster:" $Cluster

# Return the VsanTelemetry Proxy Information
$vchs.VsanHealthQueryVsanClusterHealthConfig($VsanCluster.ExtensionData.MoRef).VsanTelemetryProxy

# Return whether it is enabled or not
$VsanProxyEnabled = $vchs.VsanHealthQueryVsanClusterHealthConfig($VsanCluster.ExtensionData.MoRef).EnableVsanTelemetry

Write-Host "vSAN Proxy Enabled:"$VsanProxyEnabled
}


Function Set-VsanProxyConfig {

    <#
    .SYNOPSIS
    Get the Proxy Configurations for vSAN Clusters attached to vCenter

    .DESCRIPTION
    Get the Proxy Configurations for vSAN Clusters attached to vCenter
    
    .PARAMETER Cluster
    The name of the vSAN Cluster 

    .PARAMETER ProxyUser
    The name of the vSAN Cluster 

    .PARAMETER ProxyPass
    The name of the vSAN Cluster 

    .PARAMETER ProxyHost
    The name of the vSAN Cluster 

    .PARAMETER ProxyPort
    The name of the vSAN Cluster 

    .PARAMETER ProxyEnabled
    The name of the vSAN Cluster 

    .EXAMPLE
    PS C:\> Get-VsanProxyConfig -Cluster "ClusterName"

    .NOTES
    Author                                    : Jase McCarty
    Version                                   : 0.1
    Requires                                  : PowerCLI Desktop 6.5 or higher
#>

# Set Parameters
[CmdletBinding()]Param(
    [Parameter(Mandatory=$true)][String]$Cluster,
    [Parameter(Mandatory=$true)][String]$ProxyUser,
    [Parameter(Mandatory=$true)][String]$ProxyPass,
    [Parameter(Mandatory=$true)][String]$ProxyHost,
    [Parameter(Mandatory=$true)][String]$ProxyPort,
    [Parameter(Mandatory=$false)][Boolean]$ProxyEnabled
)

# Get the Cluster Object
$VsanCluster = Get-Cluster -Name $Cluster

# Setup the vSAN View
$vchs = Get-VsanView -Id VsanVcClusterHealthSystem-vsan-cluster-health-system

Write-Host "   "

# Write which cluster we are working on
Write-Host "Setting the vSAN Proxy Information for Cluster:" $Cluster

# Configure the variable for the vSAN Telemetry Proxy
$VsanTelemetryProxy = New-Object -TypeName VMware.Vsan.Views.VsanClusterTelemetryProxyConfig
$VsanTelemetryProxy.Host     = $ProxyHost
$VsanTelemetryProxy.Password = $ProxyPass
$VsanTelemetryProxy.User     = $ProxyUser
$VsanTelemetryProxy.Port     = $ProxyPort 

# Configure the variable for the vSAN Health Configuration
$VsanClusterConfig = New-Object -Type VMware.Vsan.Views.VsanClusterHealthConfigs 
$VsanClusterConfig.VsanTelemetryProxy = $VsanTelemetryProxy

# If the state differs from the $ProxyEnabled parameter, change it
If ($ProxyConfigEnabled -ne $ProxyEnabled) {
    $VsanClusterConfig.EnableVsanTelemetry = $ProxyEnabled
}

# Update the proxy configuration
$vchs.VsanHealthSetVsanClusterTelemetryConfig($VsanCluster.ExtensionData.MoRef,$VsanClusterConfig)

}

#Example to get the vSAN Proxy
Get-VsanProxyConfig -Cluster "Cluster"

#Example to set the vSAN Proxy
Set-VsanProxyConfig -Cluster "Cluster" -ProxyUser "fred" -ProxyPass "VMware1!" -ProxyHost "proxy.vmware.com" -ProxyPort "8080" -ProxyEnabled $True
