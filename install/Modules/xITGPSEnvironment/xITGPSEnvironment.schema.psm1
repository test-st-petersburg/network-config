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
