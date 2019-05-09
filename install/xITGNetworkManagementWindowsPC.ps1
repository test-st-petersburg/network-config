#Requires -Version 5.0
#Requires -Modules PSDesiredStateConfiguration
#Requires -Modules cChoco

configuration ITGNetworkManagementWindowsPC
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName cChoco
	Import-DscResource -ModuleName xComputerManagement
	Import-DscResource -ModuleName xHyper-V

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

}
