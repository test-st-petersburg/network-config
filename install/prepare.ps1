#Requires -Version 5.0
#Requires -RunAsAdministrator
#Requires -Modules PSDesiredStateConfiguration

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;

# TODO: через GPO
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted;
#Enable-PSRemoting -Force;

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted;
Install-Module PackageManagement -RequiredVersion 1.3.1;
Install-Module PowerShellModule;

$ModulesDir = (Join-Path -Path $PSScriptRoot -ChildPath 'Modules');

Import-Module (Join-Path -Path $ModulesDir -ChildPath 'xITGPSEnvironment') -Force;
$PSConfigDir = (Join-Path -Path $PSScriptRoot -ChildPath 'PSconfig');
ITGPSEnvironment -OutputPath $PSConfigDir;
Start-DscConfiguration -Path $PSConfigDir -Wait -Verbose -ErrorAction Stop;

Import-Module (Join-Path -Path $ModulesDir -ChildPath 'xITGDSCEnvironment') -Force;
$DSCConfigDir = (Join-Path -Path $PSScriptRoot -ChildPath 'DSCconfig');
ITGDSCEnvironment -OutputPath $DSCConfigDir;
Start-DscConfiguration -Path $DSCConfigDir -Wait -Verbose -ErrorAction Stop;

$PSDefaultParameterValues = @{
    'Enable-WindowsOptionalFeature:NoRestart' = $true
}

. (Join-Path -Path $PSScriptRoot -ChildPath 'xITGNetworkManagementWindowsPC.ps1');
$ConfigDir = (Join-Path -Path $PSScriptRoot -ChildPath 'config');
ITGNetworkManagementWindowsPC -OutputPath $ConfigDir;
Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -ErrorAction Stop;
