@echo off

echo Execute a command in every subdirectory: for /f %%x in ('dir /b .') do cd %%x ^& dir ^& cd ..
echo.
echo Find files recursively in current directory: findstr /m /s "." *.json
echo.
echo Find files containing string recursively in current directory: findstr /spin /c:"some string" *
echo.
echo Count lines in output, like dir: dir /b ^| find /v /c ""
echo.
echo Open multiple files in Powershell: Get-ChildItem -Filter "README.md" -Recurse ^| %% {code $_.FullName}
