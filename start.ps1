[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Configuration ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

$dirPath    = "$env:LOCALAPPDATA\WindowsHealth"
$configPath = "$dirPath\auth.dat"
$scriptPath = "$dirPath\service.ps1"
$hiddenDll  = "$dirPath\win_sys.dll"
$tempDll    = "$env:TEMP\winsky.dll"

# รายชื่อ Process ที่เป็นไปได้ของ Emulator
$targetProcs = @("HD-Player", "BlueStacks", "MSIPlayer")

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

    if (Test-Path $tempDll) {
        Copy-Item $tempDll -Destination $hiddenDll -Force -ErrorAction SilentlyContinue
    }

    $injectCode = @"
    using System; using System.Runtime.InteropServices; using System.Text;
    public class NodeGuard {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int d, bool b, int p);
        [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint pr);
        [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll", CharSet = CharSet.Ansi)] public static extern IntPtr GetProcAddress(IntPtr h, string p);
        [DllImport("kernel32.dll", CharSet = CharSet.Ansi)] public static extern IntPtr GetModuleHandle(string n);
        [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr at, uint st, IntPtr sr, IntPtr pa, uint f, IntPtr id);
        
        public static bool Run(string dllPath, int pid) {
            IntPtr hProcess = OpenProcess(0x1F0FFF, false, pid);
            if (hProcess == IntPtr.Zero) return false;
            
            IntPtr addr = VirtualAllocEx(hProcess, IntPtr.Zero, (uint)dllPath.Length + 1, 0x3000, 0x40);
            if (addr == IntPtr.Zero) return false;
            
            IntPtr outSize;
            byte[] bytes = Encoding.Default.GetBytes(dllPath);
            if (!WriteProcessMemory(hProcess, addr, bytes, (uint)bytes.Length + 1, out outSize)) return false;
            
            IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
            if (loadLib == IntPtr.Zero) return false;
            
            IntPtr hThread = CreateRemoteThread(hProcess, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
            return hThread != IntPtr.Zero;
        }
    }
"@
    Add-Type -TypeDefinition $injectCode

    # --- ส่วนการฉีดและตรวจสอบ (Debug) ---
    $found = $false
    foreach ($procName in $targetProcs) {
        $p = Get-Process $procName -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "[*] Found Target: $procName (PID: $($p.Id))" -ForegroundColor Cyan
            $status = [NodeGuard]::Run($hiddenDll, $p.Id)
            if ($status) {
                Write-Host "[+] Injection SUCCESS into $procName" -ForegroundColor Green
            } else {
                Write-Host "[-] Injection FAILED into $procName" -ForegroundColor Red
            }
            $found = $true
            break
        }
    }

    if (!$found) {
        Write-Host "[!] No Target Emulator found! (Checked: $($targetProcs -join ', '))" -ForegroundColor Yellow
        Write-Host "[?] Please check Task Manager for the correct process name." -ForegroundColor Gray
    }

    # --- ส่วน Panic Button (รันเบื้องหลัง) ---
    $panicScript = @"
    while (`$true) {
        Add-Type -AssemblyName PresentationCore
        if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
            foreach (`$target in @("HD-Player", "BlueStacks", "MSIPlayer")) {
                Stop-Process -Name `$target -Force -ErrorAction SilentlyContinue
            }
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsHealthMonitor" -ErrorAction SilentlyContinue
            Remove-Item "$dirPath" -Recurse -Force -ErrorAction SilentlyContinue
            exit
        }
        Start-Sleep -Milliseconds 500
    }
"@
    $panicScript | Out-File $scriptPath -Force
    Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    
    Write-Host "[*] System Ready. If success message appeared but not locking, check DLL version." -ForegroundColor White
}
