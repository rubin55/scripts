@echo off
rem Generated by JetBrains Toolbox 1.24.12080 at 2022-06-26T01:47:54.577684100

set waitarg=
set ideargs=

:next
set "passwait="
if "%~1"=="--wait" set passwait=1
if "%~1"=="-w" set passwait=1
if defined passwait (set waitarg=/wait)
if not "%~1"=="" (
  if defined passwait (set "ideargs=%ideargs%--wait ") else (set "ideargs=%ideargs%%1 ")
  shift
  goto next
)

start "" %waitarg% C:\Users\rubin\AppData\Local\JetBrains\Toolbox\apps\datagrip\ch-0\221.5787.39\bin\datagrip64.exe %ideargs%