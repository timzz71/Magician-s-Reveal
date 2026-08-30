# Magician's Reveal - Professional Minecraft Forensic Scanner
# Version: 1.0.0
# Author: Timzz71
# Description: Forensic scanner for consented screenshare investigations

param(
    [string]$OutputDir = $PWD.Path,
    [string]$MinecraftDir = "$env:APPDATA\.minecraft"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🔍 MAGICIAN'S REVEAL - v1.0.0" -ForegroundColor Cyan
Write-Host "  Professional Minecraft Forensic Scanner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Warning "This script requires Administrator privileges for full forensic data collection."
    Write-Host "Continuing with limited permissions..." -ForegroundColor Yellow
}

# Initialize findings
$script:Findings = @()

function Add-Finding {
    param(
        [string]$Id,
        [string]$Tier,
        [string]$Category,
        [string]$Title,
        [string]$Message,
        [hashtable]$Evidence = @{}
    )
    $finding = @{
        id = $Id
        tier = $Tier
        category = $Category
        title = $Title
        message = $Message
        evidence = $Evidence
        timestamp = (Get-Date).ToString("o")
    }
    $script:Findings += $finding
    Write-Host "[$Tier] $Title" -ForegroundColor $(if ($Tier -eq "Detection") { "Red" } elseif ($Tier -eq "Warning") { "Yellow" } else { "White" })
}

# ============ SUSPICIOUS PATTERNS (CLEAN VERSION) ============
$suspiciousPatterns = @(
    "AimAssist", "AnchorTweaks", "AutoAnchor", "AutoCrystal", "AutoDoubleHand",
    "AutoHitCrystal", "AutoPot", "AutoTotem", "AutoArmor", "InventoryTotem",
    "LegitTotem", "PingSpoof", "SelfDestruct", "ShieldBreaker", "TriggerBot",
    "AxeSpam", "WebMacro", "FastPlace", "WalksyOptimizer", "WalskyOptimizer",
    "WalksyCrystalOptimizerMod", "Donut", "Replace Mod", "ShieldDisabler",
    "SilentAim", "Totem Hit", "Wtap", "FakeLag", "dev.virel", "orchard",
    "BlockESP", "dev.krypton", "skid.krypton", "AntiMissClick", "LagReach",
    "PopSwitch", "SprintReset", "ChestSteal", "AntiBot", "ElytraSwap",
    "FastXP", "FastExp", "Refill", "AirAnchor", "jnativehook", "FakeInv",
    "HoverTotem", "AutoClicker", "AutoFirework", "PackSpoof", "Antiknockback",
    "catlean", "AuthBypass", "Asteria", "Prestige", "AutoEat", "AutoMine",
    "MaceSwap", "Macro198", "StunSlam", "SafeAnchor", "DoubleAnchor",
    "AutoTPA", "BaseFinder", "Xenon", "gypsy", "AutoPotRefill", "KeyPearl",
    "AutoNethPot", "AutoDtap", "AutoWeb", "AnchorAction",
    "org.chainlibs.module.impl.modules.Crystal.Y",
    "org.chainlibs.module.impl.modules.Crystal.bF",
    "org.chainlibs.module.impl.modules.Crystal.bM",
    "org.chainlibs.module.impl.modules.Crystal.bY",
    "org.chainlibs.module.impl.modules.Crystal.bq",
    "org.chainlibs.module.impl.modules.Crystal.cv",
    "org.chainlibs.module.impl.modules.Crystal.o",
    "org.chainlibs.module.impl.modules.Blatant.I",
    "org.chainlibs.module.impl.modules.Blatant.bR",
    "org.chainlibs.module.impl.modules.Blatant.bx",
    "org.chainlibs.module.impl.modules.Blatant.cj",
    "org.chainlibs.module.impl.modules.Blatant.dk",
    "imgui.gl3", "imgui.glfw", "BowAim", "Criticals", "Fakenick",
    "FakeItem", "invsee", "ItemExploit", "Hellion", "LicenseCheckMixin",
    "ClientPlayerInteractionManagerAccessor", "ClientPlayerEntityMixim",
    "dev.gambleclient", "obfuscatedAuth", "phantom-refmap.json", "xyz.greaj"
)

