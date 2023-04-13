@set "OSArch=x86"
@wmic os get osarchitecture|>nul findstr 64
@if "%errorlevel%" == "0" (
    set "OSArch=x64"
)
