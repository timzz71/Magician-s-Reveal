# MeowScanner.ps1 – Minecraft SS Forensic Scanner (detect.ac‑parity edition)
# Version: 1.0.0
# Author: System Forensics
# Description: One‑shot, consented, investigator‑run scan for Minecraft cheat artifacts.
# Flags: Info (21) | Warning (63) | Detection (48) – 132 total.
# Usage: .\MeowScanner.ps1 [-OutputDir <path>] [-MinecraftDir <path>]
# ------------------------------------------------------------

param(
    [string]$OutputDir = $PWD.Path,
    [string]$MinecraftDir = "$env:APPDATA\.minecraft"
)

# ---- Embedded Flag Catalogue (132 flags) ----
$script:FlagCatalogue = @{
    "info" = @(
        @{ id = "ACCOUNT_MINECRAFT"; category = "Accounts & Identity"; title = "Minecraft Account"; message = "Usernames from launcher data: {usernames}" },
        @{ id = "ACCOUNT_STEAM"; category = "Accounts & Identity"; title = "Steam Account"; message = "Steam ID / account ID: {steam_id}" },
        @{ id = "ACCOUNT_UPLAY"; category = "Accounts & Identity"; title = "R6 Account Uplay ID"; message = "Uplay ID: {uplay_id}" },
        @{ id = "SERIAL_NUMBER"; category = "System Snapshot"; title = "Serial Number"; message = "System serial: {serial}" },
        @{ id = "WINDOWS_INSTALLED"; category = "System Snapshot"; title = "Windows Installed"; message = "Installed {elapsed} ago" },
        @{ id = "USER_LOGON_TIME"; category = "System Snapshot"; title = "User Logon Time"; message = "Logon time: {logon_time}" },
        @{ id = "SCAN_TIME"; category = "System Snapshot"; title = "Scan Time"; message = "Scan started at {scan_time}" },
        @{ id = "PROCESS_START_TIMES"; category = "System Snapshot"; title = "Process Start Times"; message = "Explorer: {explorer_start}, javaw: {javaw_start}" },
        @{ id = "FILE_TRANSFER_ANYDESK"; category = "File & Device Activity"; title = "File Transferred Over Anydesk"; message = "File {file} transferred via AnyDesk" },
        @{ id = "DELETED_EXE"; category = "File & Device Activity"; title = "Deleted Exe"; message = "Deleted executable: {path}" },
        @{ id = "DOWNLOADED_SAVED_FILE"; category = "File & Device Activity"; title = "Downloaded / Saved File"; message = "File {file} downloaded (unsigned/missing)" },
        @{ id = "CRASHED_FILE_NOT_PRESENT"; category = "File & Device Activity"; title = "Crashed File Not Present"; message = "Crashed file missing: {file}" },
        @{ id = "MALICIOUS_FILE_DEFENDER"; category = "File & Device Activity"; title = "Malicious File (Defender History)"; message = "Defender detected: {file}" },
        @{ id = "DEVICE_REMOVED_AFTER_LOGON"; category = "File & Device Activity"; title = "Device Removed After Logon"; message = "Device {device} removed post‑logon" },
        @{ id = "DEVICE_REMOVED_BEFORE_LOGON"; category = "File & Device Activity"; title = "Device Removed Before Logon"; message = "Device {device} removed pre‑logon" },
        @{ id = "DISK_PARTITION_CREATED"; category = "File & Device Activity"; title = "Disk Partition Created"; message = "Partition {partition} created" },
        @{ id = "PROXY_VPN_NOT_FOUND"; category = "System State"; title = "Proxy / VPN Not Found"; message = "No proxy/VPN detected" },
        @{ id = "KERNEL_DMA_DISABLED"; category = "System State"; title = "Kernel DMA Protection Disabled"; message = "Kernel DMA Protection is off" },
        @{ id = "CRASH_DUMP_FOLDER_NOT_PRESENT"; category = "System State"; title = "CrashDump Folder Not Present"; message = "Crash dump folder missing" },
        @{ id = "CLEARED_EVENT_LOG"; category = "System State"; title = "Cleared Event Log Before Logon"; message = "Event log cleared pre‑logon" },
        @{ id = "BROWSING_HISTORY_CLEARED"; category = "System State"; title = "Browsing History Cleared Recently"; message = "Browsing history cleared recently" },
        @{ id = "TIME_CHANGE"; category = "System State"; title = "Time Change"; message = "System time changed: {change}" },
        @{ id = "OPENSAVEPIDLMRU_CLEANED"; category = "System State"; title = "OpenSavePidlMRU Cleaned"; message = "OpenSavePidlMRU cleaned" }
    )
    "warning" = @(
        @{ id = "BAM_STOPPED_RESTARTED"; category = "BAM & Install Date"; title = "BAM Stopped/Restarted/Paused/Offline"; message = "BAM service state changed: {state}" },
        @{ id = "BAM_HAS_BEEN_CLEANED"; category = "BAM & Install Date"; title = "BAM Has Been Cleaned"; message = "BAM key cleaned" },
        @{ id = "DELETED_BAM_KEY"; category = "BAM & Install Date"; title = "Deleted BAM Key"; message = "BAM registry key deleted" },
        @{ id = "SPOOFED_WINDOWS_INSTALL_DATE"; category = "BAM & Install Date"; title = "Spoofed Windows Install Date"; message = "Install date appears spoofed" },
        @{ id = "CLEARED_EVENT_LOG_SINCE_LOGON"; category = "EventLog Tampering"; title = "Cleared Event Log Since Logon"; message = "Event log cleared post‑logon (non‑critical)" },
        @{ id = "EVENTLOG_SET_READONLY"; category = "EventLog Tampering"; title = "Eventlog Set To Read Only"; message = "Event log file set read‑only" },
        @{ id = "EVENTLOG_READONLY_CORROBORATED"; category = "EventLog Tampering"; title = "Eventlog Read-Only (corroborated)"; message = "Event log read‑only with deleted‑exe artifact" },
        @{ id = "EVENTLOG_FILE_RENAMED"; category = "EventLog Tampering"; title = "Eventlog File Renamed"; message = "Event log file renamed: {new_name}" },
        @{ id = "USN_JOURNAL_SIZE_MODIFIED"; category = "USN Journal & FAT Drives"; title = "USN Journal Size Modified"; message = "USN journal shrunk abnormally" },
        @{ id = "USN_JOURNAL_NOT_PRESENT"; category = "USN Journal & FAT Drives"; title = "USN Journal Not Present On Drive"; message = "USN journal missing on drive {drive}" },
        @{ id = "WINDOWSDB_FILE_CLEANED"; category = "USN Journal & FAT Drives"; title = "WindowsDB File Cleaned"; message = "WindowsDB file cleaned" },
        @{ id = "ACTIVITIESCACHE_ARTIFACT_CLEANED"; category = "USN Journal & FAT Drives"; title = "Activitiescache Artifact Cleaned"; message = "Activities cache cleaned" },
        @{ id = "JUNCTION_DELETED"; category = "USN Journal & FAT Drives"; title = "Junction Deleted"; message = "Junction deleted at {path}" },
        @{ id = "FOUND_FAT_DRIVE"; category = "USN Journal & FAT Drives"; title = "Found FAT Drive"; message = "FAT drive present: {drive}" },
        @{ id = "FILE_ON_FAT_DRIVE_MODIFIED"; category = "USN Journal & FAT Drives"; title = "File On FAT Drive Modified"; message = "File {file} on FAT modified" },
        @{ id = "FAT_DRIVE_FILE_REPLACED"; category = "USN Journal & FAT Drives"; title = "FAT Drive File Replaced/Renamed"; message = "File replaced/renamed on FAT" },
        @{ id = "NOT_SIGNED_FILE_EXECUTED"; category = "File Execution Indicators"; title = "Not Signed File Executed"; message = "Unsigned file executed: {file}" },
        @{ id = "FILE_RAN_WITH_MODIFIED_EXTENSION"; category = "File Execution Indicators"; title = "File Ran With Modified Extension"; message = "File {file} ran with altered extension" },
        @{ id = "FILE_EXECUTED_FROM_DIFFERENT_DRIVE"; category = "File Execution Indicators"; title = "File Executed From Different Drive"; message = "File executed from {drive}" },
        @{ id = "SUSPICIOUS_FILE_RAN_AS_ADMIN"; category = "File Execution Indicators"; title = "Suspicious File Ran As Administrator"; message = "File {file} ran elevated" },
        @{ id = "EXECUTED_BAT_CMD_FILE"; category = "File Execution Indicators"; title = "Executed .bat/.cmd File"; message = "Batch file executed: {file}" },
        @{ id = "EXECUTED_PYTHON_FILE"; category = "File Execution Indicators"; title = "Executed Python File"; message = "Python script executed: {file}" },
        @{ id = "NOT_FOUND_EXECUTED_PYTHON_FILE"; category = "File Execution Indicators"; title = "Not Found Executed Python File"; message = "Python file ran then self‑deleted" },
        @{ id = "POSSIBLE_AHK_BYPASS_SCRIPT"; category = "File Execution Indicators"; title = "Possible AHK Bypass Script Found"; message = "AHK script found: {file}" },
        @{ id = "POWERSHELL_EVENTLOG_MAXSIZE_MODIFIED"; category = "PowerShell Activity"; title = "Powershell Eventlog Max Size Modified"; message = "PS event log max size changed" },
        @{ id = "POSSIBLE_SUSPICIOUS_POWERSHELL"; category = "PowerShell Activity"; title = "Possible Suspicious Powershell Command"; message = "Suspicious PS command: {cmd}" },
        @{ id = "POTENTIALLY_MALICIOUS_POWERSHELL_PROFILE"; category = "PowerShell Activity"; title = "Potentially Malicious Powershell Profile"; message = "Malicious PS profile found" },
        @{ id = "DISK_VOLUME_WITHOUT_DRIVE_LETTER"; category = "Generic Bypass Indicators"; title = "Disk Volume Without Drive Letter"; message = "Volume {volume} has no drive letter" },
        @{ id = "PREFETCH_DUPLICATE_HASH"; category = "Generic Bypass Indicators"; title = "Prefetch Files With Duplicate Hash"; message = "Duplicate prefetch hash detected" },
        @{ id = "SUSPICIOUS_ALTERNATE_DATA_STREAM"; category = "Generic Bypass Indicators"; title = "Suspicious Alternate Data Stream"; message = "ADS found: {stream}" },
        @{ id = "HOSTS_FILE_MODIFIED"; category = "Generic Bypass Indicators"; title = "Hosts File Modified"; message = "Hosts file has been modified" },
        @{ id = "SERVICE_IS_NOT_RUNNING"; category = "Generic Bypass Indicators"; title = "Service Is Not Running"; message = "Service {service} is stopped" },
        @{ id = "SERVICE_HAS_BEEN_RESTARTED"; category = "Generic Bypass Indicators"; title = "Service Has Been Restarted"; message = "Service {service} restarted" },
        @{ id = "RECYCLE_BIN_MODIFIED"; category = "Generic Bypass Indicators"; title = "Recycle Bin Modified"; message = "Recycle Bin modified" },
        @{ id = "DISK_PARTITION_DELETED"; category = "Generic Bypass Indicators"; title = "Disk Partition Deleted"; message = "Partition {partition} deleted" },
        @{ id = "VIRTUAL_DISK_DELETED"; category = "Generic Bypass Indicators"; title = "Virtual Disk Deleted"; message = "Virtual disk deleted" },
        @{ id = "SUSPICIOUS_AUTORUNS_FILE"; category = "Generic Bypass Indicators"; title = "Suspicious Autoruns File"; message = "Autoruns entry: {file}" },
        @{ id = "SUSPICIOUS_WMI_INSTRUCTION"; category = "Generic Bypass Indicators"; title = "Suspicious WMI Instruction Found"; message = "WMI instruction: {wmi}" },
        @{ id = "SUSPICIOUS_TASK"; category = "Generic Bypass Indicators"; title = "Suspicious Task / Suspicious Task With Script"; message = "Task {task} found with script" },
        @{ id = "FOLDER_MAPPED_TO_EXTERNAL_DRIVE"; category = "Generic Bypass Indicators"; title = "Folder Mapped To External Drive"; message = "Folder {folder} mapped to external drive" },
        @{ id = "POSSIBLE_HDMI_FUSER_DETECTED"; category = "Generic Bypass Indicators"; title = "Possible HDMI Fuser Detected"; message = "HDMI fuser activity detected" },
        @{ id = "POSSIBLE_SPOOFED_DMA_FOUND"; category = "Generic Bypass Indicators"; title = "Possible Spoofed DMA Found"; message = "Spoofed DMA detected" },
        @{ id = "SECURE_BOOT_DISABLED"; category = "Generic Bypass Indicators"; title = "Secure Boot Disabled"; message = "Secure Boot is disabled" },
        @{ id = "NVIDIA_STREAMPROOF_BYPASS_REG"; category = "Generic Bypass Indicators"; title = "NVIDIA Streamproof Bypass (Registry Modified)"; message = "Streamproof registry modified" },
        @{ id = "PROXY_VPN_FOUND"; category = "Generic Bypass Indicators"; title = "Proxy / VPN Found"; message = "Proxy/VPN detected: {proxy}" },
        @{ id = "PREVIOUSLY_INJECTED_DLL"; category = "In-Process Memory Discoveries"; title = "Previously Injected DLL"; message = "DLL {dll} injected into {process}" },
        @{ id = "PE_INJECTION_OUT_OF_INSTANCE"; category = "In-Process Memory Discoveries"; title = "PE Injection Out Of Instance"; message = "PE injected into {process}" },
        @{ id = "APP_WITH_SUSPICIOUS_DATA_USAGE"; category = "In-Process Memory Discoveries"; title = "App With Suspicious Data Usage"; message = "App {app} has unusual data usage" },
        @{ id = "DISCORD_ACCOUNT"; category = "In-Process Memory Discoveries"; title = "Discord Account"; message = "Discord account found: {user}" },
        @{ id = "CUSTOM_STRING_FOUND_WARNING"; category = "In-Process Memory Discoveries"; title = "Custom String Found (Warning)"; message = "String '{string}' found in memory" },
        @{ id = "FOUND_IN_DNSCACHE"; category = "In-Process Memory Discoveries"; title = "Found In Dnscache"; message = "Domain {domain} in DNS cache" },
        @{ id = "FOUND_IN_BROWSER_MEMORY"; category = "In-Process Memory Discoveries"; title = "Found In Browser Memory"; message = "String '{string}' in browser memory" },
        @{ id = "FOUND_IN_REGISTRY"; category = "In-Process Memory Discoveries"; title = "Found In Registry"; message = "Value '{value}' in registry" },
        @{ id = "POTENTIAL_JAR_CLIENT_FOUND"; category = "In-Process Memory Discoveries"; title = "Potential JAR Client Found"; message = "JAR client '{client}' found" },
        @{ id = "UNKNOWN_MINECRAFT_GAME_INSTANCE"; category = "In-Process Memory Discoveries"; title = "Unknown Minecraft Game Instance"; message = "Unknown Minecraft instance: {instance}" },
        @{ id = "CUSTOM_AMCACHE_HASH_WARNING"; category = "In-Process Memory Discoveries"; title = "Custom Amcache Hash Found/Not Found"; message = "Amcache hash {hash} for {file}" },
        @{ id = "POSSIBLE_SUSPICIOUS_FILE_YARA"; category = "In-Process Memory Discoveries"; title = "Possible Suspicious File (YARA)"; message = "YARA match on {file}" },
        @{ id = "PREFETCH_FILE_TYPED_MODIFIED"; category = "Generic File Tampering"; title = "Prefetch File Typed / Modified"; message = "Prefetch file {file} modified" },
        @{ id = "ICACLS_EXE_USED"; category = "Generic File Tampering"; title = "ICACLS.EXE Used"; message = "ICACLS used on {path}" },
        @{ id = "AMCACHE_CLEANED"; category = "Generic File Tampering"; title = "Amcache Cleaned"; message = "Amcache hive cleaned" },
        @{ id = "DELETED_EDITED_RPF"; category = "Generic File Tampering"; title = "Deleted/Edited RPF"; message = "RPF file {file} deleted/edited" },
        @{ id = "SUSPICIOUS_CRASHED_FILE"; category = "Generic File Tampering"; title = "Suspicious Crashed File"; message = "Crashed file: {file}" },
        @{ id = "USER_VISITED_WEBSITE"; category = "Website & Download Activity"; title = "User Visited Website"; message = "Website visited: {url}" },
        @{ id = "FILE_DOWNLOADED"; category = "Website & Download Activity"; title = "File Downloaded"; message = "File {file} downloaded" }
    )
    "detection" = @(
        @{ id = "TEST_SIGNING_ENABLED"; category = "Scan Environment"; title = "Test Signing Is Enabled"; message = "Test signing is enabled – halting scan!"; halts_scan = $true },
        @{ id = "USN_JOURNAL_MODIFIED_CLEARED"; category = "USN Journal Tampering"; title = "USN Journal Modified/Cleared"; message = "USN journal cleared" },
        @{ id = "USN_JOURNAL_MODIFIED_APPLICATION"; category = "USN Journal Tampering"; title = "USN Journal Modified (Application-level)"; message = "Application modified USN journal" },
        @{ id = "USN_JOURNAL_BYPASS_FOLDER_FOUND"; category = "USN Journal Tampering"; title = "USN Journal Bypass Folder Found"; message = "Bypass folder found in USN journal" },
        @{ id = "CHEAT_BYPASS_FILE_TRACE_USN"; category = "USN Journal Tampering"; title = "Cheat/Bypass File Trace"; message = "Cheat file trace in USN journal: {file}" },
        @{ id = "PREFETCH_FOLDER_NOT_PRESENT"; category = "Prefetch Bypasses"; title = "Prefetch Folder Is Not Present"; message = "Prefetch folder missing" },
        @{ id = "MANUALLY_DELETED_PREFETCH_FILE"; category = "Prefetch Bypasses"; title = "Manually Deleted Prefetch File"; message = "Prefetch file {file} deleted manually" },
        @{ id = "ENABLEPREFETCH_KEY_MISSING"; category = "Prefetch Bypasses"; title = "EnablePrefetcher Key Missing"; message = "EnablePrefetcher registry key missing" },
        @{ id = "ENABLEPREFETCH_NOT_ENABLED"; category = "Prefetch Bypasses"; title = "EnablePrefetcher Not Enabled"; message = "EnablePrefetcher is disabled" },
        @{ id = "ENABLEPREFETCH_MODIFIED_RECREATED"; category = "Prefetch Bypasses"; title = "EnablePrefetcher Modified & Re-Created"; message = "EnablePrefetcher disable‑run‑restore pattern" },
        @{ id = "PREFETCH_FILE_READONLY"; category = "Prefetch Bypasses"; title = "Prefetch File Set To Read Only"; message = "Prefetch file set read‑only" },
        @{ id = "FILEINFO_SYS_DRIVER_MODIFIED"; category = "Prefetch Bypasses"; title = "FileInfo.sys Driver Modified"; message = "FileInfo.sys driver modified" },
        @{ id = "FILEINFO_SYS_DRIVER_DISABLED"; category = "Prefetch Bypasses"; title = "FileInfo.sys Driver Disabled"; message = "FileInfo.sys driver disabled" },
        @{ id = "CLEARED_EVENT_LOG_CRITICAL"; category = "EventLog Exploits"; title = "Cleared Event Log Since Logon (Critical)"; message = "Critical event log cleared post‑logon" },
        @{ id = "EVENTLOG_EXPLOIT_FOUND"; category = "EventLog Exploits"; title = "Eventlog Exploit Found"; message = "EventLog exploit detected" },
        @{ id = "POWERSHELL_EXPLOIT_FOUND"; category = "EventLog Exploits"; title = "Powershell Exploit Found"; message = "ScriptBlockLogging disabled" },
        @{ id = "FILE_HANDLER_HIJACK_BYPASS"; category = "File Handler Bypasses"; title = "File Handler / Extension Hijack Bypass"; message = "Handler hijack: {extension}" },
        @{ id = "TASK_SCHEDULER_BYPASS_FOUND"; category = "Task & Service Tampering"; title = "Task Scheduler Bypass Found"; message = "Task create‑run‑delete pattern" },
        @{ id = "SERVICE_TERMINATED_BYPASS"; category = "Task & Service Tampering"; title = "Service Terminated (Bypass Attempt)"; message = "Service {service} terminated" },
        @{ id = "SUSPENDED_THREAD"; category = "Task & Service Tampering"; title = "Suspended Thread"; message = "Suspended thread in {process}" },
        @{ id = "DLL_HIJACKING_DETECTED"; category = "Memory & Code Injection"; title = "DLL Hijacking Detected"; message = "DLL hijacking: {dll}" },
        @{ id = "MINECRAFT_MEMORY_MALICIOUSLY_MODIFIED"; category = "Memory & Code Injection"; title = "Minecraft Memory Maliciously Modified"; message = "Minecraft memory modified" },
        @{ id = "FIVEM_INJECTOR_PROCESS_TAMPERING"; category = "Memory & Code Injection"; title = "FiveM Injector / Process Tampering"; message = "FiveM process tampered" },
        @{ id = "DMA_FOUND"; category = "Hardware Detection"; title = "DMA Found"; message = "DMA device found" },
        @{ id = "DMA_FOUND_KNOWN_VENDOR"; category = "Hardware Detection"; title = "DMA Found (Known Vendor)"; message = "DMA from known vendor: {vendor}" },
        @{ id = "IOMMU_HARDWARE_BLOCK_DETECTED"; category = "Hardware Detection"; title = "IOMMU Hardware Block Detected"; message = "IOMMU hardware block found" },
        @{ id = "HDMI_FUSER_INVALID_EDID_SIZE"; category = "Hardware Detection"; title = "HDMI Fuser: Invalid EDID Size"; message = "Invalid EDID size" },
        @{ id = "HDMI_FUSER_INVALID_EDID_CHECKSUM"; category = "Hardware Detection"; title = "HDMI Fuser: Invalid EDID Checksum"; message = "Invalid EDID checksum" },
        @{ id = "HDMI_FUSER_UNUSUALLY_LOW_RESOLUTION"; category = "Hardware Detection"; title = "HDMI Fuser: Unusually Low Resolution"; message = "Unusually low resolution" },
        @{ id = "NVIDIA_DRIVER_PATCHED"; category = "Hardware Detection"; title = "NVIDIA Driver Patched"; message = "NVIDIA driver patched" },
        @{ id = "NVIDIA_STREAMPROOF_BYPASS_TAMPERED"; category = "Hardware Detection"; title = "NVIDIA Streamproof Bypass (Tampered)"; message = "Streamproof driver tampered" },
        @{ id = "EFI_BYPASS_SECURE_BOOT_MISMATCH"; category = "Hardware Detection"; title = "EFI Bypass: Secure Boot Mismatch"; message = "Registry vs firmware mismatch" },
        @{ id = "EFI_BYPASS_FAKE_POLICYPUBLISHER"; category = "Hardware Detection"; title = "EFI Bypass: Fake PolicyPublisher GUID"; message = "Fake PolicyPublisher GUID found" },
        @{ id = "CHEAT_SIGNED_FILE_EXECUTED"; category = "Cheat Execution Evidence"; title = "Cheat Signed File Executed"; message = "Signed cheat file executed: {file}" },
        @{ id = "FAKE_SIGNED_FILE_EXECUTED"; category = "Cheat Execution Evidence"; title = "Fake Signed File Executed"; message = "Fake signed file executed: {file}" },
        @{ id = "HIDDEN_CHEAT_DETECTED"; category = "Cheat Execution Evidence"; title = "Hidden Cheat Detected"; message = "Hidden cheat {cheat} detected" },
        @{ id = "AI_CHEAT_DETECTED"; category = "Cheat Execution Evidence"; title = "AI Cheat Detected"; message = "AI cheat {cheat} detected" },
        @{ id = "CHEAT_RAN_SINCE_LOGON"; category = "Cheat Execution Evidence"; title = "Cheat Ran Since Logon"; message = "Cheat {cheat} executed post‑logon" },
        @{ id = "MALICIOUS_MOUSE_SCRIPT_FOUND"; category = "Cheat Execution Evidence"; title = "Malicious Mouse Script Found"; message = "Lua mouse script: {script}" },
        @{ id = "POTENTIAL_MALICIOUS_JVM_ARG"; category = "Cheat Execution Evidence"; title = "Potential Malicious JVM Argument Found"; message = "JVM arg: {arg}" },
        @{ id = "CHEAT_FOUND_IN_LSASS"; category = "Cheat Discovery in Memory"; title = "Cheat Found In Lsass.exe"; message = "Cheat string in LSASS" },
        @{ id = "CHEAT_FOUND_IN_PCASVC"; category = "Cheat Discovery in Memory"; title = "Cheat Found In PcaSvc"; message = "Cheat string in PcaSvc" },
        @{ id = "CHEAT_FOUND_IN_EXPLORER"; category = "Cheat Discovery in Memory"; title = "Cheat Found In Explorer.exe"; message = "Cheat string in Explorer" },
        @{ id = "CHEAT_FOUND_IN_ROBLOX"; category = "Cheat Discovery in Memory"; title = "Cheat Found In RobloxPlayerBeta.exe"; message = "Cheat string in Roblox" },
        @{ id = "CHEAT_FOUND_IN_WINDOWS_SERVICE"; category = "Cheat Discovery in Memory"; title = "Cheat Found In Windows Service Memory"; message = "Cheat string in {service}" },
        @{ id = "CUSTOM_STRING_FOUND_DETECTION"; category = "Cheat Discovery in Memory"; title = "Custom String Found (Detection)"; message = "String '{string}' found (high confidence)" },
        @{ id = "CHEAT_HASH_FOUND_ON_PC"; category = "Cheat Discovery On Disk"; title = "Cheat Hash Found On PC"; message = "Cheat hash {hash} found in Amcache" },
        @{ id = "CHEAT_HASH_NOT_FOUND_ON_PC"; category = "Cheat Discovery On Disk"; title = "Cheat Hash Not Found On PC"; message = "Cheat hash {hash} in Amcache (file deleted)" },
        @{ id = "CUSTOM_AMCACHE_HASH_DETECTION"; category = "Cheat Discovery On Disk"; title = "Custom Amcache Hash (Detection)"; message = "Amcache hash {hash} matched cheat" },
        @{ id = "NAMED_CHEAT_BYPASS_MATCH_YARA"; category = "Cheat Discovery On Disk"; title = "Named Cheat/Bypass Match (YARA)"; message = "YARA rule {rule} matched {file}" },
        @{ id = "DISCORD_ASAR_VULNERABILITY_BYPASS"; category = "Misc Bypasses"; title = "Discord ASAR Vulnerability Bypass"; message = "Discord ASAR bypass detected" },
        @{ id = "GENERIC_CHEAT_FILE_DELETED_USN"; category = "Misc Bypasses"; title = "Generic Cheat File Deleted"; message = "Cheat file {file} deleted (USN trace)" }
    )
}