$cheatStrings = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal",
    "dontPlaceCrystal", "dontBreakCrystal", "AutoHitCrystal",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor",
    "HasAnchor", "anchortweaks", "anchor macro", "safe anchor",
    "SafeAnchor", "AirAnchor", "AutoTotem", "autototem",
    "auto totem", "InventoryTotem", "inventorytotem", "HoverTotem",
    "hover totem", "legittotem", "AutoPot", "autopot", "auto pot",
    "AutoArmor", "autoarmor", "auto armor", "AutoPotRefill",
    "ShieldDisabler", "ShieldBreaker", "AutoDoubleHand",
    "autodoublehand", "auto double hand", "AutoClicker",
    "AutoMace", "MaceSwap", "SpearSwap", "StunSlam",
    "Donut", "JumpReset", "axespam", "axe spam", "AimAssist",
    "aimassist", "aim assist", "triggerbot", "trigger bot",
    "SilentRotations", "FakeInv", "FakeLag", "pingspoof",
    "ping spoof", "fakePunch", "Fake Punch", "mace_swap",
    "quick_strike", "macro_198", "stun_slam", "safe_anchor",
    "double_anchor", "auto_pot_refill", "walksy_optimizer",
    "key_pearl", "aim_assist", "auto_neth_pot", "auto_dtap",
    "trigger_bot", "auto_web", "webmacro", "web macro",
    "AntiWeb", "AutoWeb", "lvstrng", "dqrkis", "selfdestruct",
    "self destruct", "WalksyCrystalOptimizerMod", "WalksyOptimizer",
    "WalskyOptimizer", "autoCrystalPlaceClock", "AutoFirework",
    "ElytraSwap", "FastXP", "FastExp", "NoJumpDelay", "PackSpoof",
    "Antiknockback", "catlean", "AuthBypass", "obfuscatedAuth",
    "LicenseCheckMixin", "BaseFinder", "invsee", "ItemExploit",
    "FreezePlayer", "LWFH Crystal", "KeyPearl", "LootYeeter",
    "FastPlace", "AutoBreach", "placeInterval", "breakInterval",
    "stopOnKill", "activateOnRightClick", "holdCrystal",
    "PlaceInterval", "BreakInterval", "StopOnKill",
    "damagetick", "fakePunch", "ReachHack", "ExtendReach",
    "LongReach", "HitboxExpand", "AntiKB", "NoKnockback",
    "GrimVelocity", "GrimDisabler", "VelocitySpoof", "KBReduce",
    "OffhandTotem", "TotemSwitch", "AutoWeapon", "AutoSword",
    "AutoCity", "Burrow", "SelfTrap", "HoleFiller", "AntiSurround",
    "AntiBurrow", "WTap", "TargetStrafe", "AutoGap", "AutoPearl",
    "FlyHack", "CreativeFlight", "BoatFly", "PacketFly", "AirJump",
    "SpeedHack", "BHop", "BunnyHop", "AntiFall", "NoFallDamage",
    "SafeFall", "StepHack", "FastClimb", "AutoStep", "HighStep",
    "WaterWalk", "LiquidWalk", "LavaWalk", "NoSlow", "NoSlowdown",
    "NoWeb", "NoSoulSand", "WallHack", "ElytraSpeed", "InstantElytra",
    "ScaffoldWalk", "FastBridge", "BuildHelper", "AutoBridge",
    "Nuker", "NukerLegit", "InstantBreak", "GhostHand", "NoSwing",
    "PlaceAssist", "AirPlace", "AutoPlace", "InstantPlace",
    "PlayerESP", "MobESP", "ItemESP", "StorageESP", "ChestESP",
    "Tracers", "NameTagsHack", "XRayHack", "OreFinder", "CaveFinder",
    "OreESP", "NewChunks", "ChunkBorders", "TunnelFinder",
    "TargetHUD", "ReachDisplay", "DoubleClicker", "JitterClick",
    "ButterflyClick", "CPSBoost", "ChestStealer", "InvManager",
    "InvMovebypass", "AutoSprint", "AntiAFK", "AutoRespawn",
    "PopSwitch", "FakeLatency", "FakePing", "SpoofRotation",
    "PositionSpoof", "GameSpeed", "SpeedTimer", "GrimBypass",
    "VulcanBypass", "MatrixBypass", "AACBypass", "VerusDisabler",
    "IntaveBypass", "WatchdogBypass", "PacketMine", "PacketWalk",
    "PacketSneak", "PacketCancel", "PacketDupe", "PacketSpam",
    "SelfDestruct", "HideClient", "SessionStealer", "TokenLogger",
    "TokenGrabber", "DiscordToken", "RemoteAccess", "ReverseShell",
    "C2Server", "Backdoor", "KeyLogger", "StashFinder", "TrailFinder",
    "imgui.binding", "JNativeHook", "GlobalScreen", "NativeKeyListener",
    "client-refmap.json", "cheat-refmap.json", "meteordevelopment",
    "cc/novoline", "com/alan/clients", "club/maxstats", "wtf/moonlight",
    "me/zeroeightsix/kami", "net/ccbluex", "today/opai",
    "net/minecraft/injection", "org/chainlibs/module/impl/modules",
    "xyz/greaj", "com/cheatbreaker", "com/moonsworth",
    "doomsdayclient", "DoomsdayClient", "doomsday.jar",
    "novaclient", "api.novaclient.lol", "WalksyOptimizer",
    "vape.gg", "vapeclient", "VapeClient", "VapeLite",
    "intent.store", "IntentClient", "rise.today", "riseclient.com",
    "meteor-client", "meteorclient", "meteordevelopment.meteorclient",
    "liquidbounce", "fdp-client", "net.ccbluex", "novoware",
    "novoclient", "aristois", "impactclient", "azura",
    "pandaware", "skilled", "moonClient", "astolfo",
    "futureClient", "konas", "rusherhack", "inertia", "exhibition",
    "dev.krypton", "skid.krypton", "VirginClient", "virgin client",
    "catlean", "CatleanClient", "catlean client", "ArgonClient",
    "argon client", "Asteria", "AsteriaClient", "asteria client",
    "Prestige", "PrestigeClient", "prestige client", "prestigeclient.vip",
    "gypsy", "GypsyClient", "gypsy client", "Xenon", "XenonClient",
    "xenon client", "GrimClient", "grim client", "phantom-refmap.json",
    "dqrkis.xyz", "Dqrkis Client"
)

