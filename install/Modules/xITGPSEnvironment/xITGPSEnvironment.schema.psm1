configuration ITGPSEnvironment
{
    param
    (
        [string[]]$ComputerName = 'localhost'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName PackageManagement -ModuleVersion 1.3.1
    Import-DscResource -ModuleName PowerShellModule -Name PSModuleResource

    Node $ComputerName
    {

        <#
		PackageManagementSource PSGallery
		{
			Ensure = 'Present'
			Name = 'PSGallery'
			ProviderName = 'PowerShellGet'
			SourceLocation = 'https://www.powershellgallery.com/api/v2/'
			InstallationPolicy = 'Trusted'
		}
		#>

        PSModuleResource xPowerShellExecutionPolicy
        {
            Module_Name = 'xPowerShellExecutionPolicy'
        }

        PSModuleResource InvokeBuild
        {
            Module_Name = 'InvokeBuild'
        }

        PSModuleResource Plaster
        {
            Module_Name = 'Plaster'
        }

        PSModuleResource PSScriptAnalyzer
        {
            Module_Name = 'PSScriptAnalyzer'
        }

        PSModuleResource Pester
        {
            Module_Name = 'Pester'
        }

        PSModuleResource platyPS
        {
            Module_Name = 'platyPS'
        }

        PSModuleResource New-VSCodeTask
        {
            Module_Name = 'New-VSCodeTask'
		}

        PSModuleResource cChoco
        {
            Module_Name = 'cChoco'
        }

        PSModuleResource vscode
        {
            Module_Name = 'vscode'
        }

        PSModuleResource xWinRM
        {
            Module_Name = 'xWinRM'
        }

        PSModuleResource xComputerManagement
        {
            Module_Name = 'xComputerManagement'
        }

        PSModuleResource xHyper-V
        {
            Module_Name = 'xHyper-V'
        }

        PSModuleResource xITGHyperV
        {
			Module_Name = 'xITGHyperV'
			MinimumVersion = '1.0.8'
        }

        PSModuleResource Lability
        {
            Module_Name = 'Lability'
        }

        PSModuleResource xPendingReboot
        {
            Module_Name = 'xPendingReboot'
        }

        PSModuleResource xDownloadFile
        {
            Module_Name = 'xDownloadFile'
        }

    }
}
