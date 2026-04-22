[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- ข้อมูล KeyAuth ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

$dirPath    = "$env:LOCALAPPDATA\WindowsHealth"
$configPath = "$dirPath\auth.dat"
$targetDll  = "$env:TEMP\AimbotFemaleFix.dll"
$dllUrl     = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/refs/heads/main/winsky.dll"
$targetProc = "HD-Player"

function Show-Auth {
    param($savedKey = $null)
    Clear-Host
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "     BASX AIMBOT SYSTEM       " -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    
    $initUrl = "https://keyauth.win/api/1.2/?type=init&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID&secret=$Secret&version=$Version"
    try {
        $initRes = Invoke-RestMethod -Uri $initUrl -Method Get
        if ($initRes.success -ne $true) { return $null }
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

    # --- ระบบดาวน์โหลดใหม่ (เช็คไฟล์ก่อนโหลด) ---
    if (!(Test-Path $targetDll)) {
        Write-Host "[*] Downloading components..." -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $dllUrl -OutFile $targetDll -ErrorAction Stop
            Write-Host "[+] Download Complete." -ForegroundColor Green
        } catch { 
            Write-Host "[!] Download Failed! Check your internet or link." -ForegroundColor Red
            Write-Host "[*] ตรวจสอบว่าปิด Antivirus หรือยัง?" -ForegroundColor Yellow
            exit 
        }
    } else {
        Write-Host "[*] Component already exists. Skipping download." -ForegroundColor Gray
    }

    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Diagnostics;
    using System.Text;
    public class NodeHandler {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int dw, bool b, int p);
        [DllImport("kernel32.dll", CharSet = CharSet.Auto)] public static extern IntPtr GetModuleHandle(string lp);
        [DllImport("kernel32.dll", CharSet = CharSet.Ansi)] public static extern IntPtr GetProcAddress(IntPtr h, string pName);
        [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint pr);
        [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);
        
        public static void StartNode(string path, int pid) {
            IntPtr hProc = OpenProcess(0x001F0FFF, false, pid);
            if (hProc == IntPtr.Zero) return;
            IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)path.Length + 1, 0x3000, 0x40);
            IntPtr outSize;
            WriteProcessMemory(hProc, addr, Encoding.Default.GetBytes(path), (uint)path.Length + 1, out outSize);
            IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
            CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
        }

        public static bool CheckMemory(int pid, long addr) {
            IntPtr h = OpenProcess(0x001F0FFF, false, pid);
            if (h == IntPtr.Zero) return true; // ถ้าเปิดไม่ได้ให้ถือว่ายังอยู่ไปก่อน
            byte[] b = new byte[4];
            int r;
            if (ReadProcessMemory(h, (IntPtr)addr, b, 4, out r)) {
                return b[0] == 0xFF && b[1] == 0xFF;
            }
            return false;
        }
    }
"@
    Add-Type -TypeDefinition $Source

    Write-Host "[*] Monitoring $targetProc..." -ForegroundColor Cyan
    while ($true) {
        $p = Get-Process $targetProc -ErrorAction SilentlyContinue
        if ($p) {
            # ตรวจสอบค่าที่ 0x2EC ถ้าค่าหลุด ให้ฉีดใหม่
            if (![NodeHandler]::CheckMemory($p.Id, 0x2EC)) {
                if (Test-Path $targetDll) {
                    [NodeHandler]::StartNode($targetDll, $p.Id)
                    Write-Host "[+] $(Get-Date -Format 'HH:mm:ss') - Re-Injected Successfully!" -ForegroundColor Green
                }
            }
        }
        Start-Sleep -Seconds 5
    }
} else {
    Write-Host "[-] Login Failed." -ForegroundColor Red
}
