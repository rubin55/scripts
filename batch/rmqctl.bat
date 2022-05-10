@echo off

set svc=rabbitmq
set cmd=%1

2>nul call :%cmd%
if errorlevel 1 call :def
exit/b

:start
  echo Starting RabbitMQ Messaging Service
  sc start %svc%
  call rabbitmqctl start_app
  goto :end

:stop
  echo Stopping RabbitMQ Messaging Service
  call rabbitmqctl stop
  sc stop %svc%
  goto :end

:status
  echo Showing status for RabbitMQ Messaging Service
  sc query %svc%

  rem echo Showing status for RabbitMQ Application
  rem call rabbitmqctl status
  rem echo.
  goto :end

:def
  echo Usage: rmqctl start^|stop^|status
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
