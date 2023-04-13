:: 用法:
:: getOSVersion
:: 返回值: OSVerNum OSVerName
set "OSVerName=Unsupported"
call eval "wmic os get version|findstr /r [0-9]" OSVerNum
call :check_version 5.1 "Windows XP"
call :check_version 5.2 "Windows XP x64 / Server 2003"
call :check_version 6.0 "Windows Vista / Server 2008"
call :check_version 6.1 "Windows 7 / Server 2008 R2"
call :check_version 6.2 "Windows 8 / Server 2012"
call :check_version 6.3 "Windows 8.1 / Server 2012 R2"
call :check_version 10.0 "Windows 10 / 11 / Server 2019 / Server 2022"
if "%OSVerName%" == "Unsupported" (
    set "OSVerNum=0.0"
)
exit /b 0

:check_version
    echo=%OSVerNum%|>nul findstr "^%~1"
    if "%errorlevel%" == "0" (
        set "OSVerNum=%~1"
        set "OSVerName=%~2"
    )
exit /b
