@echo off
call :main %*
exit /b %ErrorLevel%

:main <主函数>
    set "option=%~1"
    set "port=%~2"
    if "%port%" == "" (
        call :usage
        exit /b 1
    )

    if /i "%option%" == "-l" (
        call :list %port%
        exit /b 0
    )
    if /i "%option%" == "--list" (
        call :list %port%
        exit /b 0
    )
    if /i "%option%" == "-k" (
        call :kill %port%
        exit /b 0
    )
    if /i "%option%" == "--kill" (
        call :kill %port%
        exit /b 0
    )

    call :usage
exit /b 1

:usage <帮助信息>
    echo Usage: %~nx0 ^<option^> ^<port^>
    echo.
    echo Options:
    echo   -l   --list  列出占用端口进程的PID
    echo   -k   --kill  杀死占用端口进程
    echo.
exit /b 0

:list <列出占用端口进程的PID>
    set "port=%~1"
    for /f "tokens=5 delims= " %%i in ('netstat -ano^|findstr /r /c:":%port% .*LISTENING"') do (
        echo %%i
    )
exit /b 0

:kill <杀死占用端口进程>
    set "port=%~1"
    for /f "tokens=5 delims= " %%i in ('netstat -ano^|findstr /r /c:":%port% .*LISTENING"') do (
        taskkill /f /t /pid %%i
    )
exit /b 0
