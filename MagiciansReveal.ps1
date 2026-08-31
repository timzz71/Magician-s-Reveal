# ============================================================
#  MAGICIAN'S REVEAL  v3.1
#  Professional Minecraft Forensic Scanner
#  Original implementation – clean detection only
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MAGICIAN'S REVEAL - v3.1" -ForegroundColor Cyan
Write-Host "  Professional Minecraft Forensic Scanner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ---------- 1. HARD REQUIREMENT: Minecraft must be running ----------
Write-Host "[*] Checking Minecraft process..." -ForegroundColor Cyan

$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) { $mcProcess = Get-Process java -ErrorAction SilentlyContinue }

if (-not $mcProcess) {
    Write-Host ""
    Write-Host "  [!]  MINECRAFT IS NOT RUNNING" -ForegroundColor Red
    Write-Host "  This screenshot / session is INVALID." -ForegroundColor Red
    Write-Host "  Start Minecraft and run the scanner again." -ForegroundColor Yellow
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

# ---------- 2. Mods path ----------
Write-Host "Enter path to the mods folder (press Enter for default):" -ForegroundColor Yellow
$modsPath = Read-Host "PATH"

if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
}

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "[-] Invalid path: $modsPath" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "[*] Scanning: $modsPath" -ForegroundColor Green
Write-Host ""

# ---------- 3. High-signal cheat strings only ----------
$cheatStrings = @(
    "AutoCrystal","autocrystal","AutoHitCrystal","AutoAnchor","DoubleAnchor","SafeAnchor","AirAnchor",
    "AutoTotem","InventoryTotem","HoverTotem","LegitTotem","AutoPot","AutoPotRefill","AutoArmor",
    "ShieldBreaker","ShieldDisabler","AutoDoubleHand","AutoMace","MaceSwap","StunSlam","AxeSpam",
    "TriggerBot","AimAssist","SilentAim","SilentRotations","FakeLag","PingSpoof","FakeInv","WTap",
    "AutoWeb","WebMacro","KeyPearl","LootYeeter","AutoFirework","ElytraSwap","FastPlace","FastXP",
    "FastExp","NoJumpDelay","PackSpoof","Antiknockback","AuthBypass","obfuscatedAuth","LicenseCheckMixin",
    "BaseFinder","SelfDestruct","HideClient","SessionStealer","TokenLogger","TokenGrabber","DiscordToken",
    "RemoteAccess","ReverseShell","C2Server","Backdoor","KeyLogger","StashFinder","TrailFinder",
    "dev.krypton","skid.krypton","dev.virel","orchard","org.chainlibs.module.impl.modules",
    "meteordevelopment","meteorclient","liquidbounce","fdp-client","net.ccbluex","doomsdayclient",
    "novaclient","api.novaclient.lol","vape.gg","vapeclient","VapeLite","intent.store","IntentClient",
    "rise.today","riseclient.com","aristois","impactclient","azura","pandaware","skilled","moonClient",
    "astolfo","futureClient","konas","rusherhack","inertia","exhibition","catlean","CatleanClient",
    "ArgonClient","Asteria","AsteriaClient","PrestigeClient","prestigeclient.vip","gypsy","GypsyClient",
    "XenonClient","GrimClient","dqrkis.xyz","Dqrkis Client","WalksyOptimizer","WalksyCrystalOptimizerMod",
    "WalskyOptimizer","LWFH Crystal","phantom-refmap.json","xyz.greaj","imgui.gl3","imgui.glfw",
    "jnativehook","JNativeHook","GlobalScreen","NativeKeyListener","KillAura","ClickAura","CrystalAura",
    "AnchorAura","BedAura","ReachHack","AntiKB","NoKnockback","PlayerESP","XRayHack","ScaffoldWalk"
)

$suspiciousPatterns = $cheatStrings  # same high-signal list for entry names

# ---------- Helpers ----------
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-FileSHA1 { param([string]$Path) (Get-FileHash -Path $Path -Algorithm SHA1).Hash }

function Query-Modrinth {
    param([string]$Hash)
    try {
        $v = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if ($v.project_id) {
            $p = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($v.project_id)" -Method Get -UseBasicParsing -ErrorAction Stop
            return @{ Name = $p.title; Slug = $p.slug }
        }
    } catch {}
    return @{ Name = ""; Slug = "" }
}

function Invoke-ModScan {
    param([string]$FilePath)
    $found = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)

        foreach ($entry in $zip.Entries) {
            foreach ($p in $suspiciousPatterns) {
                if ($entry.FullName -like "*$p*") { [void]$found.Add($p) }
            }
        }

        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -match '\.(class|json)$' -or $entry.FullName -match 'MANIFEST\.MF') {
                try {
                    $ms = New-Object System.IO.MemoryStream
                    $entry.Open().CopyTo($ms)
                    $text = [System.Text.Encoding]::UTF8.GetString($ms.ToArray()) +
                            [System.Text.Encoding]::ASCII.GetString($ms.ToArray())
                    $ms.Dispose()

                    foreach ($s in $cheatStrings) {
                        if ($text.Contains($s)) { [void]$found.Add($s) }
                    }
                } catch {}
            }
        }
        $zip.Dispose()
    } catch {}
    return $found
}

