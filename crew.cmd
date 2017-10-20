@echo off

setlocal

set GEM_HOME=
set GEM_PATH=

set CREWFILEDIR=%~dp0
set CREWHOSTOS=windows

if not defined SSL_CERT_FILE (
    set SSL_CERT_FILE=%CREWFILEDIR%etc\ca-certificates.crt
)

if not defined CREW_NDK_DIR (
    set CREW_NDK_DIR=%CREWFILEDIR%..
)

set CREWHOSTCPU=-x86_64
if not exist %CREW_NDK_DIR%\prebuilt\windows%CREWHOSTCPU% (
   set CREWHOSTCPU=
)

if not defined CREW_TOOLS_DIR (
   set CREW_TOOLS_DIR=%CREW_NDK_DIR%\prebuilt\windows%CREWHOSTCPU%
)

rem set CREW
rem set GIT

set PATH=%CREW_TOOLS_DIR%\bin;%PATH%
%CREW_TOOLS_DIR%\bin\ruby.exe -W0 %CREWFILEDIR%crew.rb %*

if exist %CREW_NDK_DIR%\postpone (
    echo Start postponed upgrade process
    call %CREW_NDK_DIR%\postpone\upgrade.cmd
    echo = Cleaning up
    rd /q/s %CREW_NDK_DIR%\postpone
)

endlocal

exit /b %errorlevel%
