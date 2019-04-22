#Requires -Version 5.0
#Requires -RunAsAdministrator
#Requires -Modules PSDesiredStateConfiguration

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;

# TODO: через GPO
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted;
#Enable-PSRemoting -Force;

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted;
Install-Module PackageManagement -RequiredVersion 1.3.1;

$ModulesDir = (Join-Path -Path $PSScriptRoot -ChildPath 'Modules');

Import-Module (Join-Path -Path $ModulesDir -ChildPath 'xITGDSCEnvironment');

$DSCConfigDir = (Join-Path -Path $PSScriptRoot -ChildPath 'PSconfig');
$ConfigDir = (Join-Path -Path $PSScriptRoot -ChildPath 'config');

#. (Join-Path -Path $PSScriptRoot -ChildPath 'DSCEnvironmentConfig.ps1');
ITGDSCEnvironment -InstanceName ITGDSCEnvironment -OutputPath $DSCConfigDir;
Start-DscConfiguration -Path $DSCConfigDir -Wait -Verbose -ErrorAction Stop;

. (Join-Path -Path $PSScriptRoot -ChildPath 'NetworkManagementWindowsPCConfig.ps1');
NetworkManagementWindowsPCConfig -InstanceName NetworkManagementWindowsPCConfig -OutputPath $ConfigDir;
Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -ErrorAction Stop;
