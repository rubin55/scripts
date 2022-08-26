$arguments = "--no-console"
$command = "scummvm.exe"
$location = "C:\Program Files (x86)\ScummVM"
$style = "Normal"

Write-Host "Running from path: $location"
Write-Host "Command to invoke: $command"
Write-Host "Window style type: $style"

Write-Host "Starting $command.."
Start-Process -WindowStyle $style -WorkingDirectory $location $command $arguments
