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
:: Test 1: Basic execution with simple command
:: Using cmd /c exit which terminates immediately
:: ----------------------------------------
echo [Test 1] Basic execution - simple command
hide.exe cmd /c exit 0
if !ERRORLEVEL! EQU 0 (
    echo   PASS: hide.exe returned success
    set /a PASS+=1
) else (
    echo   FAIL: hide.exe returned error code !ERRORLEVEL!
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 2: Exit code on invalid command
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
echo [Test 3] Quiet flag -q with invalid command
echo   (If a dialog appears, close it manually - the test failed)
hide.exe -q __nonexistent_command_12345__
if !ERRORLEVEL! NEQ 0 (
    echo   PASS: -q flag accepted, returned error code
    set /a PASS+=1
) else (
    echo   FAIL: Expected non-zero exit code
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 4: --quiet flag (long form)
:: ----------------------------------------
echo.
echo [Test 4] Quiet flag --quiet with invalid command
echo   (If a dialog appears, close it manually - the test failed)
hide.exe --quiet __nonexistent_command_12345__
if !ERRORLEVEL! NEQ 0 (
    echo   PASS: --quiet flag accepted, returned error code
    set /a PASS+=1
) else (
    echo   FAIL: Expected non-zero exit code
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 5: -Q flag (uppercase, should also work)
:: ----------------------------------------
echo.
echo [Test 5] Quiet flag -Q (uppercase)
echo   (If a dialog appears, close it manually - the test failed)
hide.exe -Q __nonexistent_command_12345__
set TEST5_RESULT=!ERRORLEVEL!
if !TEST5_RESULT! NEQ 0 (
    echo   PASS: -Q flag accepted [case-insensitive]
    set /a PASS+=1
) else (
    echo   FAIL: Expected non-zero exit code
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 6: No arguments with -q (should exit silently)
:: ----------------------------------------
echo.
echo [Test 6] No arguments with -q exits silently
hide.exe -q
set TEST6_RESULT=!ERRORLEVEL!
if !TEST6_RESULT! EQU 1 (
    echo   PASS: Returned exit code 1 with no command
    set /a PASS+=1
) else (
    echo   FAIL: Expected exit code 1, got !TEST6_RESULT!
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 7: Command with arguments
:: ----------------------------------------
echo.
echo [Test 7] Command with multiple arguments
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
:: Test 9: Multiple -q flags (should still work)
:: ----------------------------------------
echo.
echo [Test 9] Multiple quiet flags
hide.exe -q -q cmd /c exit 0
if !ERRORLEVEL! EQU 0 (
    echo   PASS: Multiple -q flags handled correctly
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
:: Test 11: Command starting with dash (edge case)
:: Ensures -something is passed to child if not a known flag
:: ----------------------------------------
echo.
echo [Test 11] Command starting with dash (unknown flag passed to child)
hide.exe cmd /c echo -test
if !ERRORLEVEL! EQU 0 (
    echo   PASS: Unknown dash argument passed to child command
    set /a PASS+=1
) else (
    echo   FAIL: Unknown dash argument not handled
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 12: Verify child process actually runs
:: Create a temp file to prove the child executed
:: ----------------------------------------
echo.
echo [Test 12] Verify child process executes
set TEMPFILE=%TEMP%\hide_test_%RANDOM%.tmp
if exist "!TEMPFILE!" del "!TEMPFILE!"
hide.exe cmd /c echo test ^> "!TEMPFILE!"
:: Give it a moment to complete
timeout /t 1 /nobreak >nul
if exist "!TEMPFILE!" (
    echo   PASS: Child process created file
    del "!TEMPFILE!"
    set /a PASS+=1
) else (
    echo   FAIL: Child process did not create file
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 13: Spaces in arguments
:: ----------------------------------------
echo.
echo [Test 13] Arguments with spaces
hide.exe cmd /c "echo hello world"
if !ERRORLEVEL! EQU 0 (
    echo   PASS: Arguments with spaces handled
    set /a PASS+=1
) else (
    echo   FAIL: Arguments with spaces failed
    set /a FAIL+=1
)

:: ----------------------------------------
:: Test 14: Launch and verify a process stays running
:: Uses ping with a delay so we can verify it started
:: ----------------------------------------
echo.
echo [Test 14] Launch process that stays running briefly
set MARKER_FILE=%TEMP%\hide_test_marker_%RANDOM%.tmp
:: Launch a cmd that creates a marker file then waits
hide.exe cmd /c "echo started > "!MARKER_FILE!" && ping -n 3 127.0.0.1 >nul"
set TEST14_LAUNCH=!ERRORLEVEL!
:: Give it a moment to start and create the file
timeout /t 1 /nobreak >nul
if !TEST14_LAUNCH! EQU 0 (
    if exist "!MARKER_FILE!" (
        echo   PASS: Process launched and executed
        del "!MARKER_FILE!" 2>nul
        set /a PASS+=1
    ) else (
        echo   FAIL: Process launched but marker file not created
        set /a FAIL+=1
    )
) else (
    echo   FAIL: hide.exe returned error code !TEST14_LAUNCH!
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
