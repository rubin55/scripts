@echo off

:: Check if Y:\ contains what we expect.
echo Checking if X:\ contains our backup target...
if not exist "X:\Program Files" goto eject
if not exist "X:\Program Files (x86)" goto eject
if not exist "X:\Users" goto eject
if not exist "X:\Windows" goto eject


:: Do the backup using robocopy.
:: Note: needs admin privileges.
echo Starting backup of Core drive to X:\
robocopy C:\ X:\ /mir /b /xj /r:0 /log:"c:\Users\rubin\Desktop\backup-core.log"
goto done

:: Eject, eject, eject!
:eject
echo Didn't find expected folders on backup target, exiting...

:: Done with the backup.
:done
echo Finished backup of Core drive to X:\
