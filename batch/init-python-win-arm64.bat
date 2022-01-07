@echo off

SET PYTHON_DIR=C:\PROGRA~1\Python\python39
SET PATH=%PYTHON_DIR%;%PYTHON_DIR%\Scripts;%PATH%

set VCVARSALL="C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
set CL_PATH="C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30037\bin\Hostx86\arm64\cl.exe"
set MC_PATH="C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\arm64\mc.exe"

call %VCVARSALL% x86_arm64 10.0.19041.0


python --version
IF %ERRORLEVEL% NEQ 0 EXIT /b 1

echo "Installing setuptools, pip and wheel"
del /f /s /q setuptools 1>nul 2>nul
rmdir /s /q setuptools 1>nul 2>nul
git clone https://github.com/rubin55/setuptools 1>nul
IF %ERRORLEVEL% NEQ 0 EXIT /b 1

pushd setuptools
    git checkout win_arm64
    echo "Installing setuptools"
    REM python.exe bootstrap.py 1>nul 2>nul
    REM IF %ERRORLEVEL% NEQ 0 EXIT /b 1

    %CL_PATH% /D "GUI=0" /D "WIN32_LEAN_AND_MEAN" /D _ARM64_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE launcher.c /O2 /link /MACHINE:ARM64 /SUBSYSTEM:CONSOLE /out:setuptools/cli-arm64.exe
    IF %ERRORLEVEL% NEQ 0 EXIT /b 1

    EXIT /b 1

    python.exe setup.py install 1>nul
    IF %ERRORLEVEL% NEQ 0 EXIT /b 1
popd

echo "Installing pip"
python.exe -m easy_install https://github.com/pypa/pip/archive/21.2.4.tar.gz 1>nul 2>nul
IF %ERRORLEVEL% NEQ 0 EXIT /b 1

echo "Installing wheel"
python.exe -m easy_install https://github.com/ader1990/pip/archive/20.3.dev1.win_arm64.tar.gz 1>nul 2>nul
IF %ERRORLEVEL% NEQ 0 EXIT /b 1

echo "Installation completed"
