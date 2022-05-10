@echo off

set cmd=%1

set enable=C:\Users\rubin\Dropbox\Documents\Rubin\Various Documents\Automatic Proxy Settings - Enable.reg
set disable=C:\Users\rubin\Dropbox\Documents\Rubin\Various Documents\Automatic Proxy Settings - Disable.reg
2>nul call :%cmd%
if errorlevel 1 call :def
exit/b

:enable
  echo Enabling proxy using "%enable%"
  reg import "%enable%"
  goto :end

:disable
  echo Disabling proxy using "%disable%"
  reg import "%disable%"
  goto :end

:def
  echo Usage: proxy enable^|disable
  goto :end

:end
  ver > nul
  goto :eof
