@echo off

:: Will cause variables to be expanded at execution time rather than at parse time.
setlocal enabledelayedexpansion

:: Source PGO_CIDR, PGO_SECRET_NAME, PGO_K8S_DOMAIN, PGO_INSTANCE from ~/.pgorc
if exist %USERPROFILE%\.pgorc (
    del /f/q %TEMP%%\pgo-wrapper-pgorc.bat > nul 2>&1
    echo @echo off>> %TEMP%%\pgo-wrapper-pgorc.bat
    for /f "tokens=*" %%a in (%USERPROFILE%\.pgorc) do (
        set line=set %%a
        set line=!line:'=!
        set line=!line:"=!
        echo !line!>> %TEMP%%\pgo-wrapper-pgorc.bat
    )

    :: Source generated pgorc settings and remove.
    call %TEMP%%\pgo-wrapper-pgorc.bat
    del /f/q %TEMP%%\pgo-wrapper-pgorc.bat > nul 2>&1

    :: Extract network from PGO_CIDR.
    for /f "tokens=1 delims=/" %%a in ("!PGO_CIDR!") do set network=%%a

    :: Check if network is configured, only continue if so.
    for /f "usebackq tokens=*" %%a in (`route print -4 ^| findstr !network!`) do set check=%%a
    if defined check (

        :: Set-up API server URL.
        for /f "usebackq tokens=3" %%a in (`kubectl config get-contexts ^| findstr ^*`) do set PGO_TARGET_CLUSTER=%%a
        set PGO_APISERVER_URL=https://!PGO_INSTANCE!.!PGO_TARGET_CLUSTER!.!PGO_K8S_DOMAIN!

        :: Extract target namespace.
        for /f "usebackq delims=" %%a in (`echo %*`) do set "precut1=%%a"
        for /f "tokens=2 delims=¬" %%a in ("!precut1:-n =¬!") do set precut2=%%a
        for /f "tokens=1" %%a in ("!precut2!") do set NS=%%a

        if defined NS (

            :: Set PGOUSERNAME.
            kubectl get secret -n !NS! !PGO_SECRET_NAME! -o jsonpath="{.data.username}"> %TEMP%\pgo-wrapper-username-base64.txt
            for /f "usebackq tokens=*" %%a in (`type %TEMP%\pgo-wrapper-username-base64.txt`) do set PGOUSERNAME_BASE64=%%a
            del /f/q %TEMP%\pgo-wrapper-username-base64.txt > nul 2>&1
            for /f "usebackq tokens=*" %%a in (`echo !PGOUSERNAME_BASE64! ^| openssl enc -base64 -d`) do set PGOUSERNAME=%%a

            :: Set PGOUSERPASS.
            kubectl get secret -n !NS! !PGO_SECRET_NAME! -o jsonpath="{.data.password}"> %TEMP%\pgo-wrapper-userpass-base64.txt
            for /f "usebackq tokens=*" %%a in (`type %TEMP%\pgo-wrapper-userpass-base64.txt`) do set PGOUSERPASS_BASE64=%%a
            del /f/q %TEMP%\pgo-wrapper-userpass-base64.txt > nul 2>&1
            for /f "usebackq tokens=*" %%a in (`echo !PGOUSERPASS_BASE64! ^| openssl enc -base64 -d`) do set PGOUSERPASS=%%a

        )

        :: A few preferences.
        set DISABLE_TLS=true

        pgo %*
    )

    ) else (
        echo Target network !PGO_CIDR! not available, can't reach operator, aborting..
        exit /b 1
    )

) else (
    exit /b 1
)
