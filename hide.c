#define WIN32_LEAN_AND_MEAN
#include <windows.h>

// Minimal Windows program for running commands with a hidden console.
// Optimized to not require the C runtime library.

#define TITLE "HideConsole"
#define VERSION "1.1.0"
#define USAGE                                                                  \
  "Usage: hide.exe [options] <command> [args...]\r\n\r\n"                      \
  "Options:\r\n"                                                               \
  "  -h, --help     Show this help\r\n"                                        \
  "  -v, --version  Show version\r\n"                                          \
  "  -q, --quiet    Suppress errors\r\n"                                       \
  "  -w, --wait     Wait and return exit code\r\n\r\n"                         \
  "Example: hide.exe calc\r\n"

static BOOL g_quiet, g_wait, g_console;

#pragma function(memset)
void *__cdecl memset(void *d, int c, size_t n) {
  char *p = (char *)d;
  while (n--)
    *p++ = (char)c;
  return d;
}

#define IS_END(c) ((c) == ' ' || (c) == '\t' || !(c))

static void Write(DWORD std, LPCSTR s) {
  if (!g_console) {
    AttachConsole(ATTACH_PARENT_PROCESS);
    g_console = TRUE;
  }
  HANDLE h = GetStdHandle(std);
  if (h && h != INVALID_HANDLE_VALUE) {
    DWORD len = 0;
    while (s[len])
      len++;
    WriteFile(h, s, len, &len, NULL);
  }
}

static LPCSTR Match(LPCSTR p, LPCSTR arg) {
  while (*arg && *p == *arg) {
    p++;
    arg++;
  }
  return (!*arg && IS_END(*p)) ? p : NULL;
}

static void ShowError(LPCSTR cmd) {
  if (g_quiet)
    return;
  char msg[256], err[96], *p = msg, *end = msg + sizeof(msg) - 1;
  DWORD n =
      FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                     NULL, GetLastError(), 0, err, sizeof(err), NULL);
  if (!n) {
    err[0] = '?';
    err[1] = '\0';
  }
  for (LPCSTR s = "hide: error: "; *s && p < end;)
    *p++ = *s++;
  for (LPCSTR s = cmd; *s && p < end;)
    *p++ = *s++;
  for (LPCSTR s = "\r\n"; *s && p < end;)
    *p++ = *s++;
  for (LPCSTR s = err; *s && p < end;)
    *p++ = *s++;
  *p = '\0';
  Write(STD_ERROR_HANDLE, msg);
}

static LPSTR ParseCmd(LPSTR p) {
  // Skip exe name
  if (*p == '"') {
    while (*++p && *p != '"')
      ;
    if (*p)
      p++;
  } else {
    while (*p && !IS_END(*p))
      p++;
  }
  while (*p == ' ' || *p == '\t')
    p++;

  // Parse flags
  while (p[0] == '-') {
    LPCSTR next;
    char c = p[1] | 0x20; // lowercase
    if (p[1] == '-') {
      // Long flags
      if ((next = Match(p, "--quiet"))) {
        g_quiet = TRUE;
        p = (LPSTR)next;
      } else if ((next = Match(p, "--wait"))) {
        g_wait = TRUE;
        p = (LPSTR)next;
      } else if ((next = Match(p, "--help"))) {
        Write(STD_OUTPUT_HANDLE, USAGE);
        ExitProcess(0);
      } else if ((next = Match(p, "--version"))) {
        Write(STD_OUTPUT_HANDLE, TITLE " " VERSION "\r\n");
        ExitProcess(0);
      } else
        break;
    } else if (IS_END(p[2])) {
      // Short flags
      if (c == 'q') {
        g_quiet = TRUE;
        p += 2;
      } else if (c == 'w') {
        g_wait = TRUE;
        p += 2;
      } else if (c == 'h' || p[1] == '?') {
        Write(STD_OUTPUT_HANDLE, USAGE);
        ExitProcess(0);
      } else if (c == 'v') {
        Write(STD_OUTPUT_HANDLE, TITLE " " VERSION "\r\n");
        ExitProcess(0);
      } else
        break;
    } else
      break;
    while (*p == ' ' || *p == '\t')
      p++;
  }
  return p;
}

void __stdcall WinMainCRTStartup(void) {
  LPSTR cmd = ParseCmd(GetCommandLineA());

  if (!*cmd) {
    if (!g_quiet)
      Write(STD_OUTPUT_HANDLE, USAGE);
    ExitProcess(1);
  }

  STARTUPINFOA si = {0};
  PROCESS_INFORMATION pi = {0};
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_HIDE;

  if (!CreateProcessA(NULL, cmd, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL,
                      NULL, &si, &pi)) {
    ShowError(cmd);
    ExitProcess(1);
  }

  DWORD exitCode = 0;
  if (g_wait) {
    WaitForSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, &exitCode);
  }

  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
  ExitProcess(exitCode);
}
