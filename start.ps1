[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Final Control Config ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"
$target  = "HD-Player"

function Show-Auth {
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "   BASX EXTERNAL CONTROLLER   " -ForegroundColor Cyan
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

    # โหลด Library สำหรับควบคุมคีย์บอร์ด
    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Windows.Forms;

    public class ExternalControl {
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);
        
        public static void PressF6() {
            keybd_event(0x75, 0, 0, 0); // F6 Key Down
            System.Threading.Thread.Sleep(100);
            keybd_event(0x75, 0, 0x0002, 0); // F6 Key Up
        }
    }
"@
    Add-Type -ReferencedAssemblies "System.Windows.Forms" -TypeDefinition $Source

    Write-Host "[*] Controller active. Waiting for $target..." -ForegroundColor Cyan
    while ($true) {
        $p = Get-Process $target -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "[!] Target found. Activating function via Key Signal..." -ForegroundColor Yellow
            
            # บังคับให้หน้าต่างเกมเด้งขึ้นมาข้างหน้า
            [ExternalControl]::SetForegroundWindow($p.MainWindowHandle)
            Start-Sleep -Milliseconds 500
            
            # ส่งคำสั่งกด F6 ไปยังเกมโดยตรงจากระบบ
            [ExternalControl]::PressF6()
            
            Write-Host "[+] F6 Signal Sent! Check your headshot lock in game." -ForegroundColor Green
            break
        }
        Start-Sleep -Seconds 3
    }
}
