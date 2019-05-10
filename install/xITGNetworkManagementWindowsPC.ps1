#Requires -Version 5.0
#Requires -Modules PSDesiredStateConfiguration
#Requires -Modules cChoco

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

		$RouterOSVMs = 'WAN', 'GW1', 'GW2', 'WS1', 'WS2'
		$RouterOSVHDs = @{}
		foreach ( $RouterOSVM in $RouterOSVMs )
		{
			$RouterOSVHDs.Add( $RouterOSVM, ( Join-Path -Path $VhdPath -ChildPath ( $RouterOSVM + [System.IO.Path]::GetExtension( $RouterOSImagePath ) ) ) )
			File "${RouterOSVM}VHD"
			{
				Type = 'File'
				SourcePath = $RouterOSImagePath
				DestinationPath = $RouterOSVHDs[$RouterOSVM]
				DependsOn = @( '[File]NetworkVirtualTestLabVHDRoot', '[xDownloadFile]RouterOSImage' )
			}
		}

		xVMHyperV GW1
        {
			Name = 'GW1'
			Path = $VMsPath
            VhdPath = $RouterOSVHDs['GW1']
			Generation = 1
			EnableGuestService = $false
			StartupMemory = 256MB
			MinimumMemory = 256MB
			MaximumMemory = 256MB
			ProcessorCount = 1
            DependsOn = @(
                '[WindowsOptionalFeatureSet]HyperV',
                '[File]GW1VHD'
            )
        }
    }
}