# ---- Helper functions ----
$script:Flags = @()

function Raise-Flag {
    param($id, [hashtable]$evidence = @{})
    $entry = $null
    # Search in all catalogues
    $script:FlagCatalogue.Keys | ForEach-Object {
        $cat = $script:FlagCatalogue[$_]
        $found = $cat | Where-Object { $_.id -eq $id }
        if ($found) { $entry = $found; break }
    }
    if (-not $entry) {
        Write-Warning "Flag ID '$id' not found in catalogue."
        return
    }
    # Format message with evidence
    $msg = $entry.message
    foreach ($k in $evidence.Keys) {
        $msg = $msg -replace "\{$k\}", $evidence[$k]
    }
    $flag = @{
        id = $id
        tier = $null  # we'll fill from catalogue
        category = $entry.category
        title = $entry.title
        message = $msg
        evidence = $evidence
        timestamp = (Get-Date).ToString("o")
    }
    # Determine tier from catalogue key
    foreach ($tier in $script:FlagCatalogue.Keys) {
        if ($script:FlagCatalogue[$tier] | Where-Object { $_.id -eq $id }) {
            $flag.tier = $tier
            break
        }
    }
    # Check if halts scan
    if ($entry.halts_scan) {
        Write-Host "HALT: Test Signing Enabled - stopping scan." -ForegroundColor Red
        $script:Flags += $flag
        # Output partial report
        Output-Report
        exit
    }
    $script:Flags += $flag
}

