$servers = "www.steampowered.com"
$location = "C:\Steam"
$command = "steam.exe"
$style = "Normal"

Write-Host "Dependent servers: $servers"
Write-Host "Running from path: $location"
Write-Host "Command to invoke: $command"
Write-Host "Window style type: $style"

Foreach ($server in $servers) {
    while (!(Test-Connection -ComputerName $server -Count 1 -Quiet)) {
        Start-Sleep -Seconds 1
        Write-Host "Server $server not yet reachable, retrying.."
    }

    Write-Host "Server $server reachable.."
}

Write-Host "Starting $command.."
Start-Process -WindowStyle $style -WorkingDirectory $location $command
