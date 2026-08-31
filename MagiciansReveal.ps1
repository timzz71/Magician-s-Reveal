# ============================================================
#  MAGICIAN'S REVEAL  v3.7
#  Professional Minecraft Forensic Scanner
#  Broad cheat client detection
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

Write-Host ""
Write-Host "  MAGICIAN'S REVEAL  v3.7" -ForegroundColor Cyan
Write-Host "  Professional Minecraft Forensic Scanner" -ForegroundColor DarkCyan
Write-Host ""

# ---------- Minecraft check ----------
Write-Host "  Checking Minecraft process..." -ForegroundColor Gray

$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) { $mcProcess = Get-Process java -ErrorAction SilentlyContinue }

if (-not $mcProcess) {
    Write-Host ""
    Write-Host "  [!]  MINECRAFT IS NOT RUNNING" -ForegroundColor Red
    Write-Host "  This session is INVALID." -ForegroundColor Red
    Write-Host "  Start Minecraft and run the scanner again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$proc      = $mcProcess | Select-Object -First 1
$startTime = $proc.StartTime
$uptime    = (Get-Date) - $startTime

Write-Host "  Minecraft is running" -ForegroundColor Green
Write-Host "  Process : $($proc.Name)  |  PID : $($proc.Id)" -ForegroundColor DarkGray
Write-Host "  Started : $startTime" -ForegroundColor DarkGray
Write-Host "  Uptime  : $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor DarkGray
Write-Host ""

# ---------- Mods path ----------
Write-Host "  Enter path to the mods folder (press Enter for default):" -ForegroundColor Gray
$modsPath = Read-Host "  PATH"

if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
}

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "  Invalid path: $modsPath" -ForegroundColor Red
    Write-Host "  Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "  Scanning: $modsPath" -ForegroundColor DarkCyan
Write-Host ""

