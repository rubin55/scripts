@echo off
set PATH=%PATH%;C:\Program Files\Emacs\bin;%USERPROFILE%\AppData\Local\Programs\Emacs\bin
tasklist /FI "IMAGENAME eq emacs.exe" 2>NUL | find /I /N "emacs.exe" >NUL
if "%ERRORLEVEL%"=="0" start "dummy" /b "emacsclientw.exe" %*
if "%ERRORLEVEL%"=="1" start "dummy" /b "runemacs.exe" %*
