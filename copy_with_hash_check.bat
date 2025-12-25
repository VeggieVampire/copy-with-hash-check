@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Copy with Hash Check (Color + PASS fixed)

REM ===== ANSI COLORS =====
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "C_RESET=%ESC%[0m"
set "C_RED=%ESC%[31m"
set "C_GREEN=%ESC%[32m"
set "C_YELLOW=%ESC%[33m"
set "C_BLUE=%ESC%[34m"
set "C_MAGENTA=%ESC%[35m"
set "C_CYAN=%ESC%[36m"

REM ===== CONFIG =====
set "SOURCE=C:\SOURCE\"
set "DEST=E:\DEST"
set "HASHALG=SHA256"
set "LOG=%~dp0hashcopy_status.log"

echo %C_CYAN%=======================================%C_RESET%
echo %C_CYAN%Run:%C_RESET% %DATE% %TIME%
echo %C_CYAN%SOURCE:%C_RESET% "%SOURCE%"
echo %C_CYAN%DEST  :%C_RESET% "%DEST%"
echo %C_CYAN%ALG   :%C_RESET% %HASHALG%
echo %C_CYAN%LOG   :%C_RESET% "%LOG%"
echo %C_CYAN%=======================================%C_RESET%
echo.

>>"%LOG%" echo =======================================
>>"%LOG%" echo Run: %DATE% %TIME%
>>"%LOG%" echo SOURCE: "%SOURCE%"
>>"%LOG%" echo DEST  : "%DEST%"
>>"%LOG%" echo ALG   : %HASHALG%
>>"%LOG%" echo LOG   : "%LOG%"
>>"%LOG%" echo =======================================

REM ===== PRECHECKS =====
if not exist "%SOURCE%\" (
  echo %C_RED%[ERROR]%C_RESET% SOURCE not found: "%SOURCE%"
  pause
  exit /b 1
)

if not exist "%DEST%\" (
  echo %C_BLUE%[MKDIR]%C_RESET% Creating DEST: "%DEST%"
  mkdir "%DEST%" || (
    echo %C_RED%[ERROR]%C_RESET% Failed to create DEST
    pause
    exit /b 1
  )
)

where certutil >nul 2>nul || (
  echo %C_RED%[ERROR]%C_RESET% certutil not found
  pause
  exit /b 1
)

REM ===== MAIN LOOP =====
for /r "%SOURCE%" %%F in (*) do (
  call :ProcessOne "%%F"
)

echo.
echo %C_GREEN%Done.%C_RESET% Log: "%LOG%"
pause
exit /b 0


REM ==========================================================
REM =============== FILE PROCESSING SUBROUTINE ===============
REM ==========================================================
:ProcessOne
setlocal EnableDelayedExpansion

set "SRC=%~1"
set "REL=%SRC%"
set "REL=!REL:%SOURCE%\=!"
set "DST=%DEST%\!REL!"

call :Print PROCESS "!REL!"

REM --- Ensure destination directory exists ---
for %%D in ("!DST!") do set "DSTDIR=%%~dpD"
if not exist "!DSTDIR!" (
  mkdir "!DSTDIR!" 2>>"%LOG%"
  if errorlevel 1 (
    call :Print ERROR "mkdir failed: !DSTDIR!"
    endlocal & exit /b
  ) else (
    call :Print MKDIR "!DSTDIR!"
  )
)

REM --- If destination missing, copy ---
if not exist "!DST!" (
  call :Print COPY "dest missing -> copying"
  copy /Y "!SRC!" "!DST!" >nul 2>>"%LOG%"
  if errorlevel 1 (
    call :Print ERROR "copy failed"
  ) else (
    call :Print OK "copied"
  )
  endlocal & exit /b
)

REM --- Hash source ---
call :Print HASH "hashing source..."
call :GetHash "%HASHALG%" "!SRC!" SRCH
if not defined SRCH (
  call :Print ERROR "hash failed (source)"
  endlocal & exit /b
)

REM --- Hash destination ---
call :Print HASH "hashing dest..."
call :GetHash "%HASHALG%" "!DST!" DSTH
if not defined DSTH (
  call :Print ERROR "hash failed (dest)"
  endlocal & exit /b
)

REM --- Sanitize hashes (strip whitespace/CR) ---
for /f "delims=" %%A in ("!SRCH!") do set "SRCH=%%A"
for /f "delims=" %%A in ("!DSTH!") do set "DSTH=%%A"
set "SRCH=!SRCH: =!"
set "DSTH=!DSTH: =!"

call :Print HASH "SRC !SRCH!"
call :Print HASH "DST !DSTH!"

REM --- Compare ---
if /I "!SRCH!"=="!DSTH!" (
  call :Print PASS "same hash -> SKIP"
) else (
  call :Print FAIL "hash mismatch -> OVERWRITE"
  copy /Y "!SRC!" "!DST!" >nul 2>>"%LOG%"
  if errorlevel 1 (
    call :Print ERROR "overwrite copy failed"
  ) else (
    call :Print OK "overwritten"
  )
)

endlocal & exit /b


REM ==========================================================
REM ====================== PRINT =============================
REM ==========================================================
:Print
setlocal EnableDelayedExpansion
set "TAG=%~1"
set "MSG=%~2"
set "CLR=%C_RESET%"

if /I "!TAG!"=="PROCESS"  set "CLR=%C_CYAN%"
if /I "!TAG!"=="MKDIR"    set "CLR=%C_BLUE%"
if /I "!TAG!"=="COPY"     set "CLR=%C_BLUE%"
if /I "!TAG!"=="HASH"     set "CLR=%C_YELLOW%"
if /I "!TAG!"=="PASS"     set "CLR=%C_GREEN%"
if /I "!TAG!"=="OK"       set "CLR=%C_GREEN%"
if /I "!TAG!"=="FAIL"     set "CLR=%C_MAGENTA%"
if /I "!TAG!"=="ERROR"    set "CLR=%C_RED%"

echo(!CLR![!TAG!]%C_RESET% !MSG!
>>"%LOG%" echo [!TAG!] !MSG!
endlocal & exit /b


REM ==========================================================
REM ===================== GET HASH ===========================
REM ==========================================================
:GetHash
set "%~3="
set "LINE="

for /f "usebackq delims=" %%L in (`
  certutil -hashfile "%~2" %~1 ^| findstr /R /I "^[0-9A-F]"
`) do (
  set "LINE=%%L"
  goto :GotHash
)

:GotHash
if not defined LINE exit /b
set "LINE=%LINE: =%"
set "%~3=%LINE%"
exit /b