# ---------- Comprehensive high-signal cheat indicators ----------
$cheatStrings = @(
    # === Combat / Utility Modules ===
    "AutoCrystal","AutoHitCrystal","AutoAnchor","DoubleAnchor","SafeAnchor","AirAnchor",
    "AutoTotem","InventoryTotem","HoverTotem","LegitTotem","AutoPot","AutoPotRefill","AutoArmor",
    "ShieldBreaker","ShieldDisabler","AutoDoubleHand","AutoMace","MaceSwap","StunSlam","AxeSpam",
    "TriggerBot","AimAssist","SilentAim","SilentRotations","FakeLag","PingSpoof","FakeInv","WTap",
    "AutoWeb","WebMacro","KeyPearl","LootYeeter","AutoFirework","ElytraSwap","FastPlace",
    "PackSpoof","Antiknockback","AuthBypass","obfuscatedAuth","LicenseCheckMixin","BaseFinder",
    "SelfDestruct","HideClient","SessionStealer","TokenLogger","TokenGrabber","DiscordToken",
    "RemoteAccess","ReverseShell","C2Server","Backdoor","KeyLogger","StashFinder","TrailFinder",
    "KillAura","ClickAura","MultiAura","ForceField","LegitAura","CrystalAura","AnchorAura",
    "BedAura","AutoBed","BedBomb","BowAimbot","BowSpam","AutoBow","AutoCrit","CritBypass",
    "AlwaysCrit","CriticalHit","ReachHack","ExtendReach","LongReach","HitboxExpand","HitboxExpander",
    "AntiKB","NoKnockback","GrimVelocity","VelocitySpoof","KBReduce","OffhandTotem","TotemSwitch",
    "AutoWeapon","AutoSword","AutoCity","Burrow","SelfTrap","HoleFiller","AntiSurround","AntiBurrow",
    "TargetStrafe","AutoGap","AutoPearl","FlyHack","CreativeFlight","BoatFly","PacketFly","AirJump",
    "SpeedHack","BHop","BunnyHop","AntiFall","NoFallDamage","SafeFall","StepHack","FastClimb",
    "AutoStep","HighStep","WaterWalk","LiquidWalk","LavaWalk","NoSlow","NoSlowdown","NoWeb",
    "NoSoulSand","WallHack","ElytraSpeed","InstantElytra","ScaffoldWalk","FastBridge","BuildHelper",
    "AutoBridge","Nuker","NukerLegit","InstantBreak","GhostHand","NoSwing","PlaceAssist","AirPlace",
    "AutoPlace","InstantPlace","PlayerESP","MobESP","ItemESP","StorageESP","ChestESP","Tracers",
    "NameTagsHack","XRayHack","OreFinder","CaveFinder","OreESP","NewChunks","ChunkBorders",
    "TunnelFinder","TargetHUD","ReachDisplay","ReachHudElement","DoubleClicker","JitterClick",
    "ButterflyClick","CPSBoost","ChestStealer","InvManager","InvMovebypass","AutoSprint","AntiAFK",
    "AutoRespawn","PopSwitch","FakeLatency","FakePing","SpoofRotation","PositionSpoof","GameSpeed",
    "SpeedTimer","GrimBypass","VulcanBypass","MatrixBypass","AACBypass","VerusDisabler",
    "IntaveBypass","WatchdogBypass","PacketMine","PacketWalk","PacketSneak","PacketCancel",
    "PacketDupe","PacketSpam","NoJumpDelay","AutoClicker","BowAim","Criticals",

    # === Known Clients / Packages / Authors ===
    "com/slither/cyemer","com/slither/velaris","dev/lvstrng/aidsfuscator",
    "dev.krypton","skid.krypton","dev.virel","orchard","org.chainlibs.module.impl.modules",
    "meteordevelopment","meteorclient","meteor-client","liquidbounce","fdp-client","net.ccbluex",
    "doomsdayclient","DoomsdayClient","novaclient","api.novaclient.lol","novoware",
    "vape.gg","vapeclient","VapeClient","VapeLite","intent.store","IntentClient",
    "rise.today","riseclient.com","aristois","impactclient","azura","pandaware","skilled",
    "moonClient","astolfo","futureClient","konas","rusherhack","inertia","exhibition",
    "catlean","CatleanClient","ArgonClient","Asteria","AsteriaClient","PrestigeClient",
    "prestigeclient.vip","gypsy","GypsyClient","XenonClient","GrimClient","dqrkis.xyz",
    "Dqrkis Client","WalksyOptimizer","WalksyCrystalOptimizerMod","WalskyOptimizer",
    "LWFH Crystal","xyz.greaj","imgui.gl3","imgui.glfw","jnativehook","JNativeHook",
    "GlobalScreen","NativeKeyListener","phantom-refmap.json","client-refmap.json","cheat-refmap.json",
    "ClientPlayerInteractionManagerAccessor","ClientPlayerEntityMixim","dev.gambleclient",
    "VelarisAuth","NativeObf","TriggerBotReadyEvent","sixtwo/","fivefive/",
    "mixin/accessors/ItemInHandRendererAccessor","startAttackPre","startUseItemPost",
    "wurst","sigma","novoline","impact","wurstclient","sigma5","sigma6","aristois",
    "liquidbounce","fdpclient","meteorclient","rusherhack","konasclient","futureclient",
    "inertia","exhibition","moonlight","maxstats","alan clients","zeroeightsix","kami",
    "bleachhack","huzuni","kamiblue","lambda","seppuku","vertex","xulu","zeon",
    "doomsday","prestige","asteria","catlean","argon","xenon","gypsy","dqrkis","walksy",
    "198macros","macro198","stunslam","safeanchor","doubleanchor","keypearl","looteeter",

    # === Domains / URLs / Auth ===
    "vape.gg","intent.store","rise.today","riseclient.com","prestigeclient.vip",
    "dqrkis.xyz","api.novaclient.lol","doomsdayclient.com","meteorclient.com",
    "liquidbounce.net","wurstclient.net","impactclient.net","aristois.net",

    # === Common obfuscation / injection markers ===
    "LicenseCheckMixin","obfuscatedAuth","AuthBypass","SelfDestruct","HideClient",
    "SessionStealer","TokenLogger","TokenGrabber","DiscordToken","RemoteAccess",
    "ReverseShell","C2Server","Backdoor","KeyLogger"
)

