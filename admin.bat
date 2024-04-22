@echo off
call :main %*
exit /b %ErrorLevel%

:main
    call :is_admin
    if "%ErrorLevel%" == "0" (
        echo=当前已有管理员权限
        exit /b 0
    )
    call :elevate "cmd" "/c @prompt 管理员$s$p$g && start /d "%cd%" /b /wait cmd /k %*"
exit /b 0

:is_admin <检查管理员权限>
    powershell -c "([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)"|>nul findstr True
exit /b %ErrorLevel%

:elevate <请求管理员权限>
    echo=请求管理员权限...
    powershell -c "Start-Process -Verb RunAs '%~1' -ArgumentList '%~2 '"
exit /b 0
