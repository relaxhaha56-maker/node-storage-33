[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- ตั้งค่า KeyAuth ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

# --- เส้นทางลับสำหรับซ่อนไฟล์ (พลางตาว่าเป็นไฟล์ระบบ) ---
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

    if ($null -eq $savedKey) { 
        $key = Read-Host " Enter License Key" 
    } else { 
        $key = $savedKey 
    }

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

    # สร้างสคริปต์ทำงานเบื้องหลัง (ซ่อนร่องรอยไฟล์)
    $serviceContent = @"
    while (`$true) {
        `$proc = Get-Process "$targetProc" -ErrorAction SilentlyContinue
        if (`$proc) {
            `$code = @"
            using System;
            using System.Runtime.InteropServices;
            using System.Diagnostics;
            using System.Text;
            using System.IO;
            public class NodeGuard {
                [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int dwAccess, bool bInherit, int pid);
                [DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string lpModuleName);
                [DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
                [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr hProc, IntPtr addr, uint size, uint allocType, uint protect);
                [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr hProc, IntPtr addr, byte[] buf, uint size, out IntPtr written);
                [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr hProc, IntPtr attr, uint stack, IntPtr start, IntPtr param, uint flags, IntPtr id);
                
                public static void Execute(string path, int pid) {
                    // ฉีด DLL เข้าไปใน Memory
                    IntPtr hProc = OpenProcess(0x001F0FFF, false, pid);
                    if (hProc == IntPtr.Zero) return;
                    IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)path.Length + 1, 0x3000, 0x40);
                    IntPtr w;
                    WriteProcessMemory(hProc, addr, Encoding.Default.GetBytes(path), (uint)path.Length + 1, out w);
                    IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
                    CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
                    
                    // ทำลายหลักฐาน: ลบไฟล์ DLL ทิ้งทันทีที่ฉีดเข้า Memory แล้ว
                    System.Threading.Thread.Sleep(2000);
                    if (File.Exists(path)) { File.Delete(path); }
                }
            }
"@
            Add-Type -TypeDefinition `$code -ErrorAction SilentlyContinue
            [NodeGuard]::Execute("$dllPath", `$proc.Id)
        }
        
        # ตรวจจับปุ่ม Home เพื่อถอนการติดตั้งและปิดเกม
        Add-Type -AssemblyName PresentationCore
        if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
            Stop-Process -Name "$targetProc" -Force -ErrorAction SilentlyContinue
            Remove-Item "$configPath" -Force -ErrorAction SilentlyContinue
            Remove-Item "$scriptPath" -Force -ErrorAction SilentlyContinue
            Remove-Item "$vbsPath" -Force -ErrorAction SilentlyContinue
            break
        }
        Start-Sleep -Seconds 10
    }
"@
    # สร้างโฟลเดอร์ซ่อนถ้ายังไม่มี
    New-Item -ItemType Directory -Path (Split-Path $scriptPath) -Force | Out-Null
    $serviceContent | Out-File $scriptPath -Force

    # สร้างตัวเปิดสคริปต์แบบไร้หน้าต่าง (VBS)
    $vbsContent = "CreateObject(`"Wscript.Shell`").Run `"powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"`", 0, True"
    $vbsContent | Out-File $vbsPath -Force

    # ตั้งค่าให้รันอัตโนมัติ (เปลี่ยนชื่อให้เหมือนไฟล์ระบบ Windows)
    $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $runKey -Name "WindowsSecurityHost" -Value "wscript.exe `"$vbsPath`""

    # สั่งให้ทำงานทันทีในโหมดซ่อน
    Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsPath`""
    
    Write-Host "[+] ติดตั้งระบบ BasX Stealth เรียบร้อย" -ForegroundColor Green
    Write-Host "[*] ระบบจะทำงานเงียบๆ เบื้องหลัง (ไม่ทิ้งร่องรอยไฟล์)" -ForegroundColor Cyan
    Write-Host "[!] กดปุ่ม 'HOME' เพื่อปิดเกมและล้างข้อมูลทั้งหมด" -ForegroundColor Red
    Start-Sleep -Seconds 2
} else {
    Write-Host "[-] คีย์ไม่ถูกต้องหรือหมดอายุ" -ForegroundColor Red
}
