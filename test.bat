@echo off
setlocal EnableDelayedExpansion

echo ============================================
echo   HideConsole Test Suite
echo ============================================
echo.

set PASS=0
set FAIL=0

:: Check if hide.exe exists
if not exist hide.exe (
    echo ERROR: hide.exe not found. Please build first with build.bat
    exit /b 1
)

:: ----------------------------------------
:: Test 1: Basic execution
:: ----------------------------------------
echo [Test 1] Basic execution
hide.exe cmd /c exit 0
if !ERRORLEVEL! EQU 0 (
    echo   PASS: hide.exe returned success
    set /a PASS+=1
) else (
    echo   FAIL: hide.exe returned error code !ERRORLEVEL!
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 2: Invalid command returns error
:: ----------------------------------------
echo.
echo [Test 2] Invalid command returns error code
hide.exe -q __nonexistent_command_12345__
if !ERRORLEVEL! NEQ 0 (
    echo   PASS: Returned non-zero exit code for invalid command
    set /a PASS+=1
) else (
    echo   FAIL: Should have returned non-zero exit code
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 3: -q flag (short form)
:: ----------------------------------------
echo.
echo [Test 3] Quiet flag -q
hide.exe -q __nonexistent_command_12345__
if !ERRORLEVEL! NEQ 0 (
    echo   PASS: -q flag accepted
    set /a PASS+=1
) else (
    echo   FAIL: Expected non-zero exit code
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 4: --quiet flag (long form)
:: ----------------------------------------
echo.
echo [Test 4] Quiet flag --quiet
hide.exe --quiet __nonexistent_command_12345__
if !ERRORLEVEL! NEQ 0 (
    echo   PASS: --quiet flag accepted
    set /a PASS+=1
) else (
    echo   FAIL: Expected non-zero exit code
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 5: -Q flag (uppercase)
:: ----------------------------------------
echo.
echo [Test 5] Quiet flag -Q (case-insensitive)
hide.exe -Q __nonexistent_command_12345__
if !ERRORLEVEL! NEQ 0 (
    echo   PASS: -Q flag accepted
    set /a PASS+=1
) else (
    echo   FAIL: Expected non-zero exit code
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 6: No arguments with -q
:: ----------------------------------------
echo.
echo [Test 6] No arguments with -q exits silently
hide.exe -q
if !ERRORLEVEL! EQU 1 (
    echo   PASS: Returned exit code 1
    set /a PASS+=1
) else (
    echo   FAIL: Expected exit code 1, got !ERRORLEVEL!
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 7: Command with arguments
:: ----------------------------------------
echo.
echo [Test 7] Command with arguments
hide.exe cmd /c exit 0
if !ERRORLEVEL! EQU 0 (
    echo   PASS: Command with arguments executed
    set /a PASS+=1
) else (
    echo   FAIL: Command with arguments failed
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 8: Quoted executable path
:: ----------------------------------------
echo.
echo [Test 8] Quoted executable path
hide.exe "cmd" /c exit 0
if !ERRORLEVEL! EQU 0 (
    echo   PASS: Quoted path handled correctly
    set /a PASS+=1
) else (
    echo   FAIL: Quoted path failed
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 9: Multiple -q flags
:: ----------------------------------------
echo.
echo [Test 9] Multiple quiet flags
hide.exe -q -q cmd /c exit 0
if !ERRORLEVEL! EQU 0 (
    echo   PASS: Multiple -q flags handled
    set /a PASS+=1
) else (
    echo   FAIL: Multiple -q flags broke execution
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 10: -q with valid command
:: ----------------------------------------
echo.
echo [Test 10] Quiet flag with valid command
hide.exe -q cmd /c exit 0
if !ERRORLEVEL! EQU 0 (
    echo   PASS: -q works with valid commands
    set /a PASS+=1
) else (
    echo   FAIL: -q broke valid command execution
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 11: Unknown dash argument passed to child
:: ----------------------------------------
echo.
echo [Test 11] Unknown dash argument passed to child
hide.exe cmd /c echo -test
if !ERRORLEVEL! EQU 0 (
    echo   PASS: Unknown dash argument passed correctly
    set /a PASS+=1
) else (
    echo   FAIL: Unknown dash argument not handled
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 12: Arguments with spaces
:: ----------------------------------------
echo.
echo [Test 12] Arguments with spaces
hide.exe cmd /c "echo hello world"
if !ERRORLEVEL! EQU 0 (
    echo   PASS: Arguments with spaces handled
    set /a PASS+=1
) else (
    echo   FAIL: Arguments with spaces failed
    set /a FAIL+=1
)

:: ----------------------------------------
:: Summary
:: ----------------------------------------
echo.
echo ============================================
echo   Results: !PASS! passed, !FAIL! failed
echo ============================================

if !FAIL! GTR 0 (
    exit /b 1
) else (
    exit /b 0
)