function Output-Report {
    $report = @{
        scan_time = (Get-Date).ToString("o")
        total_flags = $script:Flags.Count
        flags = $script:Flags
    }
    # Save JSON
    $json = $report | ConvertTo-Json -Depth 10
    $jsonFile = Join-Path $OutputDir "MeowScanner_report.json"
    $json | Out-File -FilePath $jsonFile -Encoding utf8
    Write-Host "JSON report saved to $jsonFile" -ForegroundColor Green

    # Human-readable summary
    $summary = @"
============================================
   MEOW SCANNER - FORENSIC REPORT
   Scan Time: $(Get-Date)
============================================

"@
    $grouped = $script:Flags | Group-Object tier
    foreach ($tier in @("detection", "warning", "info")) {
        $items = $grouped | Where-Object { $_.Name -eq $tier }
        if ($items) {
            $summary += "`n--- $($tier.ToUpper()) ($($items.Count)) ---`n"
            foreach ($f in $items.Group) {
                $summary += "[$($f.id)] $($f.title)`n  $($f.message)`n"
            }
        }
    }
    $txtFile = Join-Path $OutputDir "MeowScanner_report.txt"
    $summary | Out-File -FilePath $txtFile -Encoding utf8
    Write-Host "Human-readable report saved to $txtFile" -ForegroundColor Green

    # Also display to console
    Write-Host $summary
}

