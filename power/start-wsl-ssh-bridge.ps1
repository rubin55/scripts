# Note: you need to set SSH_AUTH_SOCK=\\.\pipe\ssh-pageant
Start-Process -WindowStyle Hidden -WorkingDirectory 'C:\Program Files\Various Utilities' 'wsl-ssh-pageant.exe' '-force -winssh ssh-pageant'
