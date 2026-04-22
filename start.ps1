[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Configuration ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

$configPath = "$env:APPDATA\Microsoft\Protect\Windows_Auth.dat"
$scriptPath = "$env:APPDATA\Microsoft\Protect\SysHost.ps1"
$vbsPath    = "$env:APPDATA\Microsoft\Protect\SysHost.vbs"
$dllPath    = "$env:TEMP\winsky.dll"
$targetProc = "HD-Player"

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
            $key | Out-File $configPath -Force
            return $true
        }
    } catch { }
    return $false
}

$currentKey = $null
if (Test-Path $configPath) { $currentKey = Get-Content $configPath }

if (Show-Auth -savedKey $currentKey) {
    Write-Host "[+] ยืนยันตัวตนสำเร็จ" -ForegroundColor Green

    # --- ส่วนที่แก้ไข: ใช้ Here-String แบบ Single Quote เพื่อกัน Error ---
    $serviceContent = @'
    $target = "HD-Player"
    $dll = "$env:TEMP\winsky.dll"
    while ($true) {
        $proc = Get-Process $target -ErrorAction SilentlyContinue
        if ($proc) {
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
                public static void Execute(string path, int pid) {
                    IntPtr h = OpenProcess(0x001F0FFF, false, pid);
                    if (h == IntPtr.Zero) return;
                    IntPtr a = VirtualAllocEx(h, IntPtr.Zero, (uint)path.Length + 1, 0x3000, 0x40);
                    IntPtr w;
                    WriteProcessMemory(h, a, Encoding.Default.GetBytes(path), (uint)path.Length + 1, out w);
                    IntPtr l = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
                    CreateRemoteThread(h, IntPtr.Zero, 0, l, a, 0, IntPtr.Zero);
                    System.Threading.Thread.Sleep(2000);
                    if (File.Exists(path)) { File.Delete(path); }
                }
            }
"@
            Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
            [NodeGuard]::Execute($dll, $proc.Id)
        }
        Add-Type -AssemblyName PresentationCore
        if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
            Stop-Process -Name $target -Force -ErrorAction SilentlyContinue
            $app = "$env:APPDATA\Microsoft\Protect"
            Remove-Item "$app\Windows_Auth.dat" -Force -ErrorAction SilentlyContinue
            Remove-Item "$app\SysHost.ps1" -Force -ErrorAction SilentlyContinue
            Remove-Item "$app\SysHost.vbs" -Force -ErrorAction SilentlyContinue
            break
        }
        Start-Sleep -Seconds 10
    }
'@
    # บันทึกไฟล์ลงเครื่อง
    if (!(Test-Path (Split-Path $scriptPath))) { New-Item -ItemType Directory -Path (Split-Path $scriptPath) -Force }
    $serviceContent | Out-File $scriptPath -Force

    # สร้าง VBS Launcher (ใช้ Single Quote เพื่อเลี่ยง Error เครื่องหมายคำพูด)
    $vbsContent = 'CreateObject("Wscript.Shell").Run "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File ""' + $scriptPath + '""", 0, True'
    $vbsContent | Out-File $vbsPath -Force

    # Registry Startup
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsSecurityHost" -Value "wscript.exe `"$vbsPath`""

    # รันทันที
    Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsPath`""
    
    Write-Host "[+] ติดตั้งระบบ BasX Stealth สำเร็จ!" -ForegroundColor Green
    Write-Host "[*] ระบบกำลังทำงานเบื้องหลัง คุณปิดหน้าต่างนี้ได้เลย" -ForegroundColor Cyan
    Write-Host "[!] กด 'HOME' เพื่อลบระบบออกทั้งหมด" -ForegroundColor Red
    Start-Sleep -Seconds 3
}