# ---- Scan modules ----
function Test-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Scan-Environment {
    # Test Signing (Detection)
    try {
        $ts = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue).EnableLUA
        # Actually test signing is in BCDEDIT
        $bcd = bcdedit /enum | Select-String "testsigning"
        if ($bcd -match "Yes") {
            Raise-Flag -id "TEST_SIGNING_ENABLED"
        }
    } catch {}
}

function Scan-FileSystem {
    param($minecraftDir)
    if (-not (Test-Path $minecraftDir)) {
        Write-Warning "Minecraft directory not found: $minecraftDir"
        return
    }
    $modsDir = Join-Path $minecraftDir "mods"
    if (Test-Path $modsDir) {
        $jarFiles = Get-ChildItem -Path $modsDir -Filter *.jar -ErrorAction SilentlyContinue
        foreach ($jar in $jarFiles) {
            $name = $jar.BaseName.ToLower()
            # Check client name list (from spec)
            $clientNames = @("vape","meteor","liquidbounce","wurst","sigma","salhack","novoware","gamesense","osiris","cosmos","sorus","azura","doomsday","argon","krypton","prestige","delta","elysian","onyx","lumina","momentum","ravenb++","uzi","skidbounce","skidcraft","backdoored","leuxbackdoor","salhackskid","grassware","allahware","bbcware","arsenic","atrium","bleachhack","caizm","coffee","cranberry","evangelion","fdp","fog","forgehax","huzuni","hydrogen","ikea","jex","kamiblue","konas","kura","lambda","lavahack","mercury","mint","mirai","nclient","neptunium","ozark","raion","rebirth","rift","selene","seppuku","silence","spark","swift","tensor","tokyo","trollhack","vertex","vrpos","xulu","zeon","zerotwo","zodiac","impact","aristois","kami","kamiblue","phobos","rusherhack","future","remix","yasha","zeroday")
            foreach ($cn in $clientNames) {
                if ($name -match $cn -or $name -match ($cn -replace "client","")) {
                    Raise-Flag -id "POTENTIAL_JAR_CLIENT_FOUND" -evidence @{client=$cn; file=$jar.Name}
                    break
                }
            }
            # Check module names (combat, crystal, totem, movement, utility, esp, evasion)
            $modules = @("killaura","crystalaura","maceaura","silentmace","aimassist","silentaim","bowaimbot","triggerbot","antiweakness","fakepunch","damagetick","onlycrit","statichitboxes","shielddisabler","antiinvis","wtap","critical","autocrit","godmode","reach","autocrystal","crystaloptimizer","cwcrystal","doubleanchor","anchorexploder","autodtap","marlowanchor","antianticw","autototem","totemoffhand","hovertotem","forcetotem","autoretotem","inventorytotemlegit","autodoublehand","fastbridge","bridgeassist","fastswim","fastplace","nobreakdelay","nojumpdelay","elytraswap","elytraglide","jetpack","autosprint","inventorymove","speed","step","autoclicker","autopot","autoeat","autoxp","autoarmor","autotool","automine","cheststealer","shulkerdropper","autosell","cordsnapper","keypearl","autotpa","bedmacro","autorestock","replacemod","scaffold","tower","playeresp","storageesp","entityesp","xray","healthindicators","targethud","netheritefinder","rtpbasefinder","tracers","chams","glow","radar","fakelag","pingspoof","packspoof","straybypass","donutsmpbypass","antiss tool","stringcleaner","selfdestruct","usnjournalcleaner","deleteusnjournal","genericselfdestruct","disabler","bypass","antiban")
            # Extract strings from jar (simple text extraction)
            try {
                $strings = [System.IO.File]::ReadAllText($jar.FullName) -replace "`0","" -split "`n"
                foreach ($module in $modules) {
                    if ($strings -match $module) {
                        Raise-Flag -id "CUSTOM_STRING_FOUND_WARNING" -evidence @{string=$module; file=$jar.Name}
                        break
                    }
                }
                # Check for obfuscation indicators: high entropy class names, base64, hex, reflection
                if ($strings -match '[A-Za-z0-9+/=]{60,}') {
                    Raise-Flag -id "CUSTOM_STRING_FOUND_WARNING" -evidence @{string="Base64 long string"; file=$jar.Name}
                }
                if ($strings -match '\\x[0-9A-Fa-f]{2}\\x[0-9A-Fa-f]{2}') {
                    Raise-Flag -id "CUSTOM_STRING_FOUND_WARNING" -evidence @{string="Hex encoded sequence"; file=$jar.Name}
                }
                if ($strings -match 'Class\.forName\(.*?[Cc]he') {
                    Raise-Flag -id "CUSTOM_STRING_FOUND_WARNING" -evidence @{string="Reflection to cheat class"; file=$jar.Name}
                }
                if ($strings -match 'System\.loadLibrary|System\.load') {
                    Raise-Flag -id "CUSTOM_STRING_FOUND_WARNING" -evidence @{string="Native library loading"; file=$jar.Name}
                }
                if ($strings -match '\b(asm|bytecode|obfuscate)\b') {
                    Raise-Flag -id "CUSTOM_STRING_FOUND_WARNING" -evidence @{string="Bytecode manipulation"; file=$jar.Name}
                }
                if ($strings -match '(AES|RSA|DES|XOR|RC4|Cipher)') {
                    Raise-Flag -id "CUSTOM_STRING_FOUND_WARNING" -evidence @{string="Encryption algorithm"; file=$jar.Name}
                }
            } catch {}
        }
    }
}

