[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- App Config ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"
$dllUrl  = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/main/winsky.dll"

function Show-Auth {
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "   BASX SYSTEM SIDE-LOADER    " -ForegroundColor Cyan
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
    
    # 1. Download DLL to a permanent system location
    $destPath = "C:\Windows\System32\win_driver_ext.dll"
    Write-Host "[*] Downloading system component..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $dllUrl -OutFile $destPath -ErrorAction Stop
    } catch {
        Write-Host "[-] Download Failed. Run as Admin!" -ForegroundColor Red
        return
    }

    # 2. Use Windows Registry to force-load the DLL (AppInit_DLLs)
    Write-Host "[!] Side-loading into Windows environment..." -ForegroundColor Yellow
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows"
    
    try {
        # Enable AppInit_DLLs
        Set-ItemProperty -Path $regPath -Name "LoadAppInit_DLLs" -Value 1
        # Set the DLL path
        Set-ItemProperty -Path $regPath -Name "AppInit_DLLs" -Value $destPath
        
        Write-Host "[+] SYSTEM LOADED SUCCESSFULLY!" -ForegroundColor Green
        Write-Host "[*] IMPORTANT: Close and RESTART your Emulator now." -ForegroundColor White
        Write-Host "[*] The DLL will auto-load when HD-Player starts." -ForegroundColor White
    } catch {
        Write-Host "[-] Registry Access Denied. Check your Antivirus!" -ForegroundColor Red
    }
}
