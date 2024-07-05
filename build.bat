@setLocal
@set "dp0=%~dp0"
@set "dp0=%dp0:~0,-1%"
@if NOT EXIST "%dp0%/build/bin" mkdir "%dp0%/build/bin"
@odin build src\bin\args --out:build\bin\args.exe --vet --warnings-as-errors