function Scan-Registry {
    # Check for client registry keys
    $knownRegKeys = @(
        "HKCU:\Software\Vape",
        "HKCU:\Software\Meteor",
        "HKCU:\Software\LiquidBounce",
        "HKCU:\Software\Wurst",
        "HKCU:\Software\Sigma",
        "HKCU:\Software\Novoware",
        "HKCU:\Software\GameSense",
        "HKCU:\Software\Osiris",
        "HKCU:\Software\Cosmos",
        "HKCU:\Software\Sorus",
        "HKCU:\Software\Azura",
        "HKCU:\Software\Doomsday",
        "HKCU:\Software\Argon",
        "HKCU:\Software\Krypton",
        "HKCU:\Software\Prestige",
        "HKCU:\Software\Delta",
        "HKCU:\Software\Elysian",
        "HKCU:\Software\Onyx",
        "HKCU:\Software\Lumina",
        "HKCU:\Software\Momentum",
        "HKCU:\Software\RavenB++",
        "HKCU:\Software\UZI",
        "HKCU:\Software\SkidBounce",
        "HKCU:\Software\Skidcraft",
        "HKCU:\Software\Backdoored",
        "HKCU:\Software\LeuxBackdoor",
        "HKCU:\Software\SalHackSkid",
        "HKCU:\Software\GrassWare",
        "HKCU:\Software\AllahWare",
        "HKCU:\Software\BBCWare",
        "HKCU:\Software\Arsenic",
        "HKCU:\Software\Atrium",
        "HKCU:\Software\BleachHack",
        "HKCU:\Software\Caizm",
        "HKCU:\Software\Coffee",
        "HKCU:\Software\Cranberry",
        "HKCU:\Software\Evangelion",
        "HKCU:\Software\FDP",
        "HKCU:\Software\Fog",
        "HKCU:\Software\ForgeHax",
        "HKCU:\Software\Huzuni",
        "HKCU:\Software\Hydrogen",
        "HKCU:\Software\Ikea",
        "HKCU:\Software\Jex",
        "HKCU:\Software\Kamiblue",
        "HKCU:\Software\Konas",
        "HKCU:\Software\Kura",
        "HKCU:\Software\Lambda",
        "HKCU:\Software\LavaHack",
        "HKCU:\Software\Mercury",
        "HKCU:\Software\Mint",
        "HKCU:\Software\Mirai",
        "HKCU:\Software\NClient",
        "HKCU:\Software\Neptunium",
        "HKCU:\Software\Ozark",
        "HKCU:\Software\Raion",
        "HKCU:\Software\Rebirth",
        "HKCU:\Software\Rift",
        "HKCU:\Software\Selene",
        "HKCU:\Software\Seppuku",
        "HKCU:\Software\Silence",
        "HKCU:\Software\Spark",
        "HKCU:\Software\Swift",
        "HKCU:\Software\Tensor",
        "HKCU:\Software\Tokyo",
        "HKCU:\Software\Trollhack",
        "HKCU:\Software\Vertex",
        "HKCU:\Software\Vrpos",
        "HKCU:\Software\Xulu",
        "HKCU:\Software\Zeon",
        "HKCU:\Software\ZeroTwo",
        "HKCU:\Software\Zodiac",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" # Check for suspicious autoruns
    )
    foreach ($keyPath in $knownRegKeys) {
        if (Test-Path $keyPath) {
            Raise-Flag -id "FOUND_IN_REGISTRY" -evidence @{value="Key $keyPath exists"}
        }
    }
    # Check for EnablePrefetcher modifications (Detection)
    try {
        $prefetch = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ErrorAction SilentlyContinue).EnablePrefetcher
        if ($prefetch -eq 0) {
            Raise-Flag -id "ENABLEPREFETCH_NOT_ENABLED"
        }
    } catch {}
}