# ============ SCAN FUNCTIONS ============

function Scan-Environment {
    Write-Host "[*] Scanning environment..." -ForegroundColor Green
    try {
        $bcd = bcdedit /enum 2>$null | Select-String "testsigning"
        if ($bcd -match "Yes") {
            Add-Finding -Id "TEST_SIGNING_ENABLED" -Tier "Detection" -Category "Scan Environment" -Title "Test Signing Is Enabled" -Message "Test signing is enabled – halting scan!"
            return $false
        }
    } catch {}
    return $true
}

function Scan-FileSystem {
    param($minecraftDir)
    Write-Host "[*] Scanning file system..." -ForegroundColor Green
    if (-not (Test-Path $minecraftDir)) {
        Write-Warning "Minecraft directory not found: $minecraftDir"
        return
    }
    $modsDir = Join-Path $minecraftDir "mods"
    if (Test-Path $modsDir) {
        $jarFiles = Get-ChildItem -Path $modsDir -Filter *.jar -ErrorAction SilentlyContinue
        foreach ($jar in $jarFiles) {
            $name = $jar.BaseName.ToLower()
            foreach ($pattern in $suspiciousPatterns) {
                if ($name -like "*$pattern*") {
                    Add-Finding -Id "POTENTIAL_JAR_CLIENT_FOUND" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Potential JAR Client Found" -Message "Pattern '$pattern' found in $($jar.Name)" -Evidence @{pattern=$pattern; file=$jar.Name}
                    break
                }
            }
            try {
                $content = [System.IO.File]::ReadAllText($jar.FullName) -replace "`0",""
                foreach ($str in $cheatStrings) {
                    if ($content -like "*$str*") {
                        Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Custom String Found (Warning)" -Message "String '$str' found in $($jar.Name)" -Evidence @{string=$str; file=$jar.Name}
                        break
                    }
                }
                if ($content -match '[A-Za-z0-9+/=]{60,}') {
                    Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Custom String Found (Warning)" -Message "Base64 long string detected in $($jar.Name)" -Evidence @{string="Base64"; file=$jar.Name}
                }
                if ($content -match '\\x[0-9A-Fa-f]{2}\\x[0-9A-Fa-f]{2}') {
                    Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Custom String Found (Warning)" -Message "Hex encoded sequence detected in $($jar.Name)" -Evidence @{string="Hex"; file=$jar.Name}
                }
                if ($content -match 'Class\.forName\(.*?[Cc]he') {
                    Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Custom String Found (Warning)" -Message "Reflection to cheat class detected in $($jar.Name)" -Evidence @{string="Reflection"; file=$jar.Name}
                }
                if ($content -match 'System\.loadLibrary|System\.load') {
                    Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Custom String Found (Warning)" -Message "Native library loading detected in $($jar.Name)" -Evidence @{string="Native"; file=$jar.Name}
                }
            } catch {}
        }
    }
}

