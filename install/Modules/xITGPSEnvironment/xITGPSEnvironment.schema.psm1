configuration ITGPSEnvironment
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName PackageManagement -ModuleVersion 1.3.1
    Import-DscResource -ModuleName PowerShellModule -Name PSModuleResource

<#
	PackageManagementSource PSGallery {
        Ensure             = "Present"
        Name               = "PSGallery"
        ProviderName       = "PowerShellGet"
        SourceLocation     = "https://www.powershellgallery.com/api/v2/"
        InstallationPolicy = "Trusted"
	}
#>

    PSModuleResource xPowerShellExecutionPolicy {
        Ensure      = "Present"
        Module_Name = "xPowerShellExecutionPolicy"
    }

    PSModuleResource cChoco {
        Ensure      = "Present"
        Module_Name = "cChoco"
    }

    PSModuleResource xWinRM {
        Ensure      = "Present"
        Module_Name = "xWinRM"
    }

}
