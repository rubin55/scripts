@echo off

set addr="logic.home.local"
set PATH=%PATH%;C:\PROGRA~1\JAVA\HOTSPOT-JDK8\BIN

:test
ping -n 1 %addr% | find "TTL=" >nul
if errorlevel 1 (
    echo Local network not yet reachable, retrying..
    goto retry
) else (
    echo Local network reachable, continue..
    goto continue
)

:retry
ping 127.0.0.1 -n 2 >nul
goto test

:continue
echo Starting Universal Media Server..
cd "C:\Program Files\UMS"
start javaw -Xmx768M -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 -classpath update.jar;ums.jar net.pms.PMS
exit