function Scan-Registry {
    Write-Host "[*] Scanning registry..." -ForegroundColor Green
    $regKeys = @("Vape", "Meteor", "LiquidBounce", "Wurst", "Sigma", "Novoware", "Prestige", "Doomsday", "Argon", "Krypton", "Delta", "Elysian", "Onyx", "Lumina", "Momentum", "RavenB++", "SkidBounce", "Skidcraft", "Backdoored", "LeuxBackdoor", "SalHackSkid", "GrassWare", "AllahWare", "BBCWare", "Arsenic", "Atrium", "BleachHack", "Caizm", "Coffee", "Cranberry", "Evangelion", "FDP", "Fog", "ForgeHax", "Huzuni", "Hydrogen", "Ikea", "Jex", "Kamiblue", "Konas", "Kura", "Lambda", "LavaHack", "Mercury", "Mint", "Mirai", "NClient", "Neptunium", "Ozark", "Raion", "Rebirth", "Rift", "Selene", "Seppuku", "Silence", "Spark", "Swift", "Tensor", "Tokyo", "Trollhack", "Vertex", "Vrpos", "Xulu", "Zeon", "ZeroTwo", "Zodiac")
    foreach ($key in $regKeys) {
        $keyPath = "HKCU:\Software\$key"
        if (Test-Path $keyPath) {
            Add-Finding -Id "FOUND_IN_REGISTRY" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Found In Registry" -Message "Registry key '$key' exists" -Evidence @{value="Key $keyPath"}
        }
    }
    try {
        $prefetch = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ErrorAction SilentlyContinue).EnablePrefetcher
        if ($prefetch -eq 0) {
            Add-Finding -Id "ENABLEPREFETCH_NOT_ENABLED" -Tier "Detection" -Category "Prefetch Bypasses" -Title "EnablePrefetcher Not Enabled" -Message "EnablePrefetcher is disabled (value: 0)"
        }
    } catch {}
}

function Scan-DNS {
    Write-Host "[*] Scanning DNS cache..." -ForegroundColor Green
    $cheatDomains = @(
        "vape.gg", "vapeclient.com", "meteorclient.com", "liquidbounce.net",
        "wurstclient.net", "sigmaclient.com", "novoware.cc", "gamesense.pw",
        "osirisclient.com", "cosmosclient.com", "sorusclient.net", "azuraclient.com",
        "deltaclient.net", "elysianclient.org", "onyxclient.com", "luminaclient.net",
        "ravenbplusplus.net", "uziclient.com", "skidbounce.net", "bleachhack.org",
        "forgehax.com", "huzuni.org", "kamiblue.org", "konasclient.com",
        "kuraclient.net", "lambdaclient.com", "mercuryclient.org", "miraiclient.net",
        "ozarkclient.com", "raionclient.net", "seppukuclient.com", "vertexclient.net",
        "prestigeclient.vip", "dqrkis.xyz"
    )
    try {
        $dns = ipconfig /displaydns 2>$null | Select-String "Record Name" | ForEach-Object { ($_ -replace ".*Record Name\. . . . . : ", "").Trim() }
        foreach ($domain in $cheatDomains) {
            foreach ($entry in $dns) {
                if ($entry -like "*$domain*") {
                    Add-Finding -Id "FOUND_IN_DNSCACHE" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Found In Dnscache" -Message "Domain '$domain' found in DNS cache" -Evidence @{domain=$domain}
                    break
                }
            }
        }
    } catch {}
}

