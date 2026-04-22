[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Final Configuration ---
$Name    = "Relaxwtf777's Application"
$OwnerID = "W404AorT6U"
$Secret  = "bdd0ab6c75599fffdb5ad43d22a82fe8bf8fa0fbd92dfdfbb2df80dc6d105d38"
$Version = "1.0"
$target  = "HD-Player"

function Show-Auth {
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "    BASX DIRECT PATCHER v3    " -ForegroundColor Cyan
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

    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Diagnostics;

    public class DirectPatch {
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint acc, bool inh, int pid);
        [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out IntPtr w);
        [DllImport("kernel32.dll")] public static extern bool VirtualProtectEx(IntPtr h, IntPtr a, uint s, uint newP, out uint oldP);

        public static bool Apply(int pid, long address, byte[] patchData) {
            IntPtr hProc = OpenProcess(0x1F0FFF, false, pid);
            if (hProc == IntPtr.Zero) return false;

            uint oldProtect;
            // Unprotect memory before writing
            VirtualProtectEx(hProc, (IntPtr)address, (uint)patchData.Length, 0x40, out oldProtect);
            
            IntPtr written;
            bool success = WriteProcessMemory(hProc, (IntPtr)address, patchData, (uint)patchData.Length, out written);
            
            // Restore protection
            VirtualProtectEx(hProc, (IntPtr)address, (uint)patchData.Length, oldProtect, out oldProtect);
            return success;
        }
    }
"@
    Add-Type -TypeDefinition $Source

    # ข้อมูล Patch (ตัวอย่าง: แก้ค่าล็อคหัวโดยตรง)
    $patchAddr = 0x2EC 
    $hexData = @(0xFF, 0xFF, 0x90, 0x90) # ค่าที่ใช้ Patch

    Write-Host "[*] Status: Searching for $target..." -ForegroundColor Cyan
    while ($true) {
        $p = Get-Process $target -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "[!] Target found. Patching memory directly..." -ForegroundColor Yellow
            if ([DirectPatch]::Apply($p.Id, $patchAddr, $hexData)) {
                Write-Host "[+] DONE! Memory patched successfully." -ForegroundColor Green
                Write-Host "[*] You can start playing now." -ForegroundColor White
                break
            } else {
                Write-Host "[-] Critical Error: Memory is write-protected." -ForegroundColor Red
                Start-Sleep -Seconds 5
            }
        }
        Start-Sleep -Seconds 2
    }
}
