@echo off

set addr="www.steampowered.com"


:test
ping -n 1 %addr% | find "TTL=" >nul
if errorlevel 1 (
    echo Steam network not yet reachable, retrying..
    goto retry
) else (
    echo Steam network reachable, continue..
    goto continue
)

:retry
ping 127.0.0.1 -n 2 >nul
goto test

:continue
echo Starting Steam..
start "Steam" "C:\Steam\steam.exe"
exit
