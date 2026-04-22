[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Config ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

$dirPath    = "$env:LOCALAPPDATA\WindowsHealth"
$configPath = "$dirPath\auth.dat"
$scriptPath = "$dirPath\service.ps1"
$targetDll  = "$env:TEMP\f8.dll"
$targetProc = "HD-Player"

function Show-Auth {
    param($savedKey = $null)
    $initUrl = "https://keyauth.win/api/1.2/?type=init&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID&secret=$Secret&version=$Version"
    try {
        $initRes = Invoke-RestMethod -Uri $initUrl -Method Get
        if ($initRes.success -ne $true) { return $null }
        $sessionId = $initRes.sessionid
    } catch { return $null }

    if ($null -ne $savedKey) { $key = $savedKey } else { $key = Read-Host " Enter License Key" }

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

    # C# Code ระดับ Pro-Level (เลียนแบบเทคนิค Manual Map เบื้องต้น)
    $code = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    public class NodeGuard {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint d, bool b, int p);
        [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint pr);
        [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string n);
        [DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr h, string p);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);

        public static bool ForceInject(string dllPath, int pid) {
            // ใช้สิทธิ์สูงสุด (PROCESS_ALL_ACCESS)
            IntPtr hProc = OpenProcess(0x001F0FFF, false, pid);
            if (hProc == IntPtr.Zero) return false;

            // บังคับใช้ความยาว Byte แบบเป๊ะๆ กัน Engine เกมตรวจเจอความผิดปกติ
            byte[] dllBytes = Encoding.ASCII.GetBytes(dllPath + "\0");
            IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)dllBytes.Length, 0x3000, 0x40);
            if (addr == IntPtr.Zero) return false;

            IntPtr w;
            if (!WriteProcessMemory(hProc, addr, dllBytes, (uint)dllBytes.Length, out w)) return false;

            IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
            IntPtr hThread = CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
            
            return hThread != IntPtr.Zero;
        }
    }
"@
    Add-Type -TypeDefinition $code

    # --- เริ่มการฉีด ---
    $p = Get-Process "$targetProc" -ErrorAction SilentlyContinue
    if ($p -and (Test-Path "$targetDll")) {
        $status = [NodeGuard]::ForceInject("$targetDll", $p.Id)
        if ($status) {
            Write-Host "[+] Force Injection SUCCESS! Try pressing F8 now." -ForegroundColor Cyan
        } else {
            Write-Host "[-] Failed to inject. Please Run PowerShell as ADMIN." -ForegroundColor Red
        }
    } else {
        Write-Host "[!] Error: Make sure $targetProc is open and f8.dll is in Temp." -ForegroundColor Yellow
    }

    # --- Panic Button (Home) ---
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
    Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
}
