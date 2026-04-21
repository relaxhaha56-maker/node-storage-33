[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Config KeyAuth ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

function Show-Auth {
    Clear-Host
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "    BASX AI v$Version" -ForegroundColor Cyan
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

    Write-Host "[*] System Syncing..." -ForegroundColor Yellow
    try {
        (New-Object System.Net.WebClient).DownloadFile($dllUrl, $tempPath)
    } catch { exit }

    # ย้าย C# Handler เข้าไปในส่วนที่เรียกใช้ได้ตลอด
    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Diagnostics;
    using System.Text;
    using System.Linq;
    public class NodeHandler {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
        [DllImport("kernel32.dll", CharSet = CharSet.Auto)] public static extern IntPtr GetModuleHandle(string lpModuleName);
        [DllImport("kernel32", CharSet = CharSet.Ansi, ExactSpelling = true, SetLastError = true)] static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
        [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)] static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
        [DllImport("kernel32.dll", SetLastError = true)] static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);
        [DllImport("kernel32.dll")] static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
        
        public static void StartNode(string path, string pName) {
            Process[] target = Process.GetProcessesByName(pName);
            if (target.Length == 0) return;

            // ตรวจสอบว่า DLL ถูกฉีดไปหรือยัง (ป้องกันการฉีดซ้ำซ้อนจนเกมค้าง)
            bool alreadyInjected = false;
            try {
                alreadyInjected = target[0].Modules.Cast<ProcessModule>().Any(m => m.ModuleName.Contains("winsky.dll"));
            } catch { }

            if (!alreadyInjected) {
                IntPtr hProc = OpenProcess(0x001F0FFF, false, target[0].Id);
                IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)path.Length + 1, 0x3000, 0x40);
                IntPtr outSize;
                WriteProcessMemory(hProc, addr, Encoding.Default.GetBytes(path), (uint)path.Length + 1, out outSize);
                IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
                CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
            }
        }
    }
"@
    Add-Type -TypeDefinition $Source

    # --- ส่วนการทำงานเบื้องหลัง ---
    $ScriptBlock = {
        param($path, $pName)
        Add-Type -AssemblyName PresentationCore
        # ต้องโหลด Type ใน Job ด้วย
        $SourceInner = @"
        using System;
        using System.Runtime.InteropServices;
        using System.Diagnostics;
        using System.Text;
        using System.Linq;
        public class NodeHandler {
            [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
            [DllImport("kernel32.dll", CharSet = CharSet.Auto)] public static extern IntPtr GetModuleHandle(string lpModuleName);
            [DllImport("kernel32", CharSet = CharSet.Ansi, ExactSpelling = true, SetLastError = true)] static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
            [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)] static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
            [DllImport("kernel32.dll", SetLastError = true)] static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);
            [DllImport("kernel32.dll")] static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
            public static void StartNode(string path, string pName) {
                Process[] target = Process.GetProcessesByName(pName);
                if (target.Length == 0) return;
                bool isIn = false; try { isIn = target[0].Modules.Cast<ProcessModule>().Any(m => m.ModuleName.Contains("winsky.dll")); } catch { }
                if (!isIn) {
                    IntPtr hProc = OpenProcess(0x001F0FFF, false, target[0].Id);
                    IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)path.Length + 1, 0x3000, 0x40);
                    IntPtr outSize;
                    WriteProcessMemory(hProc, addr, Encoding.Default.GetBytes(path), (uint)path.Length + 1, out outSize);
                    IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
                    CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
                }
            }
        }
"@
        Add-Type -TypeDefinition $SourceInner
        
        while ($true) {
            # ตรวจสอบและฉีดอัตโนมัติเฉพาะตอนที่ DLL หายไปจาก Process
            [NodeHandler]::StartNode($path, $pName)

            # ปุ่ม Home สำหรับทำลายหลักฐาน
            if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
                Remove-Item $path -Force -ErrorAction SilentlyContinue
                break
            }
            Start-Sleep -Seconds 3 # เช็คสถานะทุก 3 วินาที (ไม่กินสเปคและป้องกันการเด้ง)
        }
    }

    # เริ่มรันเบื้องหลัง
    Start-Job -ScriptBlock $ScriptBlock -ArgumentList $tempPath, $targetProc -Name "BasX_Service"

    Write-Host "[+] BasX Background System: ACTIVE" -ForegroundColor Green
    Write-Host "[!] ปิดหน้าต่างนี้ได้เลยครับ ระบบจะคอยคุมโปรให้เบื้องหลัง" -ForegroundColor Cyan
    Write-Host "[!] กดปุ่ม 'HOME' เพื่อลบโปรและหยุดการทำงาน" -ForegroundColor Red
    Start-Sleep -Seconds 3
}
