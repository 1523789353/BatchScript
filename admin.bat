@echo off
call :main %*
exit /b %ErrorLevel%

:main
    call :is_admin
    if "%ErrorLevel%" == "0" (
        echo=��ǰ���й���ԱȨ��
        exit /b 0
    )
    call :elevate "cmd" "/c @prompt ����Ա$s$p$g && start /d "%cd%" /b /wait cmd /k %*"
exit /b 0

:is_admin <������ԱȨ��>
    powershell -c "([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)"|>nul findstr True
exit /b %ErrorLevel%

:elevate <�������ԱȨ��>
    echo=�������ԱȨ��...
    powershell -c "Start-Process -Verb RunAs '%~1' -ArgumentList '%~2 '"
exit /b 0
