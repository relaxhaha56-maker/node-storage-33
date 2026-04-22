[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Configuration ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

$dirPath    = "$env:LOCALAPPDATA\WindowsHealth"
$configPath = "$dirPath\auth.dat"
$scriptPath = "$dirPath\service.ps1"
$targetDll  = "$env:TEMP\f8.dll"  # เปลี่ยนชื่อเป็น f8.dll ตามสั่ง
$targetProc = "HD-Player"

function Show-Auth {
    param($savedKey = $null)
    $initUrl = "https://keyauth.win/api/1.2/?type=init&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID&secret=$Secret&version=$Version"
    try {
        $initRes = Invoke-RestMethod -Uri $initUrl -Method Get
        if ($initRes.success -ne $true) { return $null }
        $sessionId = $initRes.sessionid
    } catch { return $null }

    # ถ้ามีคีย์เก่า (auth.dat) ให้ลองล็อกอินอัตโนมัติ
    if ($null -ne $savedKey) { 
        $key = $savedKey 
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

# เช็คว่าเครื่องนี้เคยใส่คีย์หรือยัง
$currentKey = $null
if (Test-Path $configPath) { $currentKey = Get-Content $configPath }

if (Show-Auth -savedKey $currentKey) {
    Write-Host "[+] Login Success" -ForegroundColor Green

    # C# Code สำหรับฉีด DLL (มาตรฐานสูงสุด)
    $code = @"
    using System; using System.Runtime.InteropServices; using System.Text;
    public class NodeGuard {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int d, bool b, int p);
        [DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string n);
        [DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr h, string p);
        [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint pr);
        [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);
        public static void Run(string p, int i) {
            IntPtr h = OpenProcess(0x1F0FFF, false, i);
            if (h == IntPtr.Zero) return;
            IntPtr a = VirtualAllocEx(h, IntPtr.Zero, (uint)p.Length + 1, 0x3000, 0x40);
            IntPtr w;
            WriteProcessMemory(h, a, Encoding.Default.GetBytes(p), (uint)p.Length + 1, out w);
            IntPtr l = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
            CreateRemoteThread(h, IntPtr.Zero, 0, l, a, 0, IntPtr.Zero);
        }
    }
"@
    Add-Type -TypeDefinition $code

    # --- การฉีดครั้งเดียวจบ ---
    $p = Get-Process "$targetProc" -ErrorAction SilentlyContinue
    if ($p -and (Test-Path "$targetDll")) {
        [NodeGuard]::Run("$targetDll", $p.Id)
        Write-Host "[+] Injected f8.dll into $targetProc Successfully!" -ForegroundColor Cyan
    } else {
        Write-Host "[!] Error: Make sure $targetProc is running and f8.dll is in Temp folder." -ForegroundColor Yellow
    }

    # --- สคริปต์ดักปุ่ม Home (Panic Button) ---
    $panicBody = @"
    while (`$true) {
        Add-Type -AssemblyName PresentationCore
        if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
            Stop-Process -Name "$targetProc" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsHealthMonitor" -ErrorAction SilentlyContinue
            Remove-Item "$dirPath" -Recurse -Force -ErrorAction SilentlyContinue
            exit
        }
        Start-Sleep -Milliseconds 500
    }
"@
    $panicBody | Out-File $scriptPath -Force

    # รันตัว Panic Button แบบซ่อนหน้าต่าง
    Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    
    Write-Host "[*] Service Ready. Press 'HOME' to Wipe All Traces." -ForegroundColor Gray
    Start-Sleep -Seconds 2
} else {
    Write-Host "[-] Invalid Key or Connection Error." -ForegroundColor Red
    if (Test-Path $configPath) { Remove-Item $configPath } # ลบคีย์เสียทิ้งเพื่อให้ใส่ใหม่ได้
}
