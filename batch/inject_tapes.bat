@echo off

:: Script: inject_tapes.cmd
:: Version: 1.1
:: Created by: Eric van der Horst (Symantec)
:: Modified by: Rubin Simons (RAAF Technology)
:: Purpose: Inject the tapes that were placed in the MAP

:: Number of mail access slots:
set MAPS=18

:: Which robot:
set ROBOTNR=0

:: Which controller:
set ROBOTHOST=some-netbackup-host

:: Which master server:
set MASTERSRV=some-netbackup-host

:: Determine date for log:
for %%i in (%date%) do set LOGDATE=%%i

:: Change "/" in "-" and change to day-month-year order:
echo %LOGDATE% | find "/" && for /f "delims=/ tokens=1-3" %%i in ('echo %LOGDATE%') do @set LOGDATE=%%j-%%i-%%k
for /f "delims=- tokens=1-3" %%i in ('echo %LOGDATE%') do @set LOGDATE=%%k-%%j-%%i

:: Set path:
set NBUPATH=D:\Program Files\Veritas\NetBackup
set NBUBIN=%NBUPATH%\bin
set NBUCMD=%NBUBIN%\admincmd
set NBUVOL=D:\Program Files\Veritas\Volmgr\bin
set LOGDIR=D:\Scripts\logs\_inject-logs
set PATH=%PATH%;%NBUBIN%;%NBUPATH%;%NBUCMD%;%NBUVOL%

:: Set logfile:
set LOGFILE=%LOGDIR%\inject_tapes-%LOGDATE%.txt

:: Write out header:
echo Injecting tapes > %LOGFILE%
echo --------------- >> %LOGFILE%
echo . >> %LOGFILE%
echo The following tapes are injected into the robot >> %LOGFILE%

"%NBUVOL%\vmupdate.exe" -rt tld -rn %ROBOTNR% -rh %ROBOTHOST% -mt hcart -use_barcode_rules -empty_map >> %LOGFILE%

:: Write out footer:
echo. >> %LOGFILE%
echo --------------- >> %LOGFILE%
echo End of injecting tapes >> %LOGFILE%

:: Run blat:
blat D:\Scripts\msgbody_inject.txt -s "NetBackup inject log of %LOGDATE%" -t someone@example.com -i NetBackup -server smtp.example.com -bodyF %LOGFILE% -q

