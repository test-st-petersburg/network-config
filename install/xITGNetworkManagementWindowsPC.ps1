#Requires -Version 5.0
#Requires -Modules PSDesiredStateConfiguration
#Requires -Modules cChoco

configuration ITGNetworkManagementWindowsPC
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName cChoco

    Environment chocolatelyInstall {
        Name  = 'chocolatelyInstall'
        value = "${env:SystemDrive}\choco\bin"
    }

    cChocoInstaller choco {
        InstallDir = "${env:SystemDrive}\choco"
    }

    cChocoPackageInstaller VSCode {
        Name = 'vscode'
	}

}
