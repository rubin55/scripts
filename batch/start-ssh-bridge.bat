@echo off
powershell -WindowStyle Hidden -Command Start-Process -NoNewWindow 'wsl-ssh-pageant.exe' '-force -winssh ssh-pageant'
:: Note: you need to set SSH_AUTH_SOCK=\\.\pipe\ssh-pageant
