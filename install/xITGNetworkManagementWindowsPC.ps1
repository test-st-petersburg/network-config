#Requires -Version 5.0
#Requires -Modules PSDesiredStateConfiguration
#Requires -Modules cChoco
#Requires -Modules xComputerManagement
#Requires -Modules xHyper-V
#Requires -Modules xITGHyperV
#Requires -Modules xPendingReboot
#Requires -Modules xDownloadFile

configuration ITGNetworkManagementWindowsPC
{
    param
    (
        [string[]] $ComputerName = 'localhost',
        [string] $VirtualLabPath = ( Join-Path -Path $env:SystemDrive -ChildPath 'NetworkVirtualTestLab' ),
        [string] $MediaPath
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName cChoco
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xHyper-V
    Import-DscResource -ModuleName xITGHyperV
    Import-DSCResource -ModuleName xPendingReboot
    Import-DSCResource -ModuleName xDownloadFile

    if ( -not $MediaPath )
    {
        $MediaPath = Join-Path -Path $VirtualLabPath -ChildPath 'MasterVirtualHardDisks'
    }
    $VMsPath = Join-Path -Path $VirtualLabPath -ChildPath 'VMs'
    $VHDPath = Join-Path -Path $VirtualLabPath -ChildPath 'VMVirtualHardDisks'

    Node $ComputerName
    {

        #region common software

        cChocoInstaller choco
        {
            InstallDir = "${env:SystemDrive}\choco"
        }

        Environment chocolatelyInstall
        {
            Name = 'chocolatelyInstall'
            value = "${env:SystemDrive}\choco\bin"
            DependsOn = @('[cChocoInstaller]choco')
        }

        cChocoPackageInstaller VSCode
        {
            Name = 'vscode'
            DependsOn = @('[cChocoInstaller]choco')
        }

        cChocoPackageInstaller git
        {
            Name = 'git.install'
            DependsOn = @('[cChocoInstaller]choco')
        }

        cChocoPackageInstaller NodeJS
        {
            Name = 'nodejs'
            DependsOn = @('[cChocoInstaller]choco')
        }

        WindowsOptionalFeatureSet HyperV
        {
            Name = 'Microsoft-Hyper-V-All', 'Microsoft-Hyper-V-Tools-All'
            Ensure = 'Enable'
            NoWindowsUpdateCheck = $true
        }
        <#
		xPendingReboot PendingRebootAfterHyperVInstallation
		{
			Name = 'Check for a pending reboot after Hyper-V installation'
			SkipWindowsUpdate = $true
			SkipCcmClientSDK = $true
			DependsOn = @('[WindowsOptionalFeatureSet]HyperV')
		}
		LocalConfigurationManager
		{
			RebootNodeIfNeeded = $True
		}
		#>

        #endregion common software
        #region virtual lab folders

        File NetworkVirtualTestLabRoot
        {
            Type = 'Directory'
            DestinationPath = $VirtualLabPath
        }
        File NetworkVirtualTestLabMediaRoot
        {
            Type = 'Directory'
            DestinationPath = $MediaPath
            DependsOn = '[File]NetworkVirtualTestLabRoot'
        }
        File NetworkVirtualTestLabVMsRoot
        {
            Type = 'Directory'
            DestinationPath = $VMsPath
            DependsOn = '[File]NetworkVirtualTestLabRoot'
        }
        File NetworkVirtualTestLabVHDRoot
        {
            Type = 'Directory'
            DestinationPath = $VhdPath
            DependsOn = '[File]NetworkVirtualTestLabRoot'
        }

        #endregion virtual lab folders
        #region RouterOS image

        # TODO: добавить автоматическое определение текущей стабильной версии RouterOS
        $RouterOSVersion = '6.44.3'
        $RouterOSImageFileName = 'RouterOS.vhdx'
        $RouterOSImagePath = Join-Path -Path $MediaPath -ChildPath $RouterOSImageFileName
        xDownloadFile RouterOSImage
        {
            FileName = $RouterOSImageFileName
            SourcePath = "http://download2.mikrotik.com/routeros/$RouterOSVersion/chr-$RouterOSVersion.vhdx"
            # 'https://download.mikrotik.com/' требует дополнительных заголовков
            DestinationDirectoryPath = $MediaPath
            DependsOn = '[File]NetworkVirtualTestLabMediaRoot'
        }
        $RouterOSVhdMaximumSizeBytes = 256MB
        xVHD RouterOSImage
        {
            Name = $RouterOSImageFileName
            Type = 'Dynamic'
            Generation = 'Vhdx'
            Path = $MediaPath
            MaximumSizeBytes = $RouterOSVhdMaximumSizeBytes
            DependsOn = '[xDownloadFile]RouterOSImage'
        }

        #endregion RouterOS image
        #region management network

        xVMSwitch 'ManagementNetwork'
        {
            Name = 'MAN'
            Type = 'Internal'
            AllowManagementOS = $True
            DependsOn = '[WindowsOptionalFeatureSet]HyperV'
        }

        xVMNetworkAdapter 'ManagementOSNIC'
        {
            Id = 'ManagementOSNIC'
            Name = 'MAN'
            VMName = 'ManagementOS'
            SwitchName = 'MAN'
            DependsOn = "[xVMSwitch]ManagementNetwork"
        }

        #endregion management network
        #region virtual lab networks

        foreach ( $Network in @( 'LAN1', 'LAN2', 'WAN1', 'WAN2' ) )
        {
            xVMSwitch $Network
            {
                Name = $Network
                Type = 'Private'
                DependsOn = @(
                    '[WindowsOptionalFeatureSet]HyperV'
                )
            }
        }

        #endregion virtual lab networks
        #region virtual lab VMs

        $RouterOSVMs = 'WAN', 'GW1', 'GW2', 'WS1', 'WS2'
        foreach ( $RouterOSVM in $RouterOSVMs )
        {
            $RouterOSVhdFileName = $RouterOSVM + [System.IO.Path]::GetExtension( $RouterOSImagePath )
            $RouterOSVhdPath = Join-Path -Path $VhdPath -ChildPath $RouterOSVhdFileName
            xVHD "${RouterOSVM}VHD"
            {
                Name = $RouterOSVhdFileName
                Type = 'Differencing'
                Generation = 'Vhdx'
                Path = $VhdPath
                ParentPath = $RouterOSImagePath
                MaximumSizeBytes = $RouterOSVhdMaximumSizeBytes
                DependsOn = @(
                    '[File]NetworkVirtualTestLabVHDRoot',
                    '[xVHD]RouterOSImage'
                )
            }
            xVMHyperV $RouterOSVM
            {
                Name = $RouterOSVM
                Path = $VMsPath
                VhdPath = $RouterOSVhdPath
                Generation = 1
                EnableGuestService = $false
                StartupMemory = 256MB
                MinimumMemory = 256MB
                MaximumMemory = 256MB
                ProcessorCount = 1
                DependsOn = @(
                    '[WindowsOptionalFeatureSet]HyperV',
                    "[xVHD]${RouterOSVM}VHD"
                )
            }
            xVMLegacyNetworkAdapter "${RouterOSVM}MAN" {
                Id = "${RouterOSVM}MAN"
                Name = 'MAN'
                VMName = ${RouterOSVM}
                SwitchName = 'MAN'
                DependsOn = @(
                    "[xVMHyperV]${RouterOSVM}",
                    "[xVMSwitch]ManagementNetwork"
                )
            }
            Script "RemoveDefault${RouterOSVM}NIC"
            {
                DependsOn = "[xVMHyperV]${RouterOSVM}"
                GetScript = {
					<#
					[CmdletBinding()]
                    [OutputType([System.Collections.Hashtable])]
                    param
                    (
                        [parameter(Mandatory)]
                        [System.String]
                        $VMName = $Using:RouterOSVM
					)
					#>
					$VMName = $Using:RouterOSVM

                    $configuration = @{
                        VMName = $VMName
                    }
                    $arguments = @{}

                    if ($VMName -ne 'ManagementOS')
                    {
                        $arguments.Add('VMName', $VMName)
                    }
                    else
                    {
                        $arguments.Add('ManagementOS', $true)
                    }

                    Write-Verbose -Message ( 'Check non legacy NIC on virtual machine {0}.' -f $VMName )

                    $netAdapters = @( Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue | Where-Object { -not $_.IsLegacy } )

                    if ( $netAdapters )
                    {
                        Write-Verbose -Message ( 'On VM {0} there non legacy NIC exists: {1}.' -f
                            $VMName,
                            ( @( $netAdapters | ForEach-Object { $_.Name } ) -join ', ' )
                        )
                        $configuration.Add( 'NetworkAdapters', @() )
                        foreach ( $netAdapter in $netAdapters )
                        {
                            $NicConfig = @{
                                IsLegacy = $false
                            }
                            if ($VMName -eq 'ManagementOS')
                            {
                                $NicConfig.Add('MacAddress', $netAdapter.MacAddress)
                                $NicConfig.Add('DynamicMacAddress', $false)
                            }
                            elseif ($netAdapter.VMName)
                            {
                                $NicConfig.Add('MacAddress', $netAdapter.MacAddress)
                                $NicConfig.Add('DynamicMacAddress', $netAdapter.DynamicMacAddressEnabled)
                            }
                            $configuration.NetworkAdapters.Add( $NicConfig )
                        }
                        $configuration.Add( 'Ensure', 'Present' )
                    }
                    else
                    {
                        Write-Verbose -Message ( 'On VM {0} non legacy NIC does not exists.' -f $VMName )
                        $configuration.Add( 'Ensure', 'Absent' )
                    }

                    return $configuration
                }
                TestScript = {
					<#
                    [CmdletBinding()]
                    [OutputType([System.Collections.Hashtable])]
                    param
                    (
                        [parameter(Mandatory)]
                        [System.String]
                        $VMName = $Using:RouterOSVM,

                        [Parameter()]
                        [ValidateSet('Present', 'Absent')]
                        [String] $Ensure = 'Absent'
                    )
					#>
					$VMName = $Using:RouterOSVM
					$Ensure = 'Absent'

                    $arguments = @{}

                    if ($VMName -ne 'ManagementOS')
                    {
                        $arguments.Add('VMName', $VMName)
                    }
                    else
                    {
                        $arguments.Add('ManagementOS', $true)
                    }

                    Write-Verbose -Message ( 'Check non legacy NIC on VM {0}.' -f $VMName )

                    $netAdapters = @( Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue | Where-Object { -not $_.IsLegacy } )

                    if ( $Ensure -eq 'Present' )
                    {
                        Write-Verbose -Message ( 'Actions not needed.' )
                        return $true
                    }
                    else
                    {
                        if ( $netAdapters )
                        {
                            Write-Verbose -Message ( 'On VM {0} there non legacy NICs exists: {1}. Deletion expected.' -f
                                $VMName,
                                ( @( $netAdapters | ForEach-Object { $_.Name } ) -join ', ' )
                            )
                            return $false
                        }
                        else
                        {
                            Write-Verbose -Message ( 'On VM {0} non legacy NICs does not exists. Actions not needed.' -f $VMName )
                            return $true
                        }
                    }
                }
                SetScript = {
					<#
                    [CmdletBinding()]
                    [OutputType([System.Collections.Hashtable])]
                    param
                    (
                        [parameter(Mandatory)]
                        [System.String]
                        $VMName = $Using:RouterOSVM,

                        [Parameter()]
                        [ValidateSet('Present', 'Absent')]
                        [String] $Ensure = 'Absent'
                    )
					#>
					$VMName = $Using:RouterOSVM
					$Ensure = 'Absent'

                    $arguments = @{}

                    if ($VMName -ne 'ManagementOS')
                    {
                        $arguments.Add('VMName', $VMName)
                    }
                    else
                    {
                        $arguments.Add('ManagementOS', $true)
                    }

                    Write-Verbose -Message ( 'Check non legacy NIC on VM {0}.' -f $VMName )

                    $netAdapters = @( Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue | Where-Object { -not $_.IsLegacy } )

                    if ( $Ensure -eq 'Present' )
                    {
                        Write-Verbose -Message ( 'Actions not needed.' )
                    }
                    else
                    {
                        if ( $netAdapters )
                        {
                            Write-Verbose -Message ( 'On VM {0} there non legacy NICs exists: {1}. Deletion expected.' -f
                                $VMName,
                                ( @( $netAdapters | ForEach-Object { $_.Name } ) -join ', ' )
                            )
                            $netAdapters | Remove-VMNetworkAdapter -Verbose -ErrorAction Stop
                            Write-Verbose -Message ( 'On VM {0} non legacy NICs are deleted successfully.' -f $VMName )
                        }
                        else
                        {
                            Write-Verbose -Message ( 'On VM {0} non legacy NICs does not exists. Actions not needed.' -f $VMName )
                        }
                    }
                }
            }
        }

        xVMLegacyNetworkAdapter WANWAN1 {
			Id = 'WANWAN1'
			Name = 'WAN1'
			VMName = 'WAN'
			SwitchName = 'WAN1'
			DependsOn = @(
				"[xVMHyperV]WAN",
				"[xVMSwitch]WAN1"
				)
        }
        xVMLegacyNetworkAdapter WANWAN2 {
			Id = 'WANWAN2'
			Name = 'WAN2'
			VMName = 'WAN'
			SwitchName = 'WAN2'
			DependsOn = @(
				"[xVMHyperV]WAN",
				"[xVMSwitch]WAN2"
				)
        }

		xVMLegacyNetworkAdapter GW1WAN {
			Id = 'GW1WAN'
			Name = 'WAN'
			VMName = 'GW1'
			SwitchName = 'WAN1'
			DependsOn = @(
				"[xVMHyperV]GW1",
				"[xVMSwitch]WAN1"
				)
        }
        xVMLegacyNetworkAdapter GW1LAN {
			Id = 'GW1LAN'
			Name = 'LAN'
			VMName = 'GW1'
			SwitchName = 'LAN1'
			DependsOn = @(
				"[xVMHyperV]GW1",
				"[xVMSwitch]LAN1"
				)
        }

        xVMLegacyNetworkAdapter WS1LAN {
			Id = 'WS1LAN'
			Name = 'LAN'
			VMName = 'WS1'
			SwitchName = 'LAN1'
			DependsOn = @(
				"[xVMHyperV]WS1",
				"[xVMSwitch]LAN1"
				)
        }

		xVMLegacyNetworkAdapter GW2WAN {
			Id = 'GW2WAN'
			Name = 'WAN'
			VMName = 'GW2'
			SwitchName = 'WAN2'
			DependsOn = @(
				"[xVMHyperV]GW2",
				"[xVMSwitch]WAN2"
				)
        }
        xVMLegacyNetworkAdapter GW2LAN {
			Id = 'GW2LAN'
			Name = 'LAN'
			VMName = 'GW2'
			SwitchName = 'LAN2'
			DependsOn = @(
				"[xVMHyperV]GW2",
				"[xVMSwitch]LAN2"
				)
        }

        xVMLegacyNetworkAdapter WS2LAN {
			Id = 'WS2LAN'
			Name = 'LAN'
			VMName = 'WS2'
			SwitchName = 'LAN2'
			DependsOn = @(
				"[xVMHyperV]WS2",
				"[xVMSwitch]LAN2"
				)
        }

        #endregion virtual lab VMs

    }
}
