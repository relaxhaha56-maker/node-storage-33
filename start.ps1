[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Configuration ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

$dirPath    = "$env:LOCALAPPDATA\WindowsHealth"
$configPath = "$dirPath\auth.dat"
$scriptPath = "$dirPath\service.ps1"
$targetDll  = "$env:TEMP\AimbotFemaleFix.dll"
$targetProc = "HD-Player"

# --- KeyAuth System (Remember Me) ---
function Show-Auth {
    param($savedKey = $null)
    $initUrl = "https://keyauth.win/api/1.2/?type=init&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID&secret=$Secret&version=$Version"
    try {
        $initRes = Invoke-RestMethod -Uri $initUrl -Method Get
        if ($initRes.success -ne $true) { return $null }
        $sessionId = $initRes.sessionid
    } catch { return $null }

    if ($null -ne $savedKey) { $key = $savedKey } else { $key = Read-Host " Enter License Key" }

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
    Write-Host "[+] Login Success" -ForegroundColor Green

    # C# Code: Memory Watcher + Injector Logic
    $code = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    public class BasXGuard {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint d, bool b, int p);
        [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
        [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint pr);
        [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string n);
        [DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr h, string p);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);

        public static bool IsLocked(IntPtr hProc, long addr) {
            byte[] buffer = new byte[4];
            int read;
            if (ReadProcessMemory(hProc, (IntPtr)addr, buffer, 4, out read)) {
                return buffer[0] == 0xFF && buffer[1] == 0xFF; 
            }
            return false;
        }

        public static void Inject(string dllPath, int pid) {
            IntPtr h = OpenProcess(0x001F0FFF, false, pid);
            if (h == IntPtr.Zero) return;
            IntPtr a = VirtualAllocEx(h, IntPtr.Zero, (uint)dllPath.Length + 1, 0x3000, 0x40);
            IntPtr w;
            WriteProcessMemory(h, a, Encoding.Default.GetBytes(dllPath), (uint)dllPath.Length + 1, out w);
            IntPtr l = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
            CreateRemoteThread(h, IntPtr.Zero, 0, l, a, 0, IntPtr.Zero);
        }
    }
"@
    Add-Type -TypeDefinition $code

    # --- ส่วนการทำงานเบื้องหลัง (Background Service) ---
    $serviceBody = @"
    while (`$true) {
        `$p = Get-Process "$targetProc" -ErrorAction SilentlyContinue
        if (`$p) {
            `$hProc = [BasXGuard]::OpenProcess(0x001F0FFF, `$false, `$p.Id)
            
            # ตรวจสอบค่าที่ตำแหน่ง 0x2EC (READ)
            # ถ้าค่าไม่ใช่ค่าล็อคหัว ให้ฉีดใหม่ทันที
            if (![BasXGuard]::IsLocked(`$hProc, 0x2EC)) {
                if (Test-Path "$targetDll") {
                    [BasXGuard]::Inject("$targetDll", `$p.Id)
                }
            }
        }
        Start-Sleep -Seconds 5 
    }
"@
    $serviceBody | Out-File $scriptPath -Force

    # รันสคริปต์เบื้องหลัง
    Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    
    Write-Host "[+] BasX Smart Protection Active" -ForegroundColor Green
    Write-Host "[*] DLL: AimbotFemaleFix.dll" -ForegroundColor Cyan
    Write-Host "[*] Monitoring Memory 0x2EC / 0x2E8..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
}
