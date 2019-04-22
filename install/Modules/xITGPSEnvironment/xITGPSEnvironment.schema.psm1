configuration ITGPSEnvironment
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

}
