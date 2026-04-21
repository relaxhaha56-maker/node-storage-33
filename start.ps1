[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- ข้อมูล KeyAuth ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

function Show-Auth {
    Clear-Host
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "    BASX AIMBOT AI v$Version" -ForegroundColor Cyan
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
    # กำหนดชื่อไฟล์และ Path ให้ชัดเจน
    $dllUrl = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/refs/heads/main/winsky.dll"
    $tempPath = "$env:TEMP\winsky.dll"
    $targetProc = "HD-Player"

    Write-Host "[*] Downloading winsky.dll..." -ForegroundColor Yellow
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($dllUrl, $tempPath)
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
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
        [DllImport("kernel32.dll", CharSet = CharSet.Auto)] public static extern IntPtr GetModuleHandle(string lpModuleName);
        [DllImport("kernel32", CharSet = CharSet.Ansi, ExactSpelling = true, SetLastError = true)] static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
        [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)] static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
        [DllImport("kernel32.dll", SetLastError = true)] static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);
        [DllImport("kernel32.dll")] static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
        
        public static void StartNode(string path, string pName) {
            Process[] target = Process.GetProcessesByName(pName);
            if (target.Length == 0) return;
            IntPtr hProc = OpenProcess(0x001F0FFF, false, target[0].Id);
            IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)path.Length + 1, 0x3000, 0x40);
            IntPtr outSize;
            WriteProcessMemory(hProc, addr, Encoding.Default.GetBytes(path), (uint)path.Length + 1, out outSize);
            IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
            CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
        }
    }
"@
    Add-Type -TypeDefinition $Source

    # ทำการฉีดเข้า HD-Player ทันที
    Write-Host "[*] Injecting winsky.dll into HD-Player..." -ForegroundColor Yellow
    [NodeHandler]::StartNode($tempPath, $targetProc)
    Write-Host "[+] Injection Completed." -ForegroundColor Green

    # ระบบ Panic Button รันเบื้องหลังเพื่อดักปุ่ม Home
    $ScriptBlock = {
        param($path)
        Add-Type -AssemblyName PresentationCore
        while ($true) {
            if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
                # ลบไฟล์ DLL ทันทีเพื่อทำลายร่องรอย
                Remove-Item $path -Force -ErrorAction SilentlyContinue
                break
            }
            Start-Sleep -Seconds 1
        }
    }
    Start-Job -ScriptBlock $ScriptBlock -ArgumentList $tempPath -Name "BasX_Panic"

    Write-Host "[!] System Ready. Press 'HOME' to Clean up." -ForegroundColor Red
    Start-Sleep -Seconds 3
} else {
    Write-Host "[-] Login Failed." -ForegroundColor Red
}
