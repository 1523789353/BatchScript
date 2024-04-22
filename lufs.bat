@echo off
call :main %*
exit /b %ErrorLevel%

:main
    :: 新闻/谈话: -18 LUFS
    :: 流行音乐: -16 LUFS
    :: 混合格式: -17 LUFS
    :: 体育运动: -17 LUFS
    :: 戏剧: -17 LUFS

    :: 在有损编码（lossy encoding）之前，真峰值不应超过-1dBTP。
    :: 这是因为有损编码容易带来峰值过冲（peak overshoot），而且一般码率越低过冲的可能幅度越大。

    :: 综合响度、真峰值、响度范围
    set loudness=-16
    set truepeak=-0.5
    set loudrange=11

    if "%~1" == "" (
        echo=用法: %~n0 ^<音频文件^>
        exit /b 1
    )

    if not exist "%~1" (
        echo=文件 "%~1" 不存在
        exit /b 1
    )

    echo=正在处理文件 "%~1"
    echo=

    call :eval ffprobe -v error -select_streams a:0 -show_entries "stream=bits_per_sample,bits_per_raw_sample" -of "default=noprint_wrappers=1:nokey=1" "%~1"
    set bits=%eval.result[0]%
    set bits_raw=%eval.result[1]%

    if "%bits%" == "N/A" set bits=0
    if "%bits_raw%" == "N/A" set bits_raw=0

    if "%bits%" == "%bits_raw%" (
        set "bit_depth=%bits%"
    ) else (
        set /a "bit_depth=%bits% + %bits_raw%"
    )

    if "%bit_depth%" == "0" (
        echo 原始音频位深为 N/A
    ) else (
        echo 原始音频位深为 %bit_depth%
    )

    :: 转换至至少 24 位 PCM 以进行处理
    if %bit_depth% leq 24 (
        set bit_pcm=24
    ) else (
        set bit_pcm=%bit_depth%
    )
    echo 使用 %bit_pcm% 位进行规范化处理

    :: 第一遍：分析音频流并获取规范化参数
    set "eval.cmdline=ffmpeg -hide_banner -i "%~1" -c:a:0 pcm_s%bit_pcm%le -af "loudnorm=I=%loudness%:TP=%truepeak%:LRA=%loudrange%:print_format=json" -f null - 2>&1 | findstr "\{ \"\ \:\ \" }" | find /v "#""
    call :eval %%%%eval.cmdline%%%%

    call :readVal "eval.result[1]" II
    call :readVal "eval.result[2]" ITP
    call :readVal "eval.result[3]" ILRA
    call :readVal "eval.result[4]" IT
    call :readVal "eval.result[5]" OI
    call :readVal "eval.result[6]" OTP
    call :readVal "eval.result[7]" OLRA
    call :readVal "eval.result[8]" OT
    call :readVal "eval.result[9]" NT
    call :readVal "eval.result[10]" TO

    echo=
    echo 输入综合响度: %II% LUFS
    echo 输入真峰值:   %ITP% dBTP
    echo 输入响度范围: %ILRA% LU
    echo 输入阈值:     %IT% LUFS
    echo 输出综合响度: %OI% LUFS
    echo 输出真峰值:   %OTP% dBTP
    echo 输出响度范围: %OLRA% LU
    echo 输出阈值:     %OT% LUFS
    echo 标准化类型:   %NT%
    echo 目标偏移:     %TO% LU
    echo=

    :: 第二遍：应用参数对音频流进行规范化
    :: 如果处于动态模式，采样率将为 192kHz
    :: 将流传输给 QAAC 进行编码
    :: 自动通过内置 SoX 进行向下采样至 48kHz
    ffmpeg -hide_banner -y -i "%~1" -c:a pcm_s%bit_pcm%le -af "loudnorm=I=%loudness%:TP=%truepeak%:LRA=%loudrange%:measured_I=%II%:measured_tp=%ITP%:measured_LRA=%ILRA%:measured_thresh=%IT%:offset=%TO%:print_format=summary" -f wav "%~dpn1_%loudness%LUFS.wav" -v quiet
    echo=
exit /b

:readVal <in> <out>
    call set "readVal.pair=%%%~1%%"
    set "readVal.pair=%readVal.pair:*:=%"
    set "readVal.pair=%readVal.pair:*"=%"
    set "readVal.pair=%readVal.pair:"=%"
    set "%~2=%readVal.pair:,=%"
exit /b

:eval
    if defined eval.line (
        for /l %%i in (0,1,%eval.line%) do (
            set "eval.result[%%i]="
        )
    )
    set eval.line=0
    for /f "delims=" %%i in ('%*') do (
        call set "eval.result[%%eval.line%%]=%%i"
        set /a eval.line+=1
    )
exit /b
