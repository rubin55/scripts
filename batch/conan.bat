@echo off

:: Will cause variables to be expanded at execution time rather than at parse time.
setlocal enabledelayedexpansion

:: Set conan HOME.
set CONAN_HOME=%ProgramFiles(x86)%\Conan\conan

:: Set conan EXECUTABLE.
set CONAN_EXECUTABLE=%CONAN_HOME%\conan.exe

:: Set msys HOME.
set MSYS_HOME=C:\MSYS

:: Set mingw64 HOME.
set MINGW64_HOME=%MSYS_HOME%\mingw64

:: Append path.
set PATH=%CONAN_HOME%;%MINGW64_HOME%\bin;%MSYS_HOME%\usr\bin;%PATH%

:: Invoke conan directly.
"%CONAN_EXECUTABLE%" %*

