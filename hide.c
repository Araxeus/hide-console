#define WIN32_LEAN_AND_MEAN
#include <windows.h>

// Minimal Windows program for running commands with a hidden console.
// Optimized to not require the C runtime library.

#define TITLE "HideConsole"
#define VERSION "1.0.0"
#define USAGE                                                                  \
  "Usage: hide.exe [-q] [-v] <command> [args...]\n\n"                          \
  "-q\tSuppress error dialogs\n"                                               \
  "-v\tShow version\n\n"                                                       \
  "Example: hide.exe calc"

static BOOL g_quiet = FALSE;

// Skip whitespace, return pointer to next non-whitespace
static LPSTR SkipWs(LPSTR p) {
  while (*p == ' ' || *p == '\t') p++;
  return p;
}

// Check if char is whitespace or end of string
#define IS_END(c) ((c) == ' ' || (c) == '\t' || !(c))

// Returns pointer past match if arg matches at p (followed by space/tab/end), else NULL
static LPCSTR MatchArg(LPCSTR p, LPCSTR arg) {
  while (*arg && *p == *arg) { p++; arg++; }
  return (!*arg && IS_END(*p)) ? p : NULL;
}

// Append string to buffer with bounds check, return new position
static char *Append(char *p, char *end, LPCSTR s) {
  while (*s && p < end) *p++ = *s++;
  return p;
}

// Close array of handles (skips NULL)
static void CloseHandles(HANDLE *h, int n) {
  for (int i = 0; i < n; i++)
    if (h[i]) CloseHandle(h[i]);
}

#pragma function(memset)
void *__cdecl memset(void *dest, int c, size_t count) {
  char *p = (char *)dest;
  while (count--) *p++ = (char)c;
  return dest;
}

// --- Core functions ---

static void ShowError(LPCSTR cmd) {
  if (g_quiet) return;

  char msg[256], err[128];
  DWORD n = FormatMessageA(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
      NULL, GetLastError(), 0, err, sizeof(err), NULL);
  if (!n) { err[0] = '?'; err[1] = '\0'; }

  // Build: "Failed: <cmd>\n\n<error>"
  char *p = msg, *end = msg + sizeof(msg) - 1;
  p = Append(p, end, "Failed: ");
  p = Append(p, end, cmd);
  p = Append(p, end, "\n\n");
  p = Append(p, end, err);
  *p = '\0';

  MessageBoxA(NULL, msg, TITLE, MB_OK | MB_ICONERROR);
}

static void SetupPipes(STARTUPINFOA *si, HANDLE *h) {
  // h[0]=toChild, h[1]=fromChild, h[2]=toParent, h[3]=fromParent
  SECURITY_ATTRIBUTES sa = {sizeof(sa), NULL, TRUE};
  HANDLE in[2], out[2];

  ZeroMemory(si, sizeof(*si));
  si->cb = sizeof(*si);
  si->dwFlags = STARTF_USESHOWWINDOW | STARTF_USESTDHANDLES;
  si->wShowWindow = SW_HIDE;
  si->hStdInput = GetStdHandle(STD_INPUT_HANDLE);
  si->hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
  si->hStdError = GetStdHandle(STD_ERROR_HANDLE);
  h[0] = h[1] = h[2] = h[3] = NULL;

  if (CreatePipe(&in[0], &in[1], &sa, 0)) {
    SetHandleInformation(in[1], HANDLE_FLAG_INHERIT, 0);
    si->hStdInput = in[0];
    h[0] = in[1];
    h[3] = in[0];

    if (CreatePipe(&out[0], &out[1], &sa, 0)) {
      SetHandleInformation(out[0], HANDLE_FLAG_INHERIT, 0);
      si->hStdOutput = si->hStdError = out[1];
      h[1] = out[0];
      h[2] = out[1];
    } else {
      CloseHandle(in[0]);
      CloseHandle(in[1]);
      si->hStdInput = GetStdHandle(STD_INPUT_HANDLE);
      h[0] = h[3] = NULL;
    }
  }
}

static LPSTR ParseCmd(LPSTR p) {
  // Skip exe name (may be quoted)
  if (*p == '"') {
    while (*++p && *p != '"');
    if (*p) p++;
  } else {
    while (*p && !IS_END(*p)) p++;
  }
  p = SkipWs(p);

  // Check for -q/--quiet or -v/--version
  while (*p == '-') {
    LPCSTR next;
    if ((next = MatchArg(p, "-q")) || (next = MatchArg(p, "-Q")) ||
        (next = MatchArg(p, "--quiet"))) {
      g_quiet = TRUE;
      p = (LPSTR)next;
    } else if ((next = MatchArg(p, "-v")) || (next = MatchArg(p, "-V")) ||
               (next = MatchArg(p, "--version"))) {
      MessageBoxA(NULL, TITLE " " VERSION, TITLE, MB_OK);
      ExitProcess(0);
    } else {
      break;
    }
    p = SkipWs(p);
  }
  return p;
}

void __stdcall WinMainCRTStartup(void) {
  LPSTR cmd = ParseCmd(GetCommandLineA());

  if (!*cmd) {
    if (!g_quiet)
      MessageBoxA(NULL, USAGE, TITLE, MB_OK | MB_ICONINFORMATION);
    ExitProcess(1);
  }

  STARTUPINFOA si;
  PROCESS_INFORMATION pi;
  HANDLE h[4];

  SetupPipes(&si, h);
  ZeroMemory(&pi, sizeof(pi));

  if (!CreateProcessA(NULL, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) {
    ShowError(cmd);
    CloseHandles(h, 4);
    ExitProcess(1);
  }

  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
  CloseHandles(h, 4);
  ExitProcess(0);
}
