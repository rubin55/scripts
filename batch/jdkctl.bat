@echo off

:: Initialize variables
set "root=C:\Program Files\Java"
set cmd=%1
set jdk=%2
set hit=
set char=
set add=

2>nul call :%cmd%
if errorlevel 1 call :def
exit/b

:list
  dir /b /on "%root%"
  goto :end

:show
  for /f "usebackq tokens=*" %%x in (`where java`) do echo %%x
  goto :end

:use
  :: Check if passed argument is an actually installed JDK, if not error out.
  for /f "usebackq tokens=*" %%x in (`dir /b /on "%root%"`) do if [%%x] equ [%jdk%] (set hit=%%x)
  if not defined hit goto :error

  :: Remove any Java from the path.
  setlocal enabledelayedexpansion
  for /f "usebackq tokens=*" %%x in (`dir /b /on "%root%"`) do (set PATH=!PATH:%root%\%%x\bin;=!)
  endlocal & set PATH=%PATH%

  :: Add selected Java to the path.
  set char=%PATH:~-1%
  if "%char%" == ";" (set "add=%root%\%hit%\bin;") else (set "add=;%root%\%hit%\bin;")
  set PATH=%PATH%%add%
  goto :end

:def
  echo Usage: jdkctl list^|show^|use
  echo.
  goto :end

:error
  echo Error: JDK %jdk% not installed.
  echo.
  goto :end

:end
  set root=
  set cmd=
  set jdk=
  set hit=
  set char=
  set add=
  goto :eof
