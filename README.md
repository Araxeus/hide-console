# HideConsole

[![Build](https://github.com/Araxeus/hide-console/actions/workflows/build.yml/badge.svg)](https://github.com/Araxeus/hide-console/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/Araxeus/hide-console)](https://github.com/Araxeus/hide-console/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A tiny Windows utility for running commands with a hidden console window.

Perfect for Windows shortcuts, scheduled tasks, or anywhere you want to run a console program silently in the background.

## Features

- **Tiny** - Only ~5KB, no external dependencies
- **No console flash** - Launches processes with the console completely hidden
- **Simple** - Just prefix any command with `hide.exe`
- **Quiet mode** - Optional `-q` flag to suppress error dialogs

## Download

Pre-built binaries are available on the [Releases](https://github.com/Araxeus/hide-console/releases/latest) page:

| File | Architecture | Notes |
|------|--------------|-------|
| `hide.exe` | 64-bit (x64) | **Recommended** - works with `wsl.exe` |
| `hide-x86.exe` | 32-bit (x86) | For legacy 32-bit systems |

## Usage

```
hide.exe [options] <command> [arguments...]
```

### Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help message |
| `-v`, `--version` | Show version information |
| `-q`, `--quiet` | Suppress all output |
| `-w`, `--wait` | Wait for command to finish and return its exit code |

### Examples

```
hide.exe calc
hide.exe wsl --exec xterm -display :0
hide.exe cmd /c start notepad
hide.exe powershell -File script.ps1
hide.exe -q some-command-that-might-fail
hide.exe -w cmd /c my-script.bat && echo Success
```

## Building

### Requirements

- Visual Studio with C++ tools (or just the Build Tools for Visual Studio)
- Run commands from a **Developer Command Prompt**

### Quick Build

Run `build.bat` from a Developer Command Prompt:

```
build.bat
```

### Manual Build

```
rc.exe /nologo resource.rc
cl.exe /nologo /O1 /GS- /c /Fo:hide.obj hide.c
link.exe /nologo /NODEFAULTLIB /ENTRY:WinMainCRTStartup /SUBSYSTEM:WINDOWS /OPT:REF /OPT:ICF /MERGE:.rdata=.text hide.obj resource.res kernel32.lib user32.lib
```

### Debug Build

```
rc.exe /nologo resource.rc
cl.exe /nologo /Zi /Od /c /Fo:hide.obj hide.c
link.exe /nologo /DEBUG /ENTRY:WinMainCRTStartup /SUBSYSTEM:WINDOWS hide.obj resource.res kernel32.lib user32.lib
```

### Testing

After building, run the test suite:

```
test.bat
```

This runs automated tests for basic execution, quiet mode flags, error handling, and argument parsing.

## Build Size Comparison

| Build Type | Size |
|------------|------|
| Minimal (no CRT) | ~5 KB |
| Dynamic CRT (/MD) | ~10 KB |
| Static CRT (/MT) | ~600 KB |

## Basic Test

```
hide.exe calc
```

If Calculator opens, hide.exe is working correctly.

## Security & Verification

Release binaries are built automatically by [GitHub Actions](https://github.com/Araxeus/hide-console/actions) and include [build provenance attestation](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds).

You can verify that a release binary was built from this repository:

```
gh attestation verify hide.exe --repo Araxeus/hide-console
gh attestation verify hide-x86.exe --repo Araxeus/hide-console
```

This requires the [GitHub CLI](https://cli.github.com/). You can also view attestations on the [Actions tab](https://github.com/Araxeus/hide-console/attestations).

## License

[MIT](LICENSE)
