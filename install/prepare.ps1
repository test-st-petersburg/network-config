#Requires -Version 5.0
#Requires -RunAsAdministrator
#Requires -Modules PSDesiredStateConfiguration

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted;
Install-Module PackageManagement -RequiredVersion 1.3.1;

$PSConfigDir = (Join-Path -Path $PSScriptRoot -ChildPath 'PSconfig');
$ConfigDir = (Join-Path -Path $PSScriptRoot -ChildPath 'config');

. (Join-Path -Path $PSScriptRoot -ChildPath 'PSForNetworkManagementWindowsPCDSC.ps1');
PSForNetworkManagementWindowsPCDSC -InstanceName PSForNetworkManagementWindowsPCDSC -OutputPath $PSConfigDir;
Start-DscConfiguration -Path $PSConfigDir -Wait -Verbose;

. (Join-Path -Path $PSScriptRoot -ChildPath 'NetworkManagementWindowsPCDSC.ps1');
NetworkManagementWindowsPCDSC -InstanceName NetworkManagementWindowsPCDSC -OutputPath $ConfigDir;
Start-DscConfiguration -Path $ConfigDir -Wait -Verbose;