function Get-ObfuscationFlags {
    param([string]$FilePath)
    $flags = [System.Collections.Generic.List[string]]::new()
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $total = 0; $numeric = 0; $unicode = 0; $single = 0; $jp = 0; $fw = 0

        foreach ($e in $zip.Entries) {
            if ($e.FullName -match '\.class$') {
                $total++
                $name = [IO.Path]::GetFileNameWithoutExtension(($e.FullName -split '/')[-1])
                if ($name -match '^\d+$')          { $numeric++ }
                if ($name -match '[^\x00-\x7F]')   { $unicode++ }
                if ($name -match '^[a-zA-Z]$')     { $single++ }
                if ($name -match '[\u3040-\u30FF]'){ $jp++ }
                if ($name -match '[\uFF21-\uFF5A]'){ $fw++ }
            }
        }
        $zip.Dispose()
        if ($total -lt 10) { return $flags }

        $pct = { param($n) [math]::Round(($n / $total) * 100) }
        if ((& $pct $numeric) -ge 30) { $flags.Add("Heavy numeric class names ($((& $pct $numeric))%)") }
        if ((& $pct $unicode) -ge 20) { $flags.Add("Unicode class names ($((& $pct $unicode))%)") }
        if ((& $pct $single)  -ge 25) { $flags.Add("Single-letter class names ($((& $pct $single))%)") }
        if ($jp -gt 0)                { $flags.Add("Japanese obfuscation ($jp classes)") }
        if ($fw -gt 0)                { $flags.Add("Fullwidth Unicode class names ($fw classes)") }
    } catch {}
    return $flags
}

# ---------- Main scan ----------
$jars = Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction SilentlyContinue
if ($jars.Count -eq 0) {
    Write-Host "[!] No JAR files found." -ForegroundColor Yellow
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Host "[*] Found $($jars.Count) JAR files" -ForegroundColor Green
Write-Host ""

$suspicious = @()
$obfuscated = @()
$verified   = @()
$unknown    = @()
$clean      = 0

$i = 0
foreach ($jar in $jars) {
    $i++
    Write-Host "`r  Scanning [$i/$($jars.Count)] $($jar.Name)..." -NoNewline

    $hash = Get-FileSHA1 $jar.FullName
    $modr = Query-Modrinth $hash
    if ($modr.Slug) {
        $verified += [PSCustomObject]@{ Name = $modr.Name; File = $jar.Name }
        continue
    }

    $matches = Invoke-ModScan $jar.FullName
    $obf     = Get-ObfuscationFlags $jar.FullName

    if ($matches.Count -gt 0) {
        $suspicious += [PSCustomObject]@{ File = $jar.Name; Matches = $matches }
    }
    elseif ($obf.Count -gt 0) {
        $obfuscated += [PSCustomObject]@{ File = $jar.Name; Flags = $obf }
    }
    else {
        $unknown += $jar.Name
        $clean++
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

if ($verified.Count -gt 0) {
    Write-Host "  [+] VERIFIED MODS ($($verified.Count))" -ForegroundColor Green
    Write-Host "  --------------------------------------" -ForegroundColor DarkGray
    foreach ($m in $verified) {
        Write-Host "    ✓ $($m.Name)  →  $($m.File)" -ForegroundColor Green
    }
    Write-Host ""
}

if ($suspicious.Count -gt 0) {
    Write-Host "  [!] SUSPICIOUS MODS ($($suspicious.Count))" -ForegroundColor Red
    Write-Host "  --------------------------------------" -ForegroundColor DarkRed
    Write-Host ""

    foreach ($mod in $suspicious) {
        Write-Host "  +-- $($mod.File)" -ForegroundColor Yellow
        Write-Host "  |" -ForegroundColor DarkRed
        Write-Host "  |  Detected!" -ForegroundColor Red
        foreach ($s in ($mod.Matches | Sort-Object)) {
            Write-Host "  |    • $s" -ForegroundColor Red
        }
        Write-Host "  +------------------------------------" -ForegroundColor DarkRed
        Write-Host ""
    }
}

if ($obfuscated.Count -gt 0) {
    Write-Host "  [!] HEAVILY OBFUSCATED (no known strings)" -ForegroundColor DarkYellow
    Write-Host "  --------------------------------------" -ForegroundColor DarkYellow
    Write-Host ""
    foreach ($mod in $obfuscated) {
        Write-Host "  +-- $($mod.File)" -ForegroundColor Yellow
        foreach ($f in $mod.Flags) {
            Write-Host "  |    > $f" -ForegroundColor Yellow
        }
        Write-Host "  +------------------------------------" -ForegroundColor DarkYellow
        Write-Host ""
    }
}

if ($unknown.Count -gt 0 -and $suspicious.Count -eq 0 -and $obfuscated.Count -eq 0) {
    Write-Host "  [+] No cheat indicators found." -ForegroundColor Green
    Write-Host "  All remaining mods appear clean." -ForegroundColor Green
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Total JARs scanned     : $($jars.Count)" -ForegroundColor White
Write-Host "  Verified (Modrinth)    : $($verified.Count)" -ForegroundColor Green
Write-Host "  Suspicious (strings)   : $($suspicious.Count)" -ForegroundColor Red
Write-Host "  Heavily obfuscated     : $($obfuscated.Count)" -ForegroundColor Yellow
Write-Host "  Clean / Unknown        : $clean" -ForegroundColor Gray
Write-Host "  Minecraft running      : Yes (PID $($proc.Id))" -ForegroundColor Green
Write-Host ""
Write-Host "  Scan complete – Magician's Reveal v3.1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
