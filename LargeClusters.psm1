<#==========================================================================
Script Name: LargeClusters.psm1
Created on: 12/19/2018 
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

To use this module, Use Import-Module <path>/LargeClusters.psm1
#>

Function RebootVsanNode {

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)][string]$EsxHost,
  [Parameter(Mandatory=$False)][ValidateSet("Full","EnsureAccessibility")][string]$DataMigration
)

    Write-Host " " 
    Write-Host "Performing a reboot of $EsxHost" -ForegroundColor "DarkGreen"

    # Get the Cluster Object
    $Cluster = (Get-VMHost $EsxHost).Parent

    # Get a list of the VM's on $EsxHost
    $EsxHostGuests = Get-VM -Location $EsxHost

    If ((Get-VM -Location $EsxHost).Count -gt 0) {
        # Determine if the Cluster has DRS Enabled and is ste to Fully Automated
        If (($Cluster.DrsEnabled -eq $True) -and ($Cluster.DrsAutomationLevel -eq 'FullyAutomated')) {

            # Everything is good to go. Running VM's 'should' move off of $EsxHost automatically
            Write-Host "------ "$EsxHostGuests.Count"VMs will be evacuated from $EsxHost when put into Maintenance Mode because DRS is enabled & set to FullyAutomated"

        } else {

            # DRS is either disabled or not fully automated, VM's will have to be moved off of the host
            Write-Host "------ Evacuate any virtual machines from $EsxHost" 
            Write-Host "     |--- "$EsxHostGuests.Count"VMs must be evacuated from $EsxHost " -ForegroundColor "DarkYellow"
            Write-Host "           because DRS is either not enabled or it is not set to FullyAutomated" -ForegroundColor "DarkYellow"

            # Find hosts other than $EsxHost that are connected and available
            $ConnectedHosts = $Cluster | Get-VMHost |  Where-Object {$_.Name -ne $EsxHost -and $_.ConnectionState -eq "Connected"}
            #Write-Host "Connected Hosts:" $ConnectedHosts

            If ($EsxHostGuests.Count -gt 0) {

                # Loop through the VM's in the list. If they are on $EsxHost, move them to a random alternate host
                # DRS would be advantageous here for better uniform utilization across the cluster.
                Foreach ($EsxHostGuest in $EsxHostGuests) {

                        # Get a random host to move the VM to
                        $AvailableHost = $ConnectedHosts | Get-Random

                        # Move the VM to the random host
                        Write-Host "     |--- Moving $EsxHostGuest to $AvailableHost" -ForegroundColor "Green"
                        Move-VM $EsxHostGuest -Destination $AvailableHost -Confirm:$false -RunAsync:$true | Out-Null
                }

                Write-Host "     |--- Waiting for all VM's to evacuate $EsxHost" -ForegroundColor "DarkYellow"

                While ((Get-VM -Location $EsxHost).Count -gt 0) {
                    Sleep 1
                    Write-Host "." -NoNewline
                }
                Write-Host " "
                Write-Host "     |--- "$EsxHostGuests.Count" VMs have been moved off of $EsxHost" -ForegroundColor "Green"
            }
        }

    } else {
        Write-Host "|"
        Write-Host "------ Evacuate the Host of VMs and put it in Maintenance Mode            " -ForegroundColor "White"
        Write-Host "     |--- " -NoNewLine 
        Write-Host "No VM's on $EsxHost, proceeding to put the host in Maintenance Mode  " -ForegroundColor "Green"
    }

    # Make sure there are no resyncs going on in the environment
    $VsanResyncs = Get-VsanResyncingComponent -Cluster $Cluster

    If ($VsanResyncs) {
        Write-Host "     |--- " -NoNewLine
        Write-Host "Waiting on vSAN Resyncs to complete" -ForegroundColor "DarkYellow" 

        While ((Get-VsanResyncingComponent -Cluster $Cluster)) {
            Write-Host "." -ForegroundColor "DarkYellow" -NoNewline
        }
        
        Write-Host ""

    } else {
        Write-Host "     |--- No vSAN Resyncs being performed" -ForegroundColor "Green" 
    }


    
    # Put server in maintenance mode
    Write-Host "|"
    Write-Host "------ Putting $EsxHost into Maintenance Mode                      " -ForegroundColor "White"

    # Invoke Maintenance Mode for $EsxHost 
    If (-Not ($DataMigration)) {
        $DataMigration = "EnsureAccessibility"
    } 

    Set-VMHost -VMHost $ESXHost –State “Maintenance” –VsanDataMigrationMode $DataMigration | Out-Null

    While ((Get-VMHost $EsxHost).ConnectionState -ne "Maintenance") {
        Write-Host "." -NoNewline
    }

    Write-Host "     |--- $EsxHost is now in Maintenance Mode" -ForegroundColor "Green"

    # Reboot $EsxHost
    Write-Host "|"
    Write-Host "------ Rebooting $EsxHost" -ForegroundColor "White"
    Write-Host "     |--- $EsxHost is rebooting" -ForegroundColor "DarkYellow" -NoNewline    
    Restart-VMHost $EsxHost -Confirm:$false | Out-Null
    
    While (((Get-VMHost $EsxHost).ConnectionState) -ne "NotResponding") {
        Sleep 1
        Write-Host "." -NoNewline         
    }
    Write-Host " "
    Write-Host "     |--- $EsxHost is offline " -ForegroundColor "Red" -NoNewline

    While (((Get-VMHost $EsxHost).ConnectionState) -eq "NotResponding") {
        Sleep 1
        Write-Host "." -NoNewline 
    }
    Write-Host ""
    Write-Host "     |--- $EsxHost is back online and will exit Maintenance Mode shortly" -ForegroundColor "DarkYellow"

    While (((Get-VMHost $EsxHost).ConnectionState) -ne "Maintenance") {
        Sleep 1
        Write-Host "." -NoNewline    
    }
        
    # Exit maintenance mode
    Write-Host "     |--- $EsxHost exiting Maintenance mode"
    Set-VMhost $EsxHost -State Connected | Out-Null

    While (((Get-VMHost $EsxHost).ConnectionState) -ne "Connected") {
        Sleep 1
    }
    Write-Host ""
    Write-Host "     |--- Reboot of $EsxHost complete" -ForegroundColor "Green"
    Write-Host " "
}

