@echo off
2>&1 >nul fsutil dirty query %systemdrive%
if "%ErrorLevel%" == "0" (
    echo 当前已有管理员权限
    exit /b
)

echo 请正在请求管理员权限...
mshta vbscript:createobject("shell.application").shellexecute("cmd","/S /C ""prompt 管理员$s$p$g&start /D ""%cd%"" /B /Wait cmd""","","runas",1)(window.close)
exit
