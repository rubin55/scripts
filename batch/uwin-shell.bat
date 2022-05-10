@echo off


:: Set uwin HOME, regular style.
set UWIN_HOME=%~dp0

:: Set cmd.exe to use.
set UWIN_CMD=%COMSPEC%

:: Start a shell.
"%UWIN_CMD%" /c title UWIN Shell
"%UWIN_HOME%\u32\bin\login.exe"
