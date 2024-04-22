@if defined eval.line @(
    @for /l %%i in (0,1,%eval.line%) do @(
        @set "eval.result[%%i]="
    )
)
@set eval.line=0
@for /f "delims=" %%i in ('%*') do @(
    @call set "eval.result[%%eval.line%%]=%%i"
    @set /a eval.line+=1
)
