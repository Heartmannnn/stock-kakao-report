$code = @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class WinSearch {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);

    public static void FindKakao() {
        EnumWindows(new EnumWindowsProc((hWnd, lParam) => {
            StringBuilder sb = new StringBuilder(256);
            GetWindowText(hWnd, sb, 256);
            string title = sb.ToString();
            if (!string.IsNullOrEmpty(title)) {
                if (title.Contains("카카오") || title.Contains("Kakao") || title.Contains("전자오락")) {
                    Console.WriteLine(title);
                    ShowWindow(hWnd, 9);
                    SetForegroundWindow(hWnd);
                }
            }
            return true;
        }), IntPtr.Zero);
    }
}
"@

Add-Type -TypeDefinition $code
[WinSearch]::FindKakao()
