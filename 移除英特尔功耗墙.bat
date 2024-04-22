@echo off
cd /d "%~dp0"
call :main %*
exit /b %ErrorLevel%

:main
    call :isAdmin
    if not "%ErrorLevel%" == "0" (
        call :elevate "%~dpnx0" %*
        exit /b 1
    )

    set "key.Policy=HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
    set "counter.driver=1"
    set "key.DenyDeviceIDs=HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\DenyDeviceIDs"
    set "counter.instance=1"
    set "key.DenyInstanceIDs=HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\DenyInstanceIDs"

    echo=正在禁用英特尔功耗墙

    :: 启用组策略:阻止安装设备
    call :enablePolicy

    :: 移除 英特尔功耗墙
    call :denyDevice "*INT3400"
    call :denyDevice "*INT3402"
    call :denyDevice "*INT3403"
    call :denyDevice "*INT3404"
    call :denyDevice "*INT3407"
    call :denyDevice "*INT3409"
    call :denyDevice "*INTC1040"
    call :denyDevice "*INTC1041"
    call :denyDevice "*INTC1043"
    call :denyDevice "*INTC1044"
    call :denyDevice "*INTC1045"
    call :denyDevice "*INTC1046"
    call :denyDevice "*INTC10A0"
    call :denyDevice "*INTC10A1"
    call :denyDevice "PCI\VEN_8086&DEV_1603&CC_1180"
    call :denyDevice "PCI\VEN_8086&DEV_1903&CC_1180"
    call :denyDevice "PCI\VEN_8086&DEV_461D&CC_1180"
    call :denyDevice "PCI\VEN_8086&DEV_8A03&CC_1180"
    call :denyDevice "PCI\VEN_8086&DEV_9A03&CC_1180"
    call :denyDevice "PCI\VEN_8086&DEV_9C24&CC_1180"
    call :denyDevice "PCI\VEN_8086&DEV_A131&CC_1180"
    call :denyDevice "PCI\VEN_8086&DEV_A71D&CC_1180"
    :: 自定义: 移除 "高精度事件计时器"
    :: call :denyDevice "*PNP0103"

    :: 戴尔 Inspiron 15 7000 Gaming (7567) 特有的设置
    call :isDell7567
    if not "%ErrorLevel%" == "0" goto notDell7567
    :: 自定义: 移除 "英特尔(R)智音技术 OED", 与7567低音喇叭冲突
    :: call :denyDevice "INTELAUDIO\DSP_CTLR_DEV_A171&VEN_8086&DEV_0222&SUBSYS_00000022"
    :notDell7567

    call :denyInstance "ACPI\VEN_INT&DEV_3403"
    call :denyInstance "ACPI\INT3403"
    call :denyInstance "*INT3403"
    call :denyInstance "ACPI\VEN_INT&DEV_3400"
    call :denyInstance "ACPI\INT3400"
    call :denyInstance "*INT3400"
    call :denyInstance "PCI\VEN_8086&DEV_1903&SUBSYS_07BE1028&REV_05"
    call :denyInstance "PCI\VEN_8086&DEV_1903&SUBSYS_07BE1028"
    call :denyInstance "PCI\VEN_8086&DEV_1903&CC_118000"
    call :denyInstance "PCI\VEN_8086&DEV_1903&CC_1180"

    :: 禁用 "Intel(R) Dynamic Tuning service" 服务
    call :disableServices
    echo=更新组策略...
    2>&1 >nul gpupdate /force
    pause
exit /b 0

:isAdmin <检查管理员权限>
    powershell /c "([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)"|>nul findstr True
exit /b %ErrorLevel%

:elevate <请求管理员权限>
    set "elevate.program=%~1"
    set "elevate.arguments=%~2"

    echo=请求管理员权限...
    if defined elevate.arguments goto elevate__withelevate.arguments
    powershell -Command "Start-Process -Verb RunAs '%elevate.program%'"
exit /b %ErrorLevel%
    :elevate__withArguments
    powershell -Command "Start-Process -Verb RunAs '%elevate.program%' -ArgumentList '%elevate.arguments%'"
exit /b %ErrorLevel%

:isDell7567
    wmic csproduct get name /value|>nul findstr "^Name=Inspiron 15 7000 Gaming$"
    if not "%ErrorLevel%" == "0" exit /b 1
    wmic cpu get name /value|>nul findstr "^Name=Intel(R) Core(TM) i7-7700HQ CPU @ 2.80GHz$"
    if not "%ErrorLevel%" == "0" exit /b 1
exit /b 0

:enablePolicy <启用组策略:阻止安装设备>
    echo=启用组策略:阻止安装设备
    2>&1 >nul reg add "%key.Policy%" /v "DenyDeviceIDs" /t REG_DWORD /d 1 /f
    2>&1 >nul reg add "%key.Policy%" /v "DenyDeviceIDsRetroactive" /t REG_DWORD /d 1 /f
    2>&1 >nul reg add "%key.Policy%" /v "DenyInstanceIDs" /t REG_DWORD /d 1 /f
    2>&1 >nul reg add "%key.Policy%" /v "DenyInstanceIDsRetroactive" /t REG_DWORD /d 0 /f
    :: 删除先前阻止安装的设备
    2>&1 >nul reg delete "%key.DenyDeviceIDs%" /va /f
    2>&1 >nul reg delete "%key.DenyInstanceIDs%" /va /f
exit /b 0

:denyDevice <添加阻止安装的驱动>
    set "denyDevice.address=%~1"

    echo=禁用驱动, 并阻止驱动再次安装: %denyDevice.address:&=^&%

    :: 尝试禁用驱动
    2>&1 >nul pnputil /disable-device "%denyDevice.address%"
    :: devcon disable "%denyDevice.address%"
    :: 尝试删除驱动 (好像会重新装回来)
    :: 2>&1 >nul pnputil /remove-device "%denyDevice.address%"
    :: devcon remove "%denyDevice.address%"
    :: 阻止安装驱动
    2>&1 >nul reg add "%key.DenyDeviceIDs%" /v "%counter.driver%" /t REG_SZ /d "%denyDevice.address%" /f

    set /a "counter.driver+=1"
exit /b 0

:denyInstance <添加阻止安装的设备>
    set "denyInstance.address=%~1"

    echo=禁用设备, 并阻止设备再次安装: %denyInstance.address:&=^&%

    :: 尝试禁用设备
    2>&1 >nul pnputil /disable-device "%denyInstance.address%"
    :: devcon disable "%denyInstance.address%"
    :: 尝试删除设备 (好像会重新装回来)
    :: 2>&1 >nul pnputil /remove-device "%denyInstance.address%"
    :: devcon remove "%denyInstance.address%"
    :: 阻止安装设备
    2>&1 >nul reg add "%key.DenyInstanceIDs%" /v "%counter.instance%" /t REG_SZ /d "%denyInstance.address%" /f

    set /a "counter.instance+=1"
exit /b 0

:disableServices <禁用服务>
    echo=禁用服务: "Intel(R) Dynamic Tuning service"
    2>&1 >nul sc config esifsvc start= disabled
    2>&1 >nul sc stop esifsvc
exit /b 0
