@echo off

set cmd=%1

2>nul call :%cmd%
if errorlevel 1 call :def
exit/b

:start
  echo Starting Oracle Database Services
  sc start OracleServiceORACLE
  sc start OracleOraDB12Home1TNSListener
  goto :end

:stop
  echo Stopping Oracle Database Services
  sc stop OracleOraDB12Home1TNSListener
  sc stop OracleServiceORACLE
  goto :end

:status
  echo Showing status for Oracle Database Services
  sc query OracleOraDB12Home1TNSListener
  sc query OracleServiceORACLE
  goto :end

:def
  echo Usage: oractl start^|stop^|status
  goto :end

:end
  ver > nul
  goto :eof
