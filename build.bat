@echo off
setlocal

echo === Minimal Build Script ===
echo.

:: Check if cl.exe is available
where cl.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: cl.exe not found. Please run this from a Visual Studio Developer Command Prompt.
    echo.
    echo You can open one from:
    echo   Start Menu ^> Visual Studio ^> Developer Command Prompt
    echo.
    exit /b 1
)

:: Clean previous build
if exist hide.obj del hide.obj
if exist hide.exe del hide.exe
if exist resource.res del resource.res

echo [1/3] Compiling resources...
rc.exe /nologo resource.rc
if errorlevel 1 (
    echo ERROR: Resource compilation failed.
    exit /b 1
)

echo [2/3] Compiling source...
cl.exe /nologo /O1 /GS- /c /Fo:hide.obj hide.c
if errorlevel 1 (
    echo ERROR: Source compilation failed.
    exit /b 1
)

echo [3/3] Linking...
link.exe /nologo /NODEFAULTLIB /ENTRY:WinMainCRTStartup /SUBSYSTEM:WINDOWS /OPT:REF /OPT:ICF /MERGE:.rdata=.text hide.obj resource.res kernel32.lib user32.lib
if errorlevel 1 (
    echo ERROR: Linking failed.
    exit /b 1
)

:: Show result
echo.
echo === Build Complete ===
for %%A in (hide.exe) do echo Output: hide.exe (%%~zA bytes)
echo.

:: Cleanup intermediate files
if exist hide.obj del hide.obj
if exist resource.res del resource.res

endlocal
