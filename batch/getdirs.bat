@echo off

:: Will cause variables to be expanded at execution time rather than at parse time.
setlocal enabledelayedexpansion

:: Determine current directory.
for /f "usebackq tokens=*" %%a in (`cd`) do set cd=%%a

:: Set default config file.
set PGO_CONFIG=.pgorc

:: Set default config file location.
set config=%USERPROFILE%\%file%

:: Check for .pgorc in current directory first.
if exist %cd%\%file% call :found %cd%\%file%

:: Descent into subdirs, find .pgorc files.
call :descent "%cd%"
goto :eof

:descent
setlocal
set substract=%~1
set input=%cd%
set match=%substract%
set replace=
set result=!input:%match%=%replace%!
if defined result (
    if exist %result%%file% (
        call :found %result%%file%
    ) else (
        for /F "tokens=1* delims=\" %%f in ("%substract%") do (
            if not "%%g" == "" call :descent "%%g"
        )
    )
)
endlocal
goto :eof

:found
set PGO_CONFIG=%1

goto :eof