function Scan-DNS {
    $dns = ipconfig /displaydns | Select-String "Record Name" | ForEach-Object { $_ -replace ".*Record Name\. . . . . : ", "" } | Where-Object { $_ -ne "" }
    $cheatDomains = @(
        "vape.gg", "vapeclient.com", "meteorclient.com", "liquidbounce.net",
        "wurstclient.net", "sigmaclient.com", "novoware.cc", "gamesense.pw",
        "osirisclient.com", "cosmosclient.com", "sorusclient.net", "azuraclient.com",
        "deltaclient.net", "elysianclient.org", "onyxclient.com", "luminaclient.net",
        "ravenbplusplus.net", "uziclient.com", "skidbounce.net", "bleachhack.org",
        "forgehax.com", "huzuni.org", "kamiblue.org", "konasclient.com",
        "kuraclient.net", "lambdaclient.com", "mercuryclient.org", "miraiclient.net",
        "ozarkclient.com", "raionclient.net", "seppukuclient.com", "vertexclient.net"
    )
    foreach ($domain in $cheatDomains) {
        if ($dns -match $domain) {
            Raise-Flag -id "FOUND_IN_DNSCACHE" -evidence @{domain=$domain}
        }
    }
}

function Scan-Processes {
    $procs = Get-Process -ErrorAction SilentlyContinue
    $cheatClientNames = @("vape", "meteor", "liquidbounce", "wurst", "sigma", "salhack", "novoware", "gamesense", "osiris", "cosmos", "sorus", "azura", "doomsday", "argon", "krypton", "prestige", "198macros", "delta", "elysian", "onyx", "lumina", "momentum", "ravenb++", "uzi", "skidbounce", "skidcraft", "backdoored", "leuxbackdoor", "salhackskid", "grassware", "allahware", "bbcware", "arsenic", "atrium", "bleachhack", "caizm", "coffee", "cranberry", "evangelion", "fdp", "fog", "forgehax", "huzuni", "hydrogen", "ikea", "jex", "kamiblue", "konas", "kura", "lambda", "lavahack", "mercury", "mint", "mirai", "nclient", "neptunium", "ozark", "raion", "rebirth", "rift", "selene", "seppuku", "silence", "spark", "swift", "tensor", "tokyo", "trollhack", "vertex", "vrpos", "xulu", "zeon", "zerotwo", "zodiac", "impact", "aristois", "kami", "phobos", "rusherhack", "future", "remix", "yasha", "zeroday")
    foreach ($p in $procs) {
        $name = $p.ProcessName.ToLower()
        foreach ($cn in $cheatClientNames) {
            if ($name -match $cn) {
                Raise-Flag -id "CHEAT_FOUND_IN_WINDOWS_SERVICE" -evidence @{service=$cn; process=$p.ProcessName}
                break
            }
        }
    }
    # Check for javaw.exe and JVM arguments (simulate command line reading)
    $javaProcs = $procs | Where-Object { $_.ProcessName -eq "javaw" -or $_.ProcessName -eq "java" }
    foreach ($jp in $javaProcs) {
        try {
            $cmdLine = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($jp.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmdLine) {
                if ($cmdLine -match "-Dclient\.brand=(Wurst|Impact|Meteor|Sigma|LiquidBounce)") {
                    Raise-Flag -id "POTENTIAL_MALICIOUS_JVM_ARG" -evidence @{arg=$Matches[0]}
                }
                if ($cmdLine -match "-D(xray|fly|speed|killaura|reach|scaffold)") {
                    Raise-Flag -id "POTENTIAL_MALICIOUS_JVM_ARG" -evidence @{arg=$Matches[0]}
                }
                # Check for security manager tampering
                if ($cmdLine -match "-Djava\.security\.manager=" -or $cmdLine -match "-Xbootclasspath") {
                    Raise-Flag -id "POTENTIAL_MALICIOUS_JVM_ARG" -evidence @{arg="Security manager tamper"}
                }
            }
        } catch {}
    }
}