# ---------- Helpers ----------
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Invoke-ModScan {
    param([string]$FilePath)

    $found = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
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

        foreach ($entry in $allEntries) {
            $name = $entry.FullName
            foreach ($p in $cheatStrings) {
                if ($name -match [regex]::Escape($p)) { [void]$found.Add($p) }
            }
            if ($name -match 'dev/lvstrng/aidsfuscator') { [void]$found.Add("dev/lvstrng/aidsfuscator") }
            if ($name -match 'MixinExperienceOrb')       { [void]$found.Add("MixinExperienceOrb*") }
            if ($name -match '^a/Clumps')                 { [void]$found.Add("a/Clumps (obfuscated)") }
        }

        foreach ($entry in $allEntries) {
            if ($entry.FullName -match '\.(class|json)$' -or $entry.FullName -match 'MANIFEST\.MF') {
                try {
                    $ms = New-Object System.IO.MemoryStream
                    $entry.Open().CopyTo($ms)
                    $bytes = $ms.ToArray()
                    $ms.Dispose()
                    $text = [System.Text.Encoding]::UTF8.GetString($bytes) + [System.Text.Encoding]::ASCII.GetString($bytes)
                    foreach ($s in $cheatStrings) {
                        if ($text.Contains($s)) { [void]$found.Add($s) }
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
        $totalClass = 0; $numeric = 0; $unicode = 0; $singleLetter = 0; $japanese = 0; $fullwidth = 0; $singleCharPkg = 0

        foreach ($entry in $archive.Entries) {
            if ($entry.FullName -match '\.class$') {
                $totalClass++
                $className = [System.IO.Path]::GetFileNameWithoutExtension(($entry.FullName -split '/')[-1])
                $pkg = ($entry.FullName -replace '\.class$','' -split '/')[0]
                if ($className -match '^\d+$')                         { $numeric++ }
                if ($className -match '[^\x00-\x7F]')                  { $unicode++ }
                if ($className -match '^[a-zA-Z]$')                    { $singleLetter++ }
                if ($className -match '[\u3040-\u309F\u30A0-\u30FF]') { $japanese++ }
                if ($className -match '[\uFF21-\uFF3A\uFF41-\uFF5A]') { $fullwidth++ }
                if ($pkg.Length -eq 1)                                { $singleCharPkg++ }
            }
        }
        $archive.Dispose()
        if ($totalClass -lt 8) { return $flags }

        $pct = { param($n) [math]::Round(($n / $totalClass) * 100) }
        if ((& $pct $numeric) -ge 25)      { $flags.Add("Heavy numeric class names ($((& $pct $numeric))%)") }
        if ((& $pct $unicode) -ge 15)      { $flags.Add("Unicode class names ($((& $pct $unicode))%)") }
        if ((& $pct $singleLetter) -ge 20) { $flags.Add("Single-letter class names ($((& $pct $singleLetter))%)") }
        if ($singleCharPkg -ge 10)         { $flags.Add("Single-letter package paths (a/b/c style)") }
        if ($japanese -gt 0)               { $flags.Add("Japanese obfuscation ($japanese classes)") }
        if ($fullwidth -gt 0)              { $flags.Add("Fullwidth Unicode class names ($fullwidth classes)") }
    } catch {}
    return $flags
}

# ---------- Scan ----------
$jarFiles = Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction SilentlyContinue
if ($jarFiles.Count -eq 0) {
    Write-Host "  No JAR files found." -ForegroundColor Yellow
    Write-Host "  Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Host "  Found $($jarFiles.Count) JAR files" -ForegroundColor DarkCyan
Write-Host ""

$suspiciousMods = @()
$obfuscatedMods = @()
$cleanCount = 0
$idx = 0

foreach ($jar in $jarFiles) {
    $idx++
    Write-Host "`r  Scanning [$idx/$($jarFiles.Count)] $($jar.Name)..." -NoNewline

    $matches  = Invoke-ModScan -FilePath $jar.FullName
    $obfFlags = Get-ObfuscationFlags -FilePath $jar.FullName

    if ($matches.Count -gt 0) {
        $suspiciousMods += [PSCustomObject]@{ FileName = $jar.Name; Matches = $matches }
    }
    elseif ($obfFlags.Count -gt 0) {
        $obfuscatedMods += [PSCustomObject]@{ FileName = $jar.Name; Flags = $obfFlags }
    }
    else {
        $cleanCount++
    }
}
Write-Host "`r$(' ' * 80)`r" -NoNewline

# ---------- Results ----------
Write-Host ""
Write-Host "  RESULTS" -ForegroundColor Cyan
Write-Host ""

if ($suspiciousMods.Count -eq 0 -and $obfuscatedMods.Count -eq 0) {
    Write-Host "  No cheat indicators found." -ForegroundColor Green
    Write-Host "  All $cleanCount mods appear clean." -ForegroundColor Green
}
else {
    if ($suspiciousMods.Count -gt 0) {
        Write-Host "  SUSPICIOUS MODS ($($suspiciousMods.Count))" -ForegroundColor Red
        Write-Host ""

        foreach ($mod in $suspiciousMods) {
            Write-Host "  $($mod.FileName)" -ForegroundColor Yellow
            Write-Host "  Detected!" -ForegroundColor Red
            foreach ($m in ($mod.Matches | Sort-Object)) {
                Write-Host "    • $m" -ForegroundColor Red
            }
            Write-Host ""
        }
    }

    if ($obfuscatedMods.Count -gt 0) {
        Write-Host "  HEAVILY OBFUSCATED ($($obfuscatedMods.Count))" -ForegroundColor DarkYellow
        Write-Host ""
        foreach ($mod in $obfuscatedMods) {
            Write-Host "  $($mod.FileName)" -ForegroundColor Yellow
            foreach ($f in $mod.Flags) {
                Write-Host "    > $f" -ForegroundColor DarkYellow
            }
            Write-Host ""
        }
    }
}

Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "  Total scanned      : $($jarFiles.Count)" -ForegroundColor White
Write-Host "  Clean              : $cleanCount" -ForegroundColor Green
Write-Host "  Suspicious         : $($suspiciousMods.Count)" -ForegroundColor Red
Write-Host "  Heavily obfuscated : $($obfuscatedMods.Count)" -ForegroundColor Yellow
Write-Host "  Minecraft          : Running (PID $($proc.Id))" -ForegroundColor Green
Write-Host ""
Write-Host "  Scan complete – Magician's Reveal v3.7" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
