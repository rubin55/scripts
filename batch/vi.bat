@echo off
tasklist /FI "IMAGENAME eq gvim.exe" 2>NUL | find /I /N "gvim.exe" >NUL
if "%ERRORLEVEL%"=="0" start "dummy" /b "C:\Program Files\Vim\gvim.exe" --servername GVIM --remote-silent %*
if "%ERRORLEVEL%"=="1" start "dummy" /b "C:\Program Files\Vim\gvim.exe" --servername GVIM %*
