@echo off
rem Generated by JetBrains Toolbox 1.24.11947 at 2022-05-12T08:54:39.750721700

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

start "" %waitarg% C:\Users\rubin\AppData\Local\JetBrains\Toolbox\apps\PyCharm-P\ch-0\221.5080.212\bin\pycharm64.exe %ideargs%