# ============================================================
#  MAGICIAN'S REVEAL  v3.2
#  Professional Minecraft Forensic Scanner
#  Enhanced • Strong detection • Clean output
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

# ---------- Banner ----------
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MAGICIAN'S REVEAL - v3.2" -ForegroundColor Cyan
Write-Host "  Professional Minecraft Forensic Scanner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ---------- 1. Minecraft Process Check (required) ----------
Write-Host "[*] Checking Minecraft process..." -ForegroundColor Cyan

$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) {
    $mcProcess = Get-Process java -ErrorAction SilentlyContinue
}

if (-not $mcProcess) {
    Write-Host ""
    Write-Host "  [!]  MINECRAFT IS NOT RUNNING" -ForegroundColor Red
    Write-Host "  This screenshot / session is INVALID." -ForegroundColor Red
    Write-Host "  Please start Minecraft and run the scanner again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$proc      = $mcProcess | Select-Object -First 1
$startTime = $proc.StartTime
$uptime    = (Get-Date) - $startTime

Write-Host "  [+]  Minecraft is running" -ForegroundColor Green
Write-Host "      Process : $($proc.Name)" -ForegroundColor Gray
Write-Host "      PID     : $($proc.Id)" -ForegroundColor Gray
Write-Host "      Started : $startTime" -ForegroundColor Gray
Write-Host "      Uptime  : $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor Gray
Write-Host ""

# ---------- 2. Mods folder ----------
Write-Host "Enter path to the mods folder: " -NoNewline
Write-Host "(press Enter for default)" -ForegroundColor DarkGray
$modsPath = Read-Host "PATH"

if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    Write-Host "[*] Using default: $modsPath" -ForegroundColor White
}

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "[-] Invalid path: $modsPath" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "[*] Mods folder: $modsPath" -ForegroundColor Green
Write-Host ""

# ---------- 3. High-signal cheat indicators only ----------
$cheatStrings = @(
    # Combat / macros
    "AutoCrystal","autocrystal","AutoHitCrystal","AutoAnchor","DoubleAnchor",
    "SafeAnchor","AirAnchor","AutoTotem","InventoryTotem","HoverTotem",
    "LegitTotem","AutoPot","AutoPotRefill","AutoArmor","ShieldBreaker",
    "ShieldDisabler","AutoDoubleHand","AutoMace","MaceSwap","StunSlam",
    "AxeSpam","TriggerBot","AimAssist","SilentAim","SilentRotations",
    "FakeLag","PingSpoof","FakeInv","WTap","AutoWeb","WebMacro",
    "KeyPearl","LootYeeter","AutoFirework","ElytraSwap","FastPlace",
    "FastXP","FastExp","NoJumpDelay","PackSpoof","Antiknockback",
    "AuthBypass","obfuscatedAuth","LicenseCheckMixin","BaseFinder",
    "SelfDestruct","HideClient","SessionStealer","TokenLogger",
    "TokenGrabber","DiscordToken","RemoteAccess","ReverseShell",
    "C2Server","Backdoor","KeyLogger","StashFinder","TrailFinder",
    "KillAura","ClickAura","CrystalAura","AnchorAura","BedAura",
    "ReachHack","AntiKB","NoKnockback","PlayerESP","XRayHack",
    "ScaffoldWalk","AutoClicker","BowAim","Criticals",

    # Known client packages / identifiers
    "dev.krypton","skid.krypton","dev.virel","orchard",
    "org.chainlibs.module.impl.modules",
    "meteordevelopment","meteorclient","liquidbounce","fdp-client",
    "net.ccbluex","doomsdayclient","novaclient","api.novaclient.lol",
    "vape.gg","vapeclient","VapeLite","intent.store","IntentClient",
    "rise.today","riseclient.com","aristois","impactclient","azura",
    "pandaware","skilled","moonClient","astolfo","futureClient",
    "konas","rusherhack","inertia","exhibition","catlean",
    "CatleanClient","ArgonClient","Asteria","AsteriaClient",
    "PrestigeClient","prestigeclient.vip","gypsy","GypsyClient",
    "XenonClient","GrimClient","dqrkis.xyz","Dqrkis Client",
    "WalksyOptimizer","WalksyCrystalOptimizerMod","WalskyOptimizer",
    "LWFH Crystal","phantom-refmap.json","xyz.greaj",
    "imgui.gl3","imgui.glfw","jnativehook","JNativeHook",
    "GlobalScreen","NativeKeyListener"
)

$suspiciousPatterns = @(
    "AimAssist","AnchorTweaks","AutoAnchor","AutoCrystal","AutoDoubleHand",
    "AutoHitCrystal","AutoPot","AutoTotem","InventoryTotem","LegitTotem",
    "PingSpoof","SelfDestruct","ShieldBreaker","TriggerBot","AxeSpam",
    "WebMacro","FastPlace","WalksyOptimizer","WalskyOptimizer",
    "WalksyCrystalOptimizerMod","ShieldDisabler","SilentAim","FakeLag",
    "dev.virel","orchard","BlockESP","dev.krypton","skid.krypton",
    "AntiMissClick","LagReach","PopSwitch","SprintReset","ChestSteal",
    "AntiBot","ElytraSwap","FastXP","FastExp","Refill","AirAnchor",
    "jnativehook","FakeInv","HoverTotem","AutoClicker","AutoFirework",
    "PackSpoof","Antiknockback","catlean","AuthBypass","Asteria",
    "Prestige","MaceSwap","Macro198","StunSlam","SafeAnchor",
    "DoubleAnchor","AutoTPA","BaseFinder","Xenon","gypsy",
    "AutoPotRefill","KeyPearl","AutoNethPot","AutoDtap","AutoWeb",
    "AnchorAction","imgui.gl3","imgui.glfw","BowAim","Criticals",
    "Fakenick","FakeItem","invsee","ItemExploit","Hellion",
    "LicenseCheckMixin","ClientPlayerInteractionManagerAccessor",
    "ClientPlayerEntityMixim","dev.gambleclient","obfuscatedAuth",
    "phantom-refmap.json","xyz.greaj"
)

# ---------- Helper functions ----------
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Invoke-ModScan {
    param([string]$FilePath)

    $found = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)

        # Collect all entries (including nested JARs)
        $allEntries = [System.Collections.Generic.List[object]]::new()
        foreach ($e in $archive.Entries) { $allEntries.Add($e) }

        foreach ($nj in ($archive.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })) {
            try {
                $ms = New-Object System.IO.MemoryStream
                $nj.Open().CopyTo($ms)
                $ms.Position = 0
                $inner = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                foreach ($ie in $inner.Entries) { $allEntries.Add($ie) }
                $inner.Dispose()
            } catch {}
        }

        # Check entry names
        foreach ($entry in $allEntries) {
            foreach ($p in $suspiciousPatterns) {
                if ($entry.FullName -match [regex]::Escape($p)) {
                    [void]$found.Add($p)
                }
            }
        }

        # Deep scan content
        foreach ($entry in $allEntries) {
            if ($entry.FullName -match '\.(class|json)$' -or $entry.FullName -match 'MANIFEST\.MF') {
                try {
                    $ms = New-Object System.IO.MemoryStream
                    $entry.Open().CopyTo($ms)
                    $bytes = $ms.ToArray()
                    $ms.Dispose()

                    $text = [System.Text.Encoding]::UTF8.GetString($bytes) +
                            [System.Text.Encoding]::ASCII.GetString($bytes)

                    foreach ($s in $cheatStrings) {
                        if ($text.Contains($s)) {
                            [void]$found.Add($s)
                        }
                    }
                } catch {}
            }
        }
        $archive.Dispose()
    } catch {}

    return $found
}

function Get-ObfuscationFlags {
    param([string]$FilePath)

    $flags = [System.Collections.Generic.List[string]]::new()

    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $totalClass    = 0
        $numeric       = 0
        $unicode       = 0
        $singleLetter  = 0
        $japanese      = 0
        $fullwidth     = 0

        foreach ($entry in $archive.Entries) {
            if ($entry.FullName -match '\.class$') {
                $totalClass++
                $className = [System.IO.Path]::GetFileNameWithoutExtension(($entry.FullName -split '/')[-1])

                if ($className -match '^\d+$')                          { $numeric++ }
                if ($className -match '[^\x00-\x7F]')                   { $unicode++ }
                if ($className -match '^[a-zA-Z]$')                     { $singleLetter++ }
                if ($className -match '[\u3040-\u309F\u30A0-\u30FF]')  { $japanese++ }
                if ($className -match '[\uFF21-\uFF3A\uFF41-\uFF5A]')  { $fullwidth++ }
            }
        }
        $archive.Dispose()

        if ($totalClass -lt 10) { return $flags }

        $pct = { param($n) [math]::Round(($n / $totalClass) * 100) }

        # Stricter thresholds = only real heavy cheat obfuscation
        if ((& $pct $numeric) -ge 30) {
            $flags.Add("Heavy numeric class names ($((& $pct $numeric))%)")
        }
        if ((& $pct $unicode) -ge 20) {
            $flags.Add("Unicode / non-ASCII class names ($((& $pct $unicode))%)")
        }
        if ((& $pct $singleLetter) -ge 25) {
            $flags.Add("Single-letter class names ($((& $pct $singleLetter))%)")
        }
        if ($japanese -gt 0) {
            $flags.Add("Japanese obfuscation detected ($japanese classes)")
        }
        if ($fullwidth -gt 0) {
            $flags.Add("Fullwidth Unicode class names ($fullwidth classes)")
        }
    } catch {}

    return $flags
}

# ---------- Main scan ----------
$jarFiles = Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction SilentlyContinue

if ($jarFiles.Count -eq 0) {
    Write-Host "[!] No JAR files found." -ForegroundColor Yellow
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Host "[*] Found $($jarFiles.Count) JAR files to scan" -ForegroundColor Green
Write-Host ""

$suspiciousMods = @()
$obfuscatedMods = @()
$cleanCount     = 0

$idx = 0
foreach ($jar in $jarFiles) {
    $idx++
    Write-Host "`r  Scanning [$idx/$($jarFiles.Count)] $($jar.Name)..." -NoNewline

    $matches  = Invoke-ModScan -FilePath $jar.FullName
    $obfFlags = Get-ObfuscationFlags -FilePath $jar.FullName

    if ($matches.Count -gt 0) {
        $suspiciousMods += [PSCustomObject]@{
            FileName = $jar.Name
            Matches  = $matches
        }
    }
    elseif ($obfFlags.Count -gt 0) {
        $obfuscatedMods += [PSCustomObject]@{
            FileName = $jar.Name
            Flags    = $obfFlags
        }
    }
    else {
        $cleanCount++
    }
}
Write-Host "`r$(' ' * 90)`r" -NoNewline

# ---------- Report ----------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SCAN RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  MINECRAFT PROCESS" -ForegroundColor White
Write-Host "  --------------------------------------" -ForegroundColor DarkGray
Write-Host "  Status   : RUNNING" -ForegroundColor Green
Write-Host "  Process  : $($proc.Name)" -ForegroundColor Gray
Write-Host "  PID      : $($proc.Id)" -ForegroundColor Gray
Write-Host "  Started  : $startTime" -ForegroundColor Gray
Write-Host "  Uptime   : $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor Gray
Write-Host ""

if ($suspiciousMods.Count -eq 0 -and $obfuscatedMods.Count -eq 0) {
    Write-Host "  [+]  No cheat indicators found." -ForegroundColor Green
    Write-Host "  All $cleanCount mods appear clean." -ForegroundColor Green
}
else {
    if ($suspiciousMods.Count -gt 0) {
        Write-Host "  [!]  SUSPICIOUS MODS  ($($suspiciousMods.Count))" -ForegroundColor Red
        Write-Host "  --------------------------------------" -ForegroundColor DarkRed
        Write-Host ""

        foreach ($mod in $suspiciousMods) {
            Write-Host "  +-- $($mod.FileName)" -ForegroundColor Yellow
            Write-Host "  |" -ForegroundColor DarkRed
            Write-Host "  |  Detected!" -ForegroundColor Red
            foreach ($m in ($mod.Matches | Sort-Object)) {
                Write-Host "  |    • $m" -ForegroundColor Red
            }
            Write-Host "  +------------------------------------" -ForegroundColor DarkRed
            Write-Host ""
        }
    }

    if ($obfuscatedMods.Count -gt 0) {
        Write-Host "  [!]  HEAVILY OBFUSCATED (no known cheat strings)" -ForegroundColor DarkYellow
        Write-Host "  --------------------------------------" -ForegroundColor DarkYellow
        Write-Host ""

        foreach ($mod in $obfuscatedMods) {
            Write-Host "  +-- $($mod.FileName)" -ForegroundColor Yellow
            foreach ($f in $mod.Flags) {
                Write-Host "  |    > $f" -ForegroundColor Yellow
            }
            Write-Host "  +------------------------------------" -ForegroundColor DarkYellow
            Write-Host ""
        }
    }
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Total JARs scanned     : $($jarFiles.Count)" -ForegroundColor White
Write-Host "  Clean                  : $cleanCount" -ForegroundColor Green
Write-Host "  Suspicious (strings)   : $($suspiciousMods.Count)" -ForegroundColor Red
Write-Host "  Heavily obfuscated     : $($obfuscatedMods.Count)" -ForegroundColor Yellow
Write-Host "  Minecraft running      : Yes (PID $($proc.Id))" -ForegroundColor Green
Write-Host ""
Write-Host "  Scan complete – Magician's Reveal v3.2" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
