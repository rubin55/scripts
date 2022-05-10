function Select-Java($cmd, $jdk) {
    $root="C:\Program Files\Java"
    $path = [System.Environment]::GetEnvironmentVariable('PATH')

    switch ( $cmd ) {
        "list" { Get-ChildItem $root | Format-Table Name }
        "show" { Get-Command java | Format-Table Path }
        "use" {
            If (Test-Path $root\$jdk) {
                # Remove any Java from the path.
                $table = Get-ChildItem $root
                ForEach ($row In $table) {
                    $path = ($path.Split(';') | Where-Object { $_ -ne $row.FullName + "\bin" }) -join ';'
                }

                # Add selected Java to the path.
                $pathArray = $path.Split(';')
                $env:Path = ($pathArray + "$root\$jdk\bin") -join ';'

            } Else {
                Write-Host "Error: JDK $jdk not installed."
            }
        }
        default {
            Write-Host "Usage: jdkctl list^|show^|use"
        }
    }
}

Set-Alias jdkctl Select-Java