function Scan-Processes {
    Write-Host "[*] Scanning processes..." -ForegroundColor Green
    $procs = Get-Process -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        $name = $p.ProcessName.ToLower()
        foreach ($str in $cheatStrings) {
            if ($name -like "*$str*") {
                Add-Finding -Id "CHEAT_FOUND_IN_WINDOWS_SERVICE" -Tier "Detection" -Category "Cheat Discovery in Memory" -Title "Cheat Found In Windows Service Memory" -Message "Cheat process '$str' found running" -Evidence @{service=$str; process=$p.ProcessName}
                break
            }
        }
    }
    $javaProcs = $procs | Where-Object { $_.ProcessName -eq "javaw" -or $_.ProcessName -eq "java" }
    foreach ($jp in $javaProcs) {
        try {
            $cmdLine = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($jp.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmdLine) {
                if ($cmdLine -match "-Dclient\.brand=(Wurst|Impact|Meteor|Sigma|LiquidBounce)") {
                    Add-Finding -Id "POTENTIAL_MALICIOUS_JVM_ARG" -Tier "Detection" -Category "Cheat Execution Evidence" -Title "Potential Malicious JVM Argument Found" -Message "JVM arg: $($Matches[0])" -Evidence @{arg=$Matches[0]}
                }
                if ($cmdLine -match "-D(xray|fly|speed|killaura|reach|scaffold)") {
                    Add-Finding -Id "POTENTIAL_MALICIOUS_JVM_ARG" -Tier "Detection" -Category "Cheat Execution Evidence" -Title "Potential Malicious JVM Argument Found" -Message "JVM arg: $($Matches[0])" -Evidence @{arg=$Matches[0]}
                }
                if ($cmdLine -match "-Djava\.security\.manager=" -or $cmdLine -match "-Xbootclasspath") {
                    Add-Finding -Id "POTENTIAL_MALICIOUS_JVM_ARG" -Tier "Detection" -Category "Cheat Execution Evidence" -Title "Potential Malicious JVM Argument Found" -Message "Security manager tampering detected" -Evidence @{arg="Security manager tamper"}
                }
            }
        } catch {}
    }
}

function Scan-Prefetch {
    Write-Host "[*] Scanning prefetch..." -ForegroundColor Green
    $prefetchDir = "$env:windir\Prefetch"
    if (Test-Path $prefetchDir) {
        $files = Get-ChildItem $prefetchDir -ErrorAction SilentlyContinue
        if ($files.Count -eq 0) {
            Add-Finding -Id "PREFETCH_FOLDER_NOT_PRESENT" -Tier "Detection" -Category "Prefetch Bypasses" -Title "Prefetch Folder Is Not Present" -Message "Prefetch folder is empty or missing"
        } elseif ($files.Count -lt 5) {
            Add-Finding -Id "MANUALLY_DELETED_PREFETCH_FILE" -Tier "Detection" -Category "Prefetch Bypasses" -Title "Manually Deleted Prefetch File" -Message "Prefetch folder has unusually few files ($($files.Count))"
        }
    } else {
        Add-Finding -Id "PREFETCH_FOLDER_NOT_PRESENT" -Tier "Detection" -Category "Prefetch Bypasses" -Title "Prefetch Folder Is Not Present" -Message "Prefetch folder not found"
    }
}

function Scan-BAM {
    Write-Host "[*] Scanning BAM..." -ForegroundColor Green
    try {
        $bamPath = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings"
        if (Test-Path $bamPath) {
            $items = Get-ChildItem $bamPath -ErrorAction SilentlyContinue
            if ($items.Count -eq 0) {
                Add-Finding -Id "BAM_HAS_BEEN_CLEANED" -Tier "Warning" -Category "BAM and Install Date" -Title "BAM Has Been Cleaned" -Message "BAM registry key is empty"
            }
        } else {
            Add-Finding -Id "DELETED_BAM_KEY" -Tier "Warning" -Category "BAM and Install Date" -Title "Deleted BAM Key" -Message "BAM registry key is missing"
        }
    } catch {}
}

