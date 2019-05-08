﻿<#
.Synopsis
    Скрипт подготовки среды
.Description
    Скрипт подготовки среды
.Link
    https://github.com/test-st-petersburg/network-config
.Example
    .\install.ps1 -GUI;
    Устанавливаем необходимые пакеты, в том числе - и графические среды.
#>
[CmdletBinding(
    SupportsShouldProcess = $true
    , ConfirmImpact = 'Medium'
#    , HelpUri = 'https://github.com/test-st-petersburg/network-config'
)]

param (
    # Ключ, определяющий необходимость установки визуальных средств.
    # По умолчанию устанавливаются только средства для командной строки.
    [Switch]
    $GUI
,
    # Для какой области выполняются действия.
    # Все необходимые средства устанавливаются на машину (Machine),
    # переменные окружения необходимо изменить для пользователя (User).
    [System.EnvironmentVariableTarget]
    $Scope = ( [System.EnvironmentVariableTarget]::Machine )
)

Function Invoke-ExternalInstaller {
    [CmdletBinding(
        SupportsShouldProcess = $true
        , ConfirmImpact = 'Medium'
    )]
    param (
        [String]
        $LiteralPath
        ,
        [String]
        $ArgumentList
    )

    $pinfo = [System.Diagnostics.ProcessStartInfo]::new();
    $pinfo.FileName = $LiteralPath;
    #$pinfo.RedirectStandardError = $true;
    #$pinfo.RedirectStandardOutput = $true;
    $pinfo.UseShellExecute = $false;
    $pinfo.Arguments = $ArgumentList;
    if ($PSCmdLet.ShouldProcess($LiteralPath, 'Запустить')) {
        $p = [System.Diagnostics.Process]::new();
        try {
            $p.StartInfo = $pinfo;
            $p.Start() | Out-Null;
            $p.WaitForExit();
            $LASTEXITCODE = $p.ExitCode;
            #$p.StandardOutput.ReadToEnd() `
            #| Write-Verbose `
            #;
            if ( $p.ExitCode -ne 0 ) {
				#$p.StandardError.ReadToEnd() `
				"$LiteralPath exit with error code $($p.ExitCode)" `
				| Write-Error `
                ;
            };
        } finally {
            $p.Close();
        };
    };
}

switch ( $env:PROCESSOR_ARCHITECTURE ) {
    'amd64' { $ArchPath = 'x64'; }
    'x86'   { $ArchPath = 'x86'; }
    default { Write-Error 'Unsupported processor architecture.'}
};
$ToPath = @();

[String] $chocoExe;

