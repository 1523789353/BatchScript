@echo off
for /f %%i in ('"reg query "HKCU\Software\PremiumSoft\NavicatPremium" /s | findstr /L Registration"') do (
    reg delete %%i /va /f
)
for /f %%i in ('"reg query "HKCU\Software\Classes\CLSID" /s | findstr /E Info"') do (
    reg delete %%i /va /f
)
