$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;
$VerbosePreference = [System.Management.Automation.ActionPreference]::SilentlyContinue;

Function Wait-Expect
{
    [CmdletBinding()]
    param(
        [Parameter( Mandatory = $true )]
        [System.IO.TextReader] $ConsoleStreamReader,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $PromptPattern = '\[.+?\] >',
        [Switch] $PassThru,
        [Parameter()]
        [System.TimeSpan] $Timeout = ( New-Object System.TimeSpan( 0, 0, 30 ) )
    )

    $Local:ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;

    $Buffer = '';
    $VerboseBuffer = '';

    $Timer = [Diagnostics.StopWatch]::StartNew();

    $RegExp = New-Object System.Text.RegularExpressions.Regex( $PromptPattern );

    do
    {
        $StreamData = $ConsoleStreamReader.Read();
        while ( ( $StreamData -eq -1 ) -and ( $Timer.Elapsed -lt $Timeout ) )
        {
            Start-Sleep -Milliseconds 50;
            $StreamData = $ConsoleStreamReader.Read();
        };
        if ( $Timer.Elapsed -ge $Timeout )
        {
            Write-Error -Exception ( New-Object System.TimeoutException );
        };
        switch ( [char]$StreamData )
        {
            "`r"
            {
                if ( $VerboseBuffer )
                {
                    Write-Verbose $VerboseBuffer;
                    $VerboseBuffer = "";
                };
            }
            "`n"
            {
            }
            Default
            {
                $VerboseBuffer += [char] $StreamData;
            }
        }
        $Buffer += [char] $StreamData;
        $SearchResults = $RegExp.Match( $Buffer );
    } while ( -not $SearchResults.Success );

    if ( $VerboseBuffer )
    {
        Write-Verbose $VerboseBuffer;
        $VerboseBuffer = "";
    };

    $Result = $Buffer.Substring( 0, $SearchResults.Index );
    $Buffer = $Buffer.Remove( 0, $SearchResults.Index + $SearchResults.Length );
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