if ( -not ( $env:APPVEYOR -eq 'True' ) ) {
    if (
        ( $Scope -eq ( [System.EnvironmentVariableTarget]::Machine ) ) `
        -and $PSCmdLet.ShouldProcess('chocolatey', 'Установить')
    ) {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));
    };
};
$chocoExe = Join-Path `
    -Path (
        Join-Path `
            -Path ( [Environment]::GetEnvironmentVariable( 'ChocolateyInstall', [System.EnvironmentVariableTarget]::Machine ) ) `
            -ChildPath 'bin' `
    ) `
    -ChildPath 'choco.exe' `
;

if ( -not ( $env:APPVEYOR -eq 'True' ) ) {
    if (
        ( $Scope -eq ( [System.EnvironmentVariableTarget]::Machine ) ) `
        -and $PSCmdLet.ShouldProcess('cygwin', 'Установить')
    ) {
        & $chocoExe install cygwin --no-progress --confirm --failonstderr | Out-String -Stream | Write-Verbose;
	};
} else {
    if (
        $Scope -eq ( [System.EnvironmentVariableTarget]::Machine )
    ) {
		& $chocoExe upgrade cygwin --no-progress --confirm --failonstderr | Out-String -Stream | Write-Verbose;
	};
};

if (
	$Scope -eq ( [System.EnvironmentVariableTarget]::Machine )
) {
	$env:CygWin = Get-ItemPropertyValue `
        -Path HKLM:\SOFTWARE\Cygwin\setup `
        -Name rootdir `
    ;

    Write-Verbose "CygWin root directory: $env:CygWin";
    $ToPath += "$env:CygWin\bin";

    # исправляем проблемы совместимости chocolatey, cyg-get и cygwin
    If ( Test-Path "$env:CygWin\cygwinsetup.exe" ) {
        $cygwinsetup = "$env:CygWin\cygwinsetup.exe";
    } ElseIf ( Test-Path "$env:CygWin\setup-x86_64.exe" ) {
        $cygwinsetup = "$env:CygWin\setup-x86_64.exe";
    } ElseIf ( Test-Path "$env:CygWin\setup-x86.exe" ) {
        $cygwinsetup = "$env:CygWin\setup-x86.exe";
    } ElseIf ( Test-Path "$env:ChocolateyPath\lib\Cygwin\tools\cygwin\cygwinsetup.exe" ) {
        $cygwinsetup = "$env:ChocolateyPath\lib\Cygwin\tools\cygwin\cygwinsetup.exe";
    } ElseIf ( Test-Path "$env:ChocolateyPath\lib\Cygwin.$(( Get-Package -Name CygWin -ProviderName Chocolatey ).Version)\tools\cygwin\cygwinsetup.exe" ) {
        $cygwinsetup = "$env:ChocolateyPath\lib\Cygwin.$(( Get-Package -Name CygWin -ProviderName Chocolatey ).Version)\tools\cygwin\cygwinsetup.exe";
    } Else {
        Write-Error 'I can not find CygWin setup!';
    };
    Write-Verbose "CygWin setup: $cygwinsetup";
    if ($PSCmdLet.ShouldProcess('CygWin', 'Установить переменную окружения')) {
        [System.Environment]::SetEnvironmentVariable( 'CygWin', $env:CygWin, $Scope );
    };
    $ToPath += "$env:CygWin\bin";

    if (
        ( $Scope -eq ( [System.EnvironmentVariableTarget]::Machine ) ) `
		-and $PSCmdLet.ShouldProcess('Пакеты CygWin make, curl, awk, cat, cmp, cp, diff, echo, egrep, expr, false, grep, ln, ls, m4, mkdir, mv, printf, pwd, rm, rmdir, sed, sleep, sort, tar, test, touch, tr, true', 'Установить')
    ) {
        Invoke-ExternalInstaller `
            -LiteralPath $cygwinsetup `
            -ArgumentList '--packages make,curl,awk,cat,cmp,cp,diff,echo,egrep,expr,false,grep,ln,ls,m4,mkdir,mv,printf,pwd,rm,rmdir,sed,sleep,sort,tar,test,touch,tr,true --quiet-mode --no-desktop --no-startmenu' `
        ;
    };

};

$env:CygWin = Get-ItemPropertyValue `
    -Path HKLM:\SOFTWARE\Cygwin\setup `
    -Name rootdir `
;
Write-Verbose "CygWin root directory: $env:CygWin";
$ToPath += "$env:CygWin\bin";

if ( $GUI ) {
    if (
        ( $Scope -eq ( [System.EnvironmentVariableTarget]::Machine ) ) `
        -and $PSCmdLet.ShouldProcess('Visual Studio Code', 'Установить')
    ) {
        & $chocoExe install vscode --no-progress --confirm --failonstderr | Out-String -Stream | Write-Verbose;
    };
};

$Path = `
    ( `
        ( ( [Environment]::GetEnvironmentVariable( 'PATH', [System.EnvironmentVariableTarget]::Process ) ) -split ';' ) `
        + $ToPath `
        | Sort-Object -Unique `
    ) `
;
Write-Verbose 'Path variable:';
$Path | ForEach-Object { Write-Verbose "    $_" };

if ($PSCmdLet.ShouldProcess('PATH', 'Установить переменную окружения')) {
    $env:Path = $Path -join ';';
    [System.Environment]::SetEnvironmentVariable( 'PATH', $env:Path, [System.EnvironmentVariableTarget]::User );
};