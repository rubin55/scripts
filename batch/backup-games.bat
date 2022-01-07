@echo off

:: Check if Y:\ contains what we expect.
echo Checking if Y:\ contains our backup target...
if not exist Y:\Galaxy goto eject
if not exist Y:\Origin goto eject
if not exist Y:\Steam goto eject

:: Do the backup using robocopy.
:: Note: needs admin privileges.
echo Starting backup of Games drive to Y:\
robocopy G:\ Y:\ /mir /b /xj /r:0 /log:"c:\Users\rubin\Desktop\backup-games.log"

goto done

:: Eject, eject, eject!
:eject
echo Didn't find expected folders on backup target, exiting...

:: Done with the backup.
:done
echo Finished backup of Games drive to Y:\
