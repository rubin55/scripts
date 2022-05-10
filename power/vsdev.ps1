$env:JABBA_HOME="C:\Users\rubin\.jabba"
<#
.SYNOPSIS
Enables the Visual Studio command-line environment within the current PowerShell session.
.DESCRIPTION
Invoke-VisualStudioCommandLineEnvironment is a wrapper that calls VsDevCmd.bat and changes the environment of the current PowerShell session to enable you to use the compiler and linker and other assorted utilities directly from within the current PowerShell session.

.EXAMPLE
Invoke-VisualStudioCommandLineEnvironment

Activate the Visual Studio command-line environment in current PowerShell session.
#>
function Invoke-VisualStudioCommandLineEnvironment {
    Push-Location "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\Common7\Tools"
    cmd /c "VsDevCmd.bat&set" |
        ForEach-Object {
        if ($_ -match "=") {
            $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
        }
    }
    Pop-Location
    Write-Host "`nVisual Studio 2017 command prompt variables set." -ForegroundColor Yellow
}

Set-Alias vsdev Invoke-VisualStudioCommandLineEnvironment
