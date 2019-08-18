﻿$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;
$VerbosePreference = [System.Management.Automation.ActionPreference]::SilentlyContinue;

Import-Module ITGSerialTerminalTools;

$RouterOSVM = 'GW1';
Stop-VM -Name $RouterOSVM -Verbose;
Start-VM -Name $RouterOSVM -Verbose;

$ConsoleStream = New-Object System.IO.Pipes.NamedPipeClientStream(
    'localhost',
    "itg.network-config.$RouterOSVM",
    [System.IO.Pipes.PipeDirection]::InOut,
    [System.IO.Pipes.PipeOptions]::None,
    [System.Security.Principal.TokenImpersonationLevel]::Impersonation
);
$ConsoleStream.Connect();
$ConsoleStreamReader = New-Object System.IO.StreamReader( $ConsoleStream );
$ConsoleStreamWriter = New-Object System.IO.StreamWriter( $ConsoleStream );
$ConsoleStreamWriter.AutoFlush = $true;

Wait-ITGSerialTerminalExpectedMessage -PromptPattern 'Login:' `
    -ConsoleStreamReader $ConsoleStreamReader `
    -Timeout ( New-Object System.TimeSpan( 0, 0, 30 ) ) -Verbose;
$ConsoleStreamWriter.WriteLine( 'admin' );
Wait-ITGSerialTerminalExpectedMessage -PromptPattern 'Password:' `
    -ConsoleStreamReader $ConsoleStreamReader `
    -Timeout ( New-Object System.TimeSpan( 0, 0, 5 ) ) -Verbose;
$ConsoleStreamWriter.WriteLine( '' );
Wait-ITGSerialTerminalExpectedMessage `
    -ConsoleStreamReader $ConsoleStreamReader `
    -Timeout ( New-Object System.TimeSpan( 0, 0, 30 ) ) -Verbose;

Invoke-ITGSerialTerminalRemoteCommand -Command '/system identity print' `
    -ConsoleStreamReader $ConsoleStreamReader -ConsoleStreamWriter $ConsoleStreamWriter `
    -Timeout ( New-Object System.TimeSpan( 0, 0, 5 ) ) -Verbose `
    -PassThru `
| Write-Host;
Invoke-ITGSerialTerminalRemoteCommand -Command "/system identity set name=${RouterOSVM}" `
    -ConsoleStreamReader $ConsoleStreamReader -ConsoleStreamWriter $ConsoleStreamWriter  `
    -Timeout ( New-Object System.TimeSpan( 0, 0, 5 ) ) -Verbose `
    -PassThru `
| Write-Host;
Invoke-ITGSerialTerminalRemoteCommand -Command '/system identity print' `
    -ConsoleStreamReader $ConsoleStreamReader -ConsoleStreamWriter $ConsoleStreamWriter `
    -Timeout ( New-Object System.TimeSpan( 0, 0, 5 ) ) -Verbose `
    -PassThru `
| Write-Host;

$ConsoleStream.Dispose();
Stop-VM -Name $RouterOSVM -Verbose;
