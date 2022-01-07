@echo off

:: Script: eject_tapes.cmd
:: Version: 1.1
:: Created by: Eric van der Horst (Symantec)
:: Modified by: Rubin Simons (RAAF Technology)
:: Purpose: Eject the tapes that were written the last X hours

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
set LOGDIR=D:\Scripts\logs\_eject-logs
set PATH=%PATH%;%NBUBIN%;%NBUPATH%;%NBUCMD%;%NBUVOL%

:: Set logfile:
set LOGFILE=%LOGDIR%\eject_tapes-%LOGDATE%.txt
set TEMPLOGFILE=%LOGDIR%\tmp-eject-tapes.txt

:: Initialize main variables:
set HOURSAGO=%1
set COUNTER=1
set EJECT_STRING=""
set MEDIAID=""

:: Create list of tape id's which were used in the last 24 hours
"%NBUBIN%\admincmd\bpimagelist.exe" -media -idonly -hoursago %HOURSAGO% -M %MASTERSRV% > %TEMPLOGFILE%

call :Do_printheader

:: Process list with medialabels to eject
for /f %%A in (%TEMPLOGFILE%) do call :Do_settings %%A
if %EJECT_STRING%=="" echo No media was found to export >> %LOGFILE%

"%NBUVOL%\vmchange.exe" -res -multi_eject -rt tld -mt hcart2 -rn %ROBOTNR% -rh %ROBOTHOST% -single_cycle -ml %EJECT_STRING% >> %LOGFILE%

:: Write out footer:
echo. >> %LOGFILE%
echo --------------- >> %LOGFILE%
echo End of ejecting tapes >> %LOGFILE%

:: Run blat:
blat D:\Scripts\msgbody_eject.txt -s "NetBackup eject log of %LOGDATE%" -t someone@example.com,someone.else@example.com -i NetBackup -server smtp.example.com -bodyF %LOGFILE% -q

GOTO :EOF

:: Do_settings: take a media id, run bpmedialist, determine eject_string:
:Do_settings
    set MEDIAID=%1
    if "%COUNTER%"=="1" bpmedialist -mlist -m %MEDIAID% >> %LOGFILE%
    if "%COUNTER%"=="2" bpmedialist -mlist -m %MEDIAID% | find /i /v "Server Group" | find /i /v "images" >> %LOGFILE%
    if "%COUNTER%"=="1" set EJECT_STRING=%MEDIAID%
    if "%COUNTER%"=="2" set EJECT_STRING=%EJECT_STRING%:%MEDIAID%
    set COUNTER=2
GOTO :EOF

:: Do_printheader: print a friendly message:
:Do_printheader
    echo on
    echo  Goedemorgen,> %LOGFILE%
    echo. >> %LOGFILE%
    echo  Onderstaande tapes voor BLAH staan klaar in de >> %LOGFILE%
    echo  export slots van de ROBOT library en kunnen >> %LOGFILE%
    echo  worden aangeboden voor transport. >> %LOGFILE%
    echo. >> %LOGFILE%
    echo  Bedankt! >> %LOGFILE%
    echo. >> %LOGFILE%
    echo  Met vriendelijke groet, >> %LOGFILE%
    echo  -- >> %LOGFILE%
    echo  Storage Team >> %LOGFILE%
    echo. >> %LOGFILE%
    echo. >> %LOGFILE%
    echo. >> %LOGFILE%
    echo Ejecting tapes >> %LOGFILE%
    echo --------------- >> %LOGFILE%
    echo off
GOTO :EOF

