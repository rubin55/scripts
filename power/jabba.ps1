function Invoke-Jabba {
    $env:JABBA_HOME=$env:USERPROFILE + "\.jabba"
    $fd3=$([System.IO.Path]::GetTempFileName())
    $command=$env:JABBA_HOME + "\bin\jabba.exe $args --fd3 $fd3"
    & { $env:JABBA_SHELL_INTEGRATION="ON"; Invoke-Expression $command }
    $fd3content=$(Get-Content $fd3)
    if ($fd3content) {
        $expression=$fd3content.replace("export ","`$env:").replace("unset ","Remove-Item env:") -join "`n"
        if (-not $expression -eq "") { Invoke-Expression $expression }
    }
    Remove-Item -Force $fd3
}

Set-Alias jabba Invoke-Jabba