Function Set-VsanLargeClusterSupport {
<#---
    .SYNOPSIS
    This function will go through each host in a designated cluster and enable or disable Large Cluster Support

    .DESCRIPTION
    This function will go through each host in a designated cluster and enable or disable Large Cluster Support

    .PARAMETER ClusterName
    The Cluster to modify

    .PARAMETER LargeClusterSupport
    Enable/Disable Large Cluster Support

    .PARAMETER DataMigration 
    Set the Data Migration Mode for vSAN Nodes that are put in Maintenance Mode - Valid values are "Full" or "EnsureAccessibility"

    .EXAMPLE To Set Large Cluster Support 
    Set-VsanLargeCluserSupport -ClusterName <ClusterName> -LargeClusterSupport $true

    .EXAMPLE To Disable Large Cluster Support
    Set-VsanLargeCluserSupport -ClusterName <ClusterName> -LargeClusterSupport $false

    .NOTES This is only applicable to ESXi hosts with Virtual SAN 6.2 or greater
#>

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)][string]$ClusterName,
  [Parameter(Mandatory=$True)][Boolean]$LargeClusterSupport,
  [Parameter(Mandatory=$False)][ValidateSet("Full","EnsureAccessibility")][string]$DataMigration
)

# Get the Cluster Name
$Cluster = Get-Cluster -Name $ClusterName

# Display the Cluster
Write-Host Cluster: $($Cluster.name)

    # If the Cluster has VSAN Enabled, then proceed
    if ($Cluster.VsanEnabled){ 

        # Cycle through each ESXi Host in the cluster
        Foreach ($ESXHost in ($Cluster |Get-VMHost |Sort-Object Name)){

            # Grab EsxCLI content to check for proper host version
            $esxcli = Get-EsxCli -VMHost $ESXHost -V2

            # Write the name of the current host
            Write-Host "Configuring Large Cluster Support for $EsxHost"
                
            # Setup our Advanced Arguments for the EsxCli object
            $GetAdvancedArgs = $EsxCli.system.settings.advanced.list.CreateArgs()
            $SetAdvancedArgs = $EsxCli.system.settings.advanced.set.CreateArgs()

            # Get the current setting for 'Increased Node Support'
            $GetAdvancedArgs.option = "/VSAN/goto11"
            $IncreasedNodeSupport = $esxcli.system.settings.advanced.list.Invoke($GetAdvancedArgs)

            # Get the current setting for 'TCP/IP Heap Size'
            $GetAdvancedArgs.option = "/Net/TcpipHeapMax"
            $TcpipHeapMax = $esxcli.system.settings.advanced.list.Invoke($GetAdvancedArgs)

            # Perform Different Actions Based on Whether We're Enabling/Disabling Large Cluster Support
            Switch ($LargeClusterSupport) {
                $true {

                    # Set 'Increased Node Support' if it is not already
                    If ($IncreasedNodeSupport.intvalue -ne "1") {
                        Write-Host "|"
                        Write-Host "------ Enabling Increased Node Support' for $EsxHost" -ForegroundColor "White"

                        $SetAdvancedArgs.option = "/VSAN/goto11"
                        $SetAdvancedArgs.intvalue = "1"
                        $esxcli.system.settings.advanced.set.Invoke($SetAdvancedArgs)
                        $RebootRequired = $true
                    } else {
                    # Do nothing if this is already set
                        Write-Host "|"
                        Write-Host "------ $EsxHost already setup for 'Increased Node Support'" -ForegroundColor "Green"
                    }

                    # Set 'Tcpip Heap Max' if it is not already
                    If (($TcpipHeapMax.IntValue -ne $TcpipHeapMax.MaxValue)) {
                        Write-Host "------ Adjusting TCP/IP Heap Max value' for $EsxHost" -ForegroundColor "White"
                        $SetAdvancedArgs.option = "/Net/TcpipHeapMax"
                        $SetAdvancedArgs.intvalue = $TcpipHeapMax.MaxValue
                        $esxcli.system.settings.advanced.set.Invoke($SetAdvancedArgs)
                        $RebootRequired = $true
                    } else {
                    # Do nothing if this is already set
                        Write-Host "------ $EsxHost already setup for correct 'TCP/IP Heap Size" -ForegroundColor "Green"
                    }
                }
                
                $false {

                    # Disable 'Increased Node Support' if it is set
                    If ($IncreasedNodeSupport.intvalue -ne "0") {
                        Write-Host "------ Disabling Increased Node Support' for $EsxHost" -ForegroundColor "White"
                        $SetAdvancedArgs.option = "/VSAN/goto11"
                        $SetAdvancedArgs.intvalue = "0"
                        $esxcli.system.settings.advanced.set.Invoke($SetAdvancedArgs)
                        $RebootRequired = $true
                    } else {
                    # Do nothing if it is already set
                        Write-Host "------ $EsxHost isn't setup for 'Increased Node Support'" -ForegroundColor "Green"
                    }
                
                    # Return 'Tcpip Heap Max' to the default setting if it is not already
                    If (($TcpipHeapMax.IntValue -ne $TcpipHeapMax.defaultintvalue)) {
                        Write-Host "------ Adjusting TCP/IP Heap Max value' for $EsxHost" -ForegroundColor "White"
                        $SetAdvancedArgs.option = "/Net/TcpipHeapMax"
                        $SetAdvancedArgs.intvalue = $TcpipHeapMax.defaultintvalue
                        $esxcli.system.settings.advanced.set.Invoke($SetAdvancedArgs)
                        $RebootRequired = $true
                    } else {
                    # Do nothing if it is already set
                        Write-Host "------ $EsxHost already setup for the default 'TCP/IP Heap Size" -ForegroundColor "Green"
                    }
                }
            }

            If ($RebootRequired -eq $true) {
                # Reboot the ESXi Host
                Write-Host "Reboot Required for $EsxHost"

                # If the Data Migration Mode is specified, honor it.
                If ($DataMigration) {
                    RebootVsanNode -EsxHost $ESXHost -DataMigration $DataMigration
                } 
                    RebootVsanNode -EsxHost $ESXHost
            }
        }
			  
    } 
}
