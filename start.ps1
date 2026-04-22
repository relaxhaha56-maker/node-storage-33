[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Configuration ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

$dirPath    = "$env:LOCALAPPDATA\WindowsHealth"
$configPath = "$dirPath\auth.dat"
$scriptPath = "$dirPath\service.ps1"
$vbsPath    = "$dirPath\launcher.vbs"
$hiddenDll  = "$dirPath\win_sys.dll"
$tempDll    = "$env:TEMP\winsky.dll"
$targetProc = "HD-Player"
$regKey     = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$regName    = "WindowsHealthMonitor"

function Show-Auth {
    param($savedKey = $null)
    $initUrl = "https://keyauth.win/api/1.2/?type=init&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID&secret=$Secret&version=$Version"
    try {
        $initRes = Invoke-RestMethod -Uri $initUrl -Method Get
        if ($initRes.success -ne $true) { return $null }
        $sessionId = $initRes.sessionid
    } catch { return $null }

    if ($null -eq $savedKey) { $key = Read-Host " Enter License Key" } else { $key = $savedKey }

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

    # ย้าย DLL ไปเก็บที่ลับ
    if (Test-Path $tempDll) {
        try {
            Copy-Item $tempDll -Destination $hiddenDll -Force -ErrorAction SilentlyContinue
            Remove-Item $tempDll -Force -ErrorAction SilentlyContinue
        } catch { }
    }

    $code = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    using System.IO;
    public class NodeGuard {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int dw, bool b, int p);
        [DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string n);
        [DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr h, string p);
        [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint pr);
        [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);
        public static void Run(string path, int pid) {
            IntPtr h = OpenProcess(0x001F0FFF, false, pid);
            if (h == IntPtr.Zero) return;
            IntPtr a = VirtualAllocEx(h, IntPtr.Zero, (uint)path.Length + 1, 0x3000, 0x40);
            IntPtr w;
            WriteProcessMemory(h, a, Encoding.Default.GetBytes(path), (uint)path.Length + 1, out w);
            IntPtr l = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
            CreateRemoteThread(h, IntPtr.Zero, 0, l, a, 0, IntPtr.Zero);
        }
    }
"@

    # ระบบเบื้องหลังพร้อม Panic Button
    $serviceBody = @"
    `$target = "$targetProc"
    `$dir = "$dirPath"
    while (`$true) {
        `$proc = Get-Process `$target -ErrorAction SilentlyContinue
        if (`$proc) {
            [NodeGuard]::Run("$hiddenDll", `$proc.Id)
        }
        
        # ฟังก์ชัน Panic Button (กด Home)
        Add-Type -AssemblyName PresentationCore
        if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
            # 1. ปิดเกม
            Stop-Process -Name `$target -Force -ErrorAction SilentlyContinue
            # 2. ลบ Startup Registry
            Remove-ItemProperty -Path "$regKey" -Name "$regName" -ErrorAction SilentlyContinue
            # 3. ลบโฟลเดอร์หลักทิ้งทั้งหมด
            Remove-Item `$dir -Recurse -Force -ErrorAction SilentlyContinue
            # 4. ปิดตัวเอง
            exit
        }
        Start-Sleep -Seconds 8
    }
"@
    $finalScript = "Add-Type -TypeDefinition @'`n$code`n'@`n" + $serviceBody
    $finalScript | Out-File $scriptPath -Force

    # แก้ไข VBS ให้คลีนที่สุด (กัน Invalid Character)
    $vbsContent = "Set s = CreateObject(`"WScript.Shell`"): s.Run `"powershell.exe -WindowStyle Hidden -File `"`" & s.ExpandEnvironmentStrings(`"%LOCALAPPDATA%\WindowsHealth\service.ps1`") & `"`"`", 0, False"
    $vbsContent | Out-File $vbsPath -Force

    # เซ็ตค่า Registry และรัน
    Set-ItemProperty -Path $regKey -Name $regName -Value "wscript.exe `"$vbsPath`""
    Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsPath`""
    
    Write-Host "[+] Stealth Persistence Active" -ForegroundColor Cyan
    Write-Host "[!] HOME KEY: Close Game & Full Cleanup" -ForegroundColor Red
    Start-Sleep -Seconds 2
}
