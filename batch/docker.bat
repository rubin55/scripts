@echo off

:: Set docker executable.
set docker_EXECUTABLE=docker.exe

:: Invoke docker with build override.
if [%1]==[build] goto build
if [%1]==[run] goto run
"%docker_EXECUTABLE%" %*
goto :eof

:build
echo Build argument passed, rewriting command to:
echo "%DOCKER_EXECUTABLE%" build --build-arg PROXY_HOST=%PROXY_HOST% --build-arg PROXY_PORT=%PROXY_PORT% --build-arg PROXY_NONE=%PROXY_NONE% --build-arg http_proxy=http://%PROXY_HOST%:%PROXY_PORT% --build-arg https_proxy=http://%PROXY_HOST%:%PROXY_PORT% --build-arg no_proxy=%PROXY_NONE% --build-arg HTTP_PROXY=http://%PROXY_HOST%:%PROXY_PORT% --build-arg HTTPS_PROXY=http://%PROXY_HOST%:%PROXY_PORT% --build-arg NO_PROXY=%PROXY_NONE% --build-arg JAVA_TOOL_OPTIONS="-XX:+UseConcMarkSweepGC -XX:InitialRAMPercentage=60.0 -XX:MaxRAMPercentage=80.0 -XX:MinHeapFreeRatio=25 -XX:MaxHeapFreeRatio=50 -Dhttp.proxyHost=%PROXY_HOST% -Dhttp.proxyPort=%PROXY_PORT% -Dhttps.proxyHost=%PROXY_HOST% -Dhttps.proxyPort=%PROXY_PORT% -Dsun.zip.disableMemoryMapping=true" %2 %3 %4 %5 %6 %7 %8 %9
timeout 4
"%DOCKER_EXECUTABLE%" build --build-arg PROXY_HOST=%PROXY_HOST% --build-arg PROXY_PORT=%PROXY_PORT% --build-arg PROXY_NONE=%PROXY_NONE% --build-arg http_proxy=http://%PROXY_HOST%:%PROXY_PORT% --build-arg https_proxy=http://%PROXY_HOST%:%PROXY_PORT% --build-arg no_proxy=%PROXY_NONE% --build-arg HTTP_PROXY=http://%PROXY_HOST%:%PROXY_PORT% --build-arg HTTPS_PROXY=http://%PROXY_HOST%:%PROXY_PORT% --build-arg NO_PROXY=%PROXY_NONE% --build-arg JAVA_TOOL_OPTIONS="-XX:+UseConcMarkSweepGC -XX:InitialRAMPercentage=60.0 -XX:MaxRAMPercentage=80.0 -XX:MinHeapFreeRatio=25 -XX:MaxHeapFreeRatio=50 -Dhttp.proxyHost=%PROXY_HOST% -Dhttp.proxyPort=%PROXY_PORT% -Dhttps.proxyHost=%PROXY_HOST% -Dhttps.proxyPort=%PROXY_PORT% -Dsun.zip.disableMemoryMapping=true" %2 %3 %4 %5 %6 %7 %8 %9
goto :eof

:run
echo Run argument passed, rewriting command to:
echo "%DOCKER_EXECUTABLE%" run --rm --env PROXY_HOST=%PROXY_HOST% --env PROXY_PORT=%PROXY_PORT% --env PROXY_NONE=%PROXY_NONE% --env http_proxy=http://%PROXY_HOST%:%PROXY_PORT% --env https_proxy=http://%PROXY_HOST%:%PROXY_PORT% --env no_proxy=%PROXY_NONE% --env HTTP_PROXY=http://%PROXY_HOST%:%PROXY_PORT% --env HTTPS_PROXY=http://%PROXY_HOST%:%PROXY_PORT% --env NO_PROXY=%PROXY_NONE% --env JAVA_TOOL_OPTIONS="-XX:+UseConcMarkSweepGC -XX:InitialRAMPercentage=60.0 -XX:MaxRAMPercentage=80.0 -XX:MinHeapFreeRatio=25 -XX:MaxHeapFreeRatio=50 -Dhttp.proxyHost=%PROXY_HOST% -Dhttp.proxyPort=%PROXY_PORT% -Dhttps.proxyHost=%PROXY_HOST% -Dhttps.proxyPort=%PROXY_PORT% -Dsun.zip.disableMemoryMapping=true" %2 %3 %4 %5 %6 %7 %8 %9
timeout 4
"%DOCKER_EXECUTABLE%" run --rm --env PROXY_HOST=%PROXY_HOST% --env PROXY_PORT=%PROXY_PORT% --env PROXY_NONE=%PROXY_NONE% --env http_proxy=http://%PROXY_HOST%:%PROXY_PORT% --env https_proxy=http://%PROXY_HOST%:%PROXY_PORT% --env no_proxy=%PROXY_NONE% --env HTTP_PROXY=http://%PROXY_HOST%:%PROXY_PORT% --env HTTPS_PROXY=http://%PROXY_HOST%:%PROXY_PORT% --env NO_PROXY=%PROXY_NONE% --env JAVA_TOOL_OPTIONS="-XX:+UseConcMarkSweepGC -XX:InitialRAMPercentage=60.0 -XX:MaxRAMPercentage=80.0 -XX:MinHeapFreeRatio=25 -XX:MaxHeapFreeRatio=50 -Dhttp.proxyHost=%PROXY_HOST% -Dhttp.proxyPort=%PROXY_PORT% -Dhttps.proxyHost=%PROXY_HOST% -Dhttps.proxyPort=%PROXY_PORT% -Dsun.zip.disableMemoryMapping=true" %2 %3 %4 %5 %6 %7 %8 %9
goto :eof
