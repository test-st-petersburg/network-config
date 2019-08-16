$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;
$VerbosePreference = [System.Management.Automation.ActionPreference]::Continue;

[string] $Buffer = '';

Function Wait-Expect
{
<#
.SYNOPSIS
	Keep receiving output from a background job until it matches a pattern.
	The output will be appended to the log file as it's received.
	When a match is found, the line with it will be returned as the result.

	The wait may be limited by a timeout. If the match is not received within
	the timeout, throws an error (unless the option -Quiet is used, then
	just returns).

	If the job completes without matching the pattern, the reaction is the same
	as on the timeout.
#>
    [CmdletBinding()]
    param(
		[parameter( Mandatory = $true )]
		[System.IO.TextReader] $StreamReader,
        [parameter( Mandatory = $true )]
		[string] $Pattern
	)

	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;

    while ( $true ) {

		$SearchResults = ( $Buffer | Select-String $Pattern ).Matches;
		if ( $SearchResults.Success ) {
			$Buffer = $Buffer.Remove( 0, $SearchResults.Index + $SearchResults.Length );
			Write-Verbose $SearchResults.Value;
			return;
		};

		$StreamData = $StreamReader.Read();
		$Buffer += [char] $StreamData;
		if ( $StreamData -ne -1 ) {
			# Write-Verbose $Buffer;
		};

	};
}

$RouterOSVM = 'GW1';
Stop-VM -Name $RouterOSVM -Verbose;
Start-VM -Name $RouterOSVM -Verbose;

$npipe = New-Object System.IO.Pipes.NamedPipeClientStream(
    'localhost',
    "itg.network-config.$RouterOSVM",
    [System.IO.Pipes.PipeDirection]::InOut,
    [System.IO.Pipes.PipeOptions]::None,
    [System.Security.Principal.TokenImpersonationLevel]::Impersonation
);
$npipe.Connect();

$pipeReader = New-Object System.IO.StreamReader( $npipe );
$pipeWriter = New-Object System.IO.StreamWriter( $npipe );
$pipeWriter.AutoFlush = $true;

Wait-Expect -StreamReader $pipeReader -Pattern 'Login:' -Verbose;
$pipeWriter.WriteLine( 'admin' );

Wait-Expect -StreamReader $pipeReader -Pattern 'Password:' -Verbose;
$pipeWriter.WriteLine( '' )

Wait-Expect -StreamReader $pipeReader -Pattern '] >' -Verbose;
$pipeWriter.WriteLine( "/system identity print" )
$pipeReader.ReadLine() | Write-Host

Wait-Expect -StreamReader $pipeReader -Pattern '] >' -Verbose;
$pipeWriter.WriteLine( "/system identity set name=${RouterOSVM}" )

Wait-Expect -StreamReader $pipeReader -Pattern '] >' -Verbose;
$pipeWriter.WriteLine( "/system identity print" )
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host

$npipe.Dispose();
Stop-VM -Name $RouterOSVM -Verbose
