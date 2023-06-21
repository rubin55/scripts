@echo off

set svc=postgresql
set cmd=%1

2>nul call :%cmd%
if errorlevel 1 call :def
exit/b

:start
  echo Starting PostgresSQL Database Service
  sc start %svc%
  goto :end

:stop
  echo Stopping PostgresSQL Database Service
  sc stop %svc%
  goto :end

:status
  echo Showing status for PostgresSQL Database Service
  sc query %svc%
  goto :end

:def
  echo Usage: pgctl start^|stop^|status
  echo.
  echo Note: if you have subinacl, you might want to:
  echo subinacl /service %svc% /grant=COMPUTER_NAME\GROUP_NAME=TOP
  echo.
  echo Note: if you have setacl, you might want to:
  echo setacl -on "\\COMPUTER_NAME\%svc%" -ot srv -actn ace -ace "n:COMPUTER_NAME\GROUP_NAME;p:start_stop"
  goto :end


:end
  ver > nul
  goto :eof
