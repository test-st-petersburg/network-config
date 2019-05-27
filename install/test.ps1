$RouterOSVM = 'GW1'
Stop-VM -Name $RouterOSVM -Verbose
Start-VM -Name $RouterOSVM -Verbose

$npipe = New-Object System.IO.Pipes.NamedPipeClientStream(
    'localhost',
    "itg.network-config.$RouterOSVM",
    [System.IO.Pipes.PipeDirection]::InOut,
    [System.IO.Pipes.PipeOptions]::None,
    [System.Security.Principal.TokenImpersonationLevel]::Impersonation
)
$npipe.Connect()

$pipeReader = New-Object System.IO.StreamReader($npipe)
$pipeWriter = New-Object System.IO.StreamWriter($npipe)
$pipeWriter.AutoFlush = $true

$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host

Start-Sleep -Seconds 1
$pipeWriter.WriteLine( 'admin' )
$pipeReader.ReadLine() | Write-Host

Start-Sleep -Seconds 1
$pipeWriter.WriteLine( '' )
$pipeReader.ReadLine() | Write-Host

$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host

Start-Sleep -Seconds 1
$pipeWriter.WriteLine( "/system identity print" )
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host

Start-Sleep -Seconds 1
$pipeWriter.WriteLine( "/system identity set name=$RouterOSVM" )
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host
$pipeReader.ReadLine() | Write-Host

$npipe.Dispose()
Stop-VM -Name $RouterOSVM -Verbose
