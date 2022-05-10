@echo off

:: Check if Z:\ contains what we expect.
echo Checking if Z:\ contains our backup target...
if not exist Z:\Archive\.stfolder goto eject
if not exist Z:\Default\.stfolder goto eject
if not exist Z:\Documents\.stfolder goto eject
if not exist Z:\Emulation\.stfolder goto eject
if not exist Z:\Fonts\.stfolder goto eject
if not exist Z:\Incoming\.stfolder goto eject
if not exist Z:\Library\.stfolder goto eject
if not exist Z:\Music\.stfolder goto eject
if not exist Z:\Pictures\.stfolder goto eject
if not exist Z:\Software\.stfolder goto eject
if not exist Z:\Source\.stfolder goto eject
if not exist Z:\Videos\.stfolder goto eject

:: Do the backup using robocopy.
:: Note: needs admin privileges.
echo Starting backup of Syncthing drive to Z:\
robocopy S:\ Z:\ /mir /b /xj /r:0 /log:"c:\Users\rubin\Desktop\backup-syncthing.log"
goto done

:: Eject, eject, eject!
:eject
echo Didn't find expected folders on backup target, exiting...

:: Done with the backup.
:done
echo Finished backup of Syncthing drive to Z:\