function Scan-Amcache {
    Write-Host "[*] Scanning Amcache..." -ForegroundColor Green
    $amcachePath = "$env:SystemRoot\AppCompat\Programs\Amcache.hve"
    if (-not (Test-Path $amcachePath)) {
        Add-Finding -Id "AMCACHE_CLEANED" -Tier "Warning" -Category "Generic File Tampering" -Title "Amcache Cleaned" -Message "Amcache hive is missing"
    }
}

function Scan-EventLog {
    Write-Host "[*] Scanning event logs..." -ForegroundColor Green
    $logNames = @("Application", "System", "Security", "Windows PowerShell")
    foreach ($log in $logNames) {
        try {
            $events = Get-WinEvent -LogName $log -MaxEvents 1 -ErrorAction SilentlyContinue
            if (-not $events) {
                Add-Finding -Id "CLEARED_EVENT_LOG_SINCE_LOGON" -Tier "Warning" -Category "EventLog Tampering" -Title "Cleared Event Log Since Logon" -Message "Event log '$log' appears empty" -Evidence @{log=$log}
            }
        } catch {}
    }
}

# ============ MAIN ============
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[*] Starting forensic scan..." -ForegroundColor Green
Write-Host "[*] Target: $MinecraftDir" -ForegroundColor Green
Write-Host "[*] Output: $OutputDir" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$continue = Scan-Environment
if ($continue) {
    Scan-FileSystem -minecraftDir $MinecraftDir
    Scan-Registry
    Scan-DNS
    Scan-Processes
    Scan-Prefetch
    Scan-BAM
    Scan-Amcache
    Scan-EventLog
}

# ============ GENERATE REPORT ============
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[*] Generating report..." -ForegroundColor Green

$detections = $script:Findings | Where-Object { $_.tier -eq "Detection" }
$warnings = $script:Findings | Where-Object { $_.tier -eq "Warning" }
$infos = $script:Findings | Where-Object { $_.tier -eq "Info" }

$report = @"
============================================
   MAGICIAN'S REVEAL - FORENSIC REPORT
   Scan Time: $(Get-Date)
   Findings: $($script:Findings.Count)
============================================

"@

if ($detections) {
    $report += "`n--- DETECTION ($($detections.Count)) ---`n"
    foreach ($f in $detections) {
        $report += "[$($f.id)] $($f.title)`n  $($f.message)`n"
    }
}
if ($warnings) {
    $report += "`n--- WARNING ($($warnings.Count)) ---`n"
    foreach ($f in $warnings) {
        $report += "[$($f.id)] $($f.title)`n  $($f.message)`n"
    }
}
if ($infos) {
    $report += "`n--- INFO ($($infos.Count)) ---`n"
    foreach ($f in $infos) {
        $report += "[$($f.id)] $($f.title)`n  $($f.message)`n"
    }
}
if ($script:Findings.Count -eq 0) {
    $report += "`n✅ No suspicious findings detected.`n"
}

$report += "`n============================================"
$report += "`nReport generated by Magician's Reveal v1.0.0"
$report += "`n============================================"

$txtFile = Join-Path $OutputDir "MagiciansReveal_report.txt"
$report | Out-File -FilePath $txtFile -Encoding utf8
Write-Host "[+] Human-readable report saved to: $txtFile" -ForegroundColor Green

$jsonFile = Join-Path $OutputDir "MagiciansReveal_report.json"
$script:Findings | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding utf8
Write-Host "[+] JSON report saved to: $jsonFile" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SCAN COMPLETE" -ForegroundColor Cyan
Write-Host "  Detections: $($detections.Count)" -ForegroundColor Red
Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor Yellow
Write-Host "  Info: $($infos.Count)" -ForegroundColor White
Write-Host "  Total: $($script:Findings.Count)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[+] Full report saved to: $txtFile" -ForegroundColor Green
