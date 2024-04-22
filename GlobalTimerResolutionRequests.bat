@echo off

:: https://sites.google.com/view/melodystweaks/misconceptions-about-timers-hpet-tsc-pmt

:: 2>nul >nul bcdedit /set useplatformtick no
:: 2>nul >nul bcdedit /set useplatformclock no
:: 2>nul >nul bcdedit /set disabledynamictick yes

2>nul >nul reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f