function Scan-Prefetch {
    $prefetchDir = "$env:windir\Prefetch"
    if (Test-Path $prefetchDir) {
        $files = Get-ChildItem $prefetchDir -ErrorAction SilentlyContinue
        # Check if folder is empty or missing
        if ($files.Count -eq 0) {
            Raise-Flag -id "PREFETCH_FOLDER_NOT_PRESENT"
        }
        # Check for manually deleted prefetch (look for very few files)
        if ($files.Count -lt 5) {
            Raise-Flag -id "MANUALLY_DELETED_PREFETCH_FILE" -evidence @{file="<multiple missing>"}
        }
    } else {
        Raise-Flag -id "PREFETCH_FOLDER_NOT_PRESENT"
    }
}

function Scan-BAM {
    # BAM keys under HKLM\SYSTEM\CurrentControlSet\Services\bam\UserSettings
    try {
        $bamPath = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings"
        if (Test-Path $bamPath) {
            $items = Get-ChildItem $bamPath -ErrorAction SilentlyContinue
            if ($items.Count -eq 0) {
                Raise-Flag -id "BAM_HAS_BEEN_CLEANED"
            }
        } else {
            Raise-Flag -id "DELETED_BAM_KEY"
        }
    } catch {}
}

function Scan-Amcache {
    # Simple check for Amcache hive presence
    $amcachePath = "$env:SystemRoot\AppCompat\Programs\Amcache.hve"
    if (Test-Path $amcachePath) {
        # Could parse with reg.exe, but for simplicity we just note presence
    } else {
        Raise-Flag -id "AMCACHE_CLEANED"
    }
}

function Scan-EventLog {
    # Check for cleared event logs (simplified)
    $logNames = @("Application", "System", "Security", "Windows PowerShell")
    foreach ($log in $logNames) {
        try {
            $events = Get-WinEvent -LogName $log -MaxEvents 1 -ErrorAction SilentlyContinue
            if (-not $events) {
                Raise-Flag -id "CLEARED_EVENT_LOG_SINCE_LOGON" -evidence @{log=$log}
            }
        } catch {}
    }
}

# ---- Main ----
if (-not (Test-Admin)) {
    Write-Warning "This script requires Administrator privileges to collect full forensic data. Please run as Administrator."
    # Continue anyway, but warn
}

Write-Host "=== MeowScanner - Starting forensic scan ===" -ForegroundColor Cyan

# Scan order
Scan-Environment
# If test signing halts, the script exits inside Raise-Flag

Scan-FileSystem -minecraftDir $MinecraftDir
Scan-Registry
Scan-DNS
Scan-Processes
Scan-Prefetch
Scan-BAM
Scan-Amcache
Scan-EventLog

# Additional scans can be added as needed

Output-Report

Write-Host "=== Scan complete ===" -ForegroundColor Green
