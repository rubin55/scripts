@echo off

set file="%USERPROFILE%\AppData\Local\Microsoft\OneDrive\logs\Business1\SyncDiagnostics.log"

:test
type %file% | find "drivesConnected = 1" > nul
if errorlevel 1 (
    echo OneDrive not connected yet, retrying..
    goto retry
) else (
    echo OneDrive connected, continue..
    goto continue
)

:retry
ping 127.0.0.1 -n 2 >nul
goto test

:continue
echo Removing extra OneDrive navigation pane..
reg import "%USERPROFILE%\Syncthing\Documents\Rubin\Registry Hacks\OneDrive Navigation Pane - Disable.reg"
rem exit