@echo off

rem Note: You can create parameterized shortcuts with PowerShell, like this:
rem powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('x.lnk');$s.TargetPath='launch-amiga-app';$s.Arguments='Games:RickDangerous/RickDangerous';$s.Save()"

rem Check for arguments.
if not "%1"=="" (
  setlocal enabledelayedexpansion

  rem A few environment variables.
  set winuaeExecutable=C:\Program Files\WinUAE\winuae64.exe
  set winuaeConfiguration=C:\Users\rubin\Syncthing\Emulation\Commodore Amiga\Configurations\Rubin's A1200 ^(PAL, HiRes^).uae
  set systemDiskLocation=C:\Users\rubin\Syncthing\Emulation\Commodore Amiga\Hard Directories\System
  set startupSequenceTemplate=!systemDiskLocation!\S\startup-sequence.wbrun

  rem Write custom startup-sequence using startup-sequence template.
  type "!startupSequenceTemplate!" | python -c "from __future__ import print_function;import re,sys; print(sys.stdin.read().replace(sys.argv[1], sys.argv[2]))" "$APP" "%1" "0" > "!systemDiskLocation!\S\startup-sequence"

  rem Create SHA-256 hash of argument to use as name for statefile (which needs to be
  rem unique per specific program inovocation).
  for /f "usebackq tokens=*" %%a in (`python -c "from __future__ import print_function;import hashlib,sys; print(hashlib.sha256(sys.argv[1].encode('utf-8')).hexdigest())" "%1"`) do set argumentHash=%%a


  rem Use Dos2Unix to make sure we have no \r (carriage return) in our startup sequence.
  dos2unix "!systemDiskLocation!\S\startup-sequence"

  rem Execute WinUAE with specified configuration.
  "!winuaeExecutable!" -f "!winuaeConfiguration!" -s statefile_name="!argumentHash!"
) else (
    echo Usage: %0 ^<path to app, Amiga style^>
    echo For example: Games:RickDangerous/RickDangerous
    exit /b 1
)
