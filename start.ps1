[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Configuration ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"

$dirPath    = "$env:LOCALAPPDATA\WindowsHealth"
$configPath = "$dirPath\auth.dat"
$scriptPath = "$dirPath\service.ps1"
$targetDll  = "$env:TEMP\f8.dll"
$hackerExe  = "$env:TEMP\Activate.exe"
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

    if ((Test-Path $hackerExe) -and (Test-Path $targetDll)) {
        Write-Host "[*] Opening Activate.exe for Manual Injection..." -ForegroundColor Cyan
        Write-Host "[!] ขั้นตอน: คลิกขวาที่ HD-Player > Miscellaneous > Inject DLL > เลือก f8.dll ใน Temp" -ForegroundColor Yellow
        
        # รัน Activate.exe (Process Hacker) ขึ้นมาแบบมีสิทธิ์ Admin เพื่อให้ Driver ทำงาน
        Start-Process -FilePath $hackerExe -Verb RunAs

        # รอให้คุณฉีดเสร็จ (กด Enter เมื่อฉีดเสร็จแล้ว)
        Read-Host " หลังจากฉีดเสร็จและล็อคติดแล้ว ให้กด Enter เพื่อลบไฟล์ร่องรอย"
        
        # --- ทำลายหลักฐานหลังใช้งาน ---
        Remove-Item $targetDll -Force -ErrorAction SilentlyContinue
        # ไม่ลบ Activate.exe ทันทีเพราะโปรแกรมอาจยังเปิดอยู่
        Write-Host "[+] Traces Cleaned." -ForegroundColor Green
    }

    # --- Panic Button (Home) ---
    $panicBody = @"
    while (`$true) {
        Add-Type -AssemblyName PresentationCore
        if ([Windows.Input.Keyboard]::IsKeyDown([Windows.Input.Key]::Home)) {
            Stop-Process -Name "$targetProc" -Force -ErrorAction SilentlyContinue
            Stop-Process -Name "Activate" -Force -ErrorAction SilentlyContinue
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
