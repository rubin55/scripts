$servers = "logic.home.local"
$location = "C:\Program Files\UMS"
$command = "javaw.exe"
$arguments = "-Xmx768M", "-Djava.net.preferIPv4Stack=true", "-Dfile.encoding=UTF-8", "-classpath", "update.jar;ums.jar", "net.pms.PMS"
$style = "Normal"

Write-Host "Dependent servers: $servers"
Write-Host "Running from path: $location"
Write-Host "Command to invoke: $command"
Write-Host "Command arguments: $arguments"
Write-Host "Window style type: $style"

Foreach ($server in $servers) {
    while (!(Test-Connection -ComputerName $server -Count 1 -Quiet)) {
        Start-Sleep -Seconds 1
        Write-Host "Server $server not yet reachable, retrying.."
    }

    Write-Host "Server $server reachable.."
}

Write-Host "Starting $command.."
Start-Process -WindowStyle $style -WorkingDirectory $location -ArgumentList $arguments $command
