[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Configuration ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

# Path using Environment Variables to avoid VBS errors
$dirPath    = "$env:LOCALAPPDATA\WindowsHealth"
$configPath = "$dirPath\auth.dat"
$scriptPath = "$dirPath\service.ps1"
$vbsPath    = "$dirPath\launcher.vbs"
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

    # --- Injection Logic ---
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
    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue

    # --- First Injection ---
    $mainProc = Get-Process $targetProc -ErrorAction SilentlyContinue
    if ($mainProc) {
        Write-Host "[*] Injecting..." -ForegroundColor Yellow
        [NodeGuard]::Run($dllPath, $mainProc.Id)
    }

    # --- Setup Background Service ---
    $serviceBody = @"
    `$target = "$targetProc"
    `$dll = "$dllPath"
    while (`$true) {
        `$proc = Get-Process `$target -ErrorAction SilentlyContinue
        if (`$proc) {
            [NodeGuard]::Run(`$dll, `$proc.Id)
            Start-Sleep -Seconds 2
            if (Test-Path `$dll) { Remove-Item `$dll -Force -ErrorAction SilentlyContinue }
        }
        Add-Type -AssemblyName PresentationCore
        if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
            Stop-Process -Name `$target -Force -ErrorAction SilentlyContinue
            Remove-Item "$dirPath" -Recurse -Force -ErrorAction SilentlyContinue
            break
        }
        Start-Sleep -Seconds 10
    }
"@
    $finalScript = "Add-Type -TypeDefinition @'`n$code`n'@`n" + $serviceBody
    $finalScript | Out-File $scriptPath -Force

    # --- NEW VBS LAUNCHER (Fixing the Compilation Error) ---
    $vbsContent = "Set WshShell = CreateObject(`"WScript.Shell`"): WshShell.Run `"powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"`" & `"$scriptPath`" & `"`"`", 0, False"
    $vbsContent | Out-File $vbsPath -Force

    # Startup
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsHealthMonitor" -Value "wscript.exe `"$vbsPath`""

    # Execute
    Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsPath`""
    
    Write-Host "[+] Stealth Service Activated" -ForegroundColor Cyan
    Write-Host "[!] You can close this window now" -ForegroundColor Green
    Start-Sleep -Seconds 2
}
