[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Config KeyAuth ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

function Show-Auth {
    Clear-Host
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "    BASX ULTRA RELINK v$Version" -ForegroundColor Cyan
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

    # C# Code (Injector) - นิยามไว้ทั้งข้างนอกและข้างใน Job
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

    # --- จังหวะที่ 1: ฉีดทันทีในหน้าหลัก (First Hit) ---
    $mainProc = Get-Process $targetProc -ErrorAction SilentlyContinue
    if ($mainProc) {
        Write-Host "[*] Initial Injection into HD-Player..." -ForegroundColor Yellow
        [Injector]::Run($tempPath, $mainProc.Id)
        Write-Host "[+] First Lock Successful!" -ForegroundColor Green
    } else {
        Write-Host "[!] HD-Player not found. Waiting in background..." -ForegroundColor Magenta
    }

    # --- จังหวะที่ 2: ส่งงานไปทำเบื้องหลัง (Background Service) ---
    $ScriptBlock = {
        param($path, $pName, $sourceCode)
        Add-Type -AssemblyName PresentationCore
        Add-Type -TypeDefinition $sourceCode # โหลดโค้ดฉีดซ้ำใน Job

        while ($true) {
            $proc = Get-Process $pName -ErrorAction SilentlyContinue
            if ($proc) {
                $alreadyIn = $false
                try {
                    foreach ($m in $proc.Modules) { if ($m.ModuleName -eq "winsky.dll") { $alreadyIn = $true; break } }
                } catch { }

                if (-not $alreadyIn) {
                    [Injector]::Run($path, $proc.Id)
                }
            }

            # ปุ่ม Home: ปิดเกม + ล้างไฟล์ + หยุด Job
            if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
                Stop-Process -Name $pName -Force -ErrorAction SilentlyContinue
                Remove-Item $path -Force -ErrorAction SilentlyContinue
                break
            }
            Start-Sleep -Seconds 3
        }
    }

    Start-Job -ScriptBlock $ScriptBlock -ArgumentList $tempPath, $targetProc, $code -Name "BasX_Ultra_Service"

    Write-Host "[+] BasX System: ACTIVE (Background)" -ForegroundColor Green
    Write-Host "[!] ปิดหน้าต่างนี้ได้เลย ระบบจะคุมให้เองแม้รีบลู" -ForegroundColor Cyan
    Write-Host "[!] กดปุ่ม 'HOME' เพื่อปิดเกมและหยุดโปร" -ForegroundColor Red
    Start-Sleep -Seconds 3
}
