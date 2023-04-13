@echo off
call :main %*
exit /b %ErrorLevel%

:main <主函数>
    cd /d "%~dp0"
    Title 扫描并修复

    call :check_admin
    if not "%ErrorLevel%" == "0" (
        call :require_admin %*
        exit /b 1
    )

    call :fixBCD
    ::call :fixWinRE
    call :fixSystemDrive
    call :fixSystemDism
    call :fixSystemSfc

    echo  ##### 修复完成...请自行重启系统!
    pause
exit /b 0

:check_admin <检查管理员权限>
    2>&1 >nul fsutil dirty query %systemdrive%
    set isAdmin=%ErrorLevel%
exit /b %isAdmin%

:require_admin <申请管理员权限>
    echo 请授予管理员权限
    start "" mshta vbscript:createobject("shell.application").shellexecute("%~dpnx0","%*","","runas",1)(window.close)
exit /b

:fixBCD <修复BCD>
    bcdboot %SystemRoot% /s %SystemDrive% /l zh-cn /f all
exit /b 0

:fixWinRE <修复WinRE>
    set "WinRE=%SystemDrive%\Recovery\WindowsRE"

    echo ##### 修复WinRE...

    :foundWinRE
    if not exist "%SystemDrive%\Recovery\WindowsRE" (
        echo ##### 未找到WinRE, 请指定WinRE路径
        set /p WinRE=WinRE路径:
        goto :foundWinRE
    )

    REAgentC /SetREImage /Path "%WinRE%"
    REAgentC /enable

    echo=
exit /b 0

:fixSystemDrive <修复系統盘>
    echo ##### 将于下一次系统重新启动时检查%SystemDrive%盘
    echo y|chkdsk /x /r /f %SystemDrive%
    echo=
exit /b 0

:fixSystemDism <Dism修复系统>
    echo ##### 使用Dism扫描并修复系统...
    DISM /Online /Cleanup-image /RestoreHealth
    :: Dism：依据wim修复
    :: DISM /Online /Cleanup-Image /RestoreHealth /Source:WIM:"D:\backup\Windows\install.wim":1
    echo=
exit /b 0

:fixSystemSfc <Sfc修复系统>
    echo ##### 使用sfc维护系统完整性...
    sfc /scannow
    echo=
exit /b 0
