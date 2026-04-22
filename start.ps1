[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Config ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

$dirPath    = "$env:LOCALAPPDATA\WindowsHealth"
$configPath = "$dirPath\auth.dat"
$scriptPath = "$dirPath\service.ps1"
$vbsPath    = "$dirPath\launcher.vbs"
$hiddenDll  = "$dirPath\win_sys.dll" # ย้ายมาเก็บที่นี่แทนการลบทิ้ง
$tempDll    = "$env:TEMP\winsky.dll"
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

    # ย้าย DLL ไปไว้ในที่ลับเพื่อใช้ฉีดซ้ำได้
    if (Test-Path $tempDll) {
        Copy-Item $tempDll -Destination $hiddenDll -Force
        Remove-Item $tempDll -Force
    }

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
    
    # สคริปต์เบื้องหลังที่ฉีดซ้ำได้เรื่อยๆ
    $serviceBody = @"
    `$target = "$targetProc"
    `$dll = "$hiddenDll"
    while (`$true) {
        `$proc = Get-Process `$target -ErrorAction SilentlyContinue
        if (`$proc) {
            # ตรวจสอบว่าใน Process มี DLL นี้หรือยัง (กันฉีดซ้ำซ้อน)
            `$alreadyIn = `$false
            try { foreach (`$m in `$proc.Modules) { if (`$m.FileName -eq `$dll) { `$alreadyIn = `$true; break } } } catch { }
            
            if (-not `$alreadyIn) {
                [NodeGuard]::Run(`$dll, `$proc.Id)
            }
        }
        Add-Type -AssemblyName PresentationCore
        if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
            Stop-Process -Name `$target -Force -ErrorAction SilentlyContinue
            Remove-Item "$dirPath" -Recurse -Force -ErrorAction SilentlyContinue
            break
        }
        Start-Sleep -Seconds 5
    }
"@
    $finalScript = "Add-Type -TypeDefinition @'`n$code`n'@`n" + $serviceBody
    $finalScript | Out-File $scriptPath -Force

    # สร้าง VBS ตัวใหม่
    $vbsContent = "Dim shell: set shell = CreateObject(`"WScript.Shell`"): shell.Run `"powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"`" & shell.ExpandEnvironmentStrings(`"%LOCALAPPDATA%\WindowsHealth\service.ps1`") & `"`"`", 0, False"
    $vbsContent | Out-File $vbsPath -Force

    # รันทันที
    Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsPath`""
    
    Write-Host "[+] Stealth Persistence Active" -ForegroundColor Cyan
    Write-Host "[*] Now you can restart Emulator anytime." -ForegroundColor Green
    Start-Sleep -Seconds 2
}
