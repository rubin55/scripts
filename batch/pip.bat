@echo off

:: Set pip EXECUTABLE.
set PIP_EXECUTABLE=pip.exe

:: Invoke pip directly.
if [%1]==[install] goto install
"%PIP_EXECUTABLE%" %*
goto :eof
:install
echo Install argument passed, rewriting command to:
echo "%PIP_EXECUTABLE%" install --user --install-option="--install-scripts=%USERPROFILE%\.python\bin" %2 %3 %4 %5 %6 %7 %8 %9
timeout 4
"%PIP_EXECUTABLE%" install --user --install-option="--install-scripts=%USERPROFILE%\.python\bin" %2 %3 %4 %5 %6 %7 %8 %9
