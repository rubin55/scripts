@echo off


:: Will cause variables to be expanded at execution time rather than at parse time.
setlocal enabledelayedexpansion

:: Convert the windows path of the home directory to non-colon backslashed style.
set input=\%HOMEDRIVE%%HOMEPATH%
set match=:
set replace=
set backslashed=!input:%match%=%replace%!

:: Convert non-colon backslashed style to forward slashes.
set input=%backslashed%
set match=\
set replace=/
set forwarded=!input:%match%=%replace%!

:: Set human HOME to MinGW or UWIN style path.
set HOME=%forwarded%

:: Set mingw HOME, regular style.
set MINGW_HOME=%~dp0

:: Save HOMEPATH (Seems to get mangled to backslash by msys, used by /etc/profile).
set ORIGINAL_HOMEPATH=%HOMEPATH%

:: Prepend MinGW executable directories to path.
set PATH=%MINGW_HOME%\bin;%MINGW_HOME%\msys\1.0\bin;%PATH%

:: Determine which cmd.exe to use
set MINGW_CMD=%COMSPEC%
if %PROCESSOR_ARCHITECTURE%==x86 set MINGW_CMD=%COMSPEC%
if %PROCESSOR_ARCHITECTURE%==AMD64 set MINGW_CMD=%WINDIR%\SysWOW64\cmd.exe

:: Start a shell.
"%MINGW_CMD%" /c title MinGW Shell
"%MINGW_CMD%" /c ""%MINGW_HOME%\msys\1.0\bin\bash" --login -i"
