#Requires -Version 5.0
#Requires -Modules PSDesiredStateConfiguration
#Requires -Modules @{ ModuleName = 'PackageManagement'; ModuleVersion = '1.1.7' }

configuration PSForNetworkManagementWindowsPCDSC
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
	Import-DscResource -ModuleName PackageManagement -ModuleVersion 1.3.1

	PackageManagementSource PSGallery
	{
		Ensure               = "Present"
		Name                 = "PSGallery"
		ProviderName         = "PowerShellGet"
		SourceLocation       = "https://www.powershellgallery.com/api/v2/"
		InstallationPolicy   = "Trusted"
	}

	PackageManagement cChoco
	{
		Ensure               = "Present"
		Name                 = "cChoco"
		Source               = "PSGallery"
		DependsOn            = "[PackageManagementSource]PSGallery"
	}
}
