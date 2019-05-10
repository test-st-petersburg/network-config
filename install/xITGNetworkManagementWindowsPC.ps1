#Requires -Version 5.0
#Requires -Modules PSDesiredStateConfiguration
#Requires -Modules cChoco

configuration ITGNetworkManagementWindowsPC
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName cChoco
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xHyper-V
    Import-DSCResource -ModuleName xPendingReboot
    Import-DSCResource -ModuleName xDownloadFile

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

    xVMSwitch LAN1
    {
        Name = 'LAN1'
        Type = 'Private'
        DependsOn = @('[WindowsOptionalFeatureSet]HyperV', '[xPendingReboot]PendingRebootAfterHyperVInstallation')
    }
    xVMSwitch LAN2
    {
        Name = 'LAN1'
        Type = 'Private'
        DependsOn = @('[WindowsOptionalFeatureSet]HyperV', '[xPendingReboot]PendingRebootAfterHyperVInstallation')
    }
    xVMSwitch WAN1
    {
        Name = 'WAN1'
        Type = 'Private'
        DependsOn = @('[WindowsOptionalFeatureSet]HyperV', '[xPendingReboot]PendingRebootAfterHyperVInstallation')
    }
    xVMSwitch WAN2
    {
        Name = 'WAN2'
        Type = 'Private'
        DependsOn = @('[WindowsOptionalFeatureSet]HyperV', '[xPendingReboot]PendingRebootAfterHyperVInstallation')
    }

	$NetworkVirtualTestLabPath = Join-Path -Path $env:SystemDrive -ChildPath 'NetworkVirtualTestLab'
	File NetworkVirtualTestLabRoot {
		Type = 'Directory'
		DestinationPath = $NetworkVirtualTestLabPath
	}
	$NetworkVirtualTestLabMediaPath = Join-Path -Path $NetworkVirtualTestLabPath -ChildPath 'MasterVirtualHardDisks'
	File NetworkVirtualTestLabMediaRoot {
		Type = 'Directory'
		DestinationPath = $NetworkVirtualTestLabMediaPath
        DependsOn = '[File]NetworkVirtualTestLabRoot'
	}

	# TODO: добавить автоматическое определение текущей стабильной версии RouterOS
	$RouterOSVersion = '6.44.3'
	$RouterOSImageFileName = 'RouterOS.vhdx'
	# $RouterOSImagePath = Join-Path -Path $NetworkVirtualTestLabMediaPath -ChildPath $RouterOSImageFileName
	xDownloadFile RouterOSImage {
		FileName = $RouterOSImageFileName
		SourcePath = "http://download2.mikrotik.com/routeros/$RouterOSVersion/chr-$RouterOSVersion.vhdx"
		# 'https://download.mikrotik.com/' требует дополнительных заголовков
		DestinationDirectoryPath = $NetworkVirtualTestLabMediaPath
        DependsOn = '[File]NetworkVirtualTestLabMediaRoot'
	}

}
