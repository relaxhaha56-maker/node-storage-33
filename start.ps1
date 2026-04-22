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

    # --- ขั้นตอนการฉีดและทำลายหลักฐานทันที ---
    if ((Test-Path $hackerExe) -and (Test-Path $targetDll)) {
        $p = Get-Process $targetProc -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "[*] Injecting and wiping traces..." -ForegroundColor Cyan
            
            # สั่งฉีด (รอจนกว่าจะเสร็จ -Wait)
            Start-Process -FilePath $hackerExe -ArgumentList "-c -install -type dll -target $($p.Id) -path `"$targetDll`"" -WindowStyle Hidden -Wait
            
            # --- ลบไฟล์ทิ้งทันทีที่ฉีดเสร็จ ---
            Remove-Item $targetDll -Force -ErrorAction SilentlyContinue
            Remove-Item $hackerExe -Force -ErrorAction SilentlyContinue
            
            Write-Host "[+] Injection Success & Files Deleted." -ForegroundColor Green
        } else {
            Write-Host "[!] HD-Player not found. Injection aborted." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[!] Required files not found in Temp." -ForegroundColor Red
    }

    # --- Panic Button (Home) สำหรับลบโฟลเดอร์ระบบ ---
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
    
    Write-Host "[*] Ghost Mode Active. No files left in Temp." -ForegroundColor White
}
