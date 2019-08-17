$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;
$VerbosePreference = [System.Management.Automation.ActionPreference]::SilentlyContinue;

[string] $Script:Buffer = '';
[string] $Script:VerboseBuffer = '';

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
        [Parameter( Mandatory = $true )]
        [System.IO.TextReader] $ConsoleStreamReader,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $PromptPattern = '\[.+?\] >',
        [Switch] $PassThru
    )

    $Local:ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;

    $Script:Buffer = '';
    $Script:VerboseBuffer = '';

    $RegExp = New-Object System.Text.RegularExpressions.Regex( $PromptPattern );

    do
    {
        $StreamData = $ConsoleStreamReader.Read();
        while ( $StreamData -eq -1 )
        {
            Start-Sleep -Milliseconds 50;
            $StreamData = $ConsoleStreamReader.Read();
        };
        switch ( [char]$StreamData )
        {
            "`r"
            {
                Write-Verbose $Script:VerboseBuffer;
                $Script:VerboseBuffer = "";
            }
            "`n"
            {
            }
            Default
            {
                $Script:VerboseBuffer += [char] $StreamData;
            }
        }
        $Script:Buffer += [char] $StreamData;
        $SearchResults = $RegExp.Match( $Script:Buffer );
    } while ( -not $SearchResults.Success );

    Write-Verbose $Script:VerboseBuffer;
    $Script:VerboseBuffer = "";

    $Result = $Script:Buffer.Substring( 0, $SearchResults.Index );
    $Script:Buffer = $Script:Buffer.Remove( 0, $SearchResults.Index + $SearchResults.Length );
    if ( $PassThru )
    {
        return $Result;
    };
}

Function Invoke-RemoteCommand
{
    [CmdletBinding()]
    param(
        [Parameter( Mandatory = $true )]
        [System.IO.TextReader] $ConsoleStreamReader,
        [Parameter( Mandatory = $true )]
        [System.IO.TextWriter] $ConsoleStreamWriter,
        [Parameter( Mandatory = $true, ValueFromPipeLine = $true )]
        [AllowEmptyString()]
        [string] $Command,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $PromptPattern = '\[.+?\] >',
        [Switch] $PassThru
    )

    $Local:ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;

    $Script:Buffer = '';
    $Script:VerboseBuffer = '';

    $ConsoleStreamWriter.WriteLine( $Command );
    Write-Verbose ">>>> $Command";

    $EscapedCommand = [System.Text.RegularExpressions.Regex]::Escape( $Command );
    Wait-Expect `
        -ConsoleStreamReader $ConsoleStreamReader `
        -PromptPattern "$PromptPattern\s*$EscapedCommand" `
        -Verbose:$false;
    Wait-Expect `
        -ConsoleStreamReader $ConsoleStreamReader `
        -PromptPattern "$PromptPattern\s*$EscapedCommand" `
        -Verbose:$false;

    return Wait-Expect `
        -ConsoleStreamReader $ConsoleStreamReader `
        -PromptPattern $PromptPattern `
        -PassThru:$PassThru `
        -Verbose:$Verbose;
}

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

Wait-Expect -PromptPattern 'Login:' `
    -ConsoleStreamReader $ConsoleStreamReader -Verbose;
$ConsoleStreamWriter.WriteLine( 'admin' );
Wait-Expect -PromptPattern 'Password:' `
    -ConsoleStreamReader $ConsoleStreamReader -Verbose;
$ConsoleStreamWriter.WriteLine( '' );
Wait-Expect `
    -ConsoleStreamReader $ConsoleStreamReader -Verbose;

Invoke-RemoteCommand -Command '/system identity print' `
    -ConsoleStreamReader $ConsoleStreamReader -ConsoleStreamWriter $ConsoleStreamWriter -Verbose -PassThru `
| Write-Host;
Invoke-RemoteCommand -Command "/system identity set name=${RouterOSVM}" `
    -ConsoleStreamReader $ConsoleStreamReader -ConsoleStreamWriter $ConsoleStreamWriter -Verbose -PassThru `
| Write-Host;
Invoke-RemoteCommand -Command '/system identity print' `
    -ConsoleStreamReader $ConsoleStreamReader -ConsoleStreamWriter $ConsoleStreamWriter -Verbose -PassThru `
| Write-Host;

$ConsoleStream.Dispose();
Stop-VM -Name $RouterOSVM -Verbose;
