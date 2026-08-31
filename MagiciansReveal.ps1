# ============================================================
#  MAGICIAN'S REVEAL  v5.1
#  Professional Minecraft Forensic Scanner
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

Write-Host ""
Write-Host "  MAGICIAN'S REVEAL  v5.1" -ForegroundColor Cyan
Write-Host "  Advanced Minecraft Client Analysis" -ForegroundColor DarkGray
Write-Host ""

# ---------- Minecraft process check ----------
Write-Host "  Checking running processes..." -ForegroundColor Gray

$mc = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mc) { $mc = Get-Process java -ErrorAction SilentlyContinue }

if (-not $mc) {
    Write-Host ""
    Write-Host "  Minecraft is not running." -ForegroundColor Red
    Write-Host "  This session is considered INVALID." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$proc = $mc | Select-Object -First 1
$uptime = (Get-Date) - $proc.StartTime

Write-Host "  Minecraft detected" -ForegroundColor Green
Write-Host "  PID $($proc.Id)  |  Running for $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor DarkGray
Write-Host ""

# ---------- Path input ----------
Write-Host "  Mods folder path (Enter = default):" -ForegroundColor Gray
$path = Read-Host "  >"

if ([string]::IsNullOrWhiteSpace($path)) {
    $path = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
}

if (-not (Test-Path $path -PathType Container)) {
    Write-Host "  Path not found." -ForegroundColor Red
    exit 1
}

Write-Host "  Target: $path" -ForegroundColor DarkCyan
Write-Host ""

# ============================================================
#  DETECTION DATA
#  (module/path signatures, literal cheat strings, fullwidth
#   evasion variants, known cheat-grade obfuscators)
# ============================================================

$moduleNames = @(
    "AutoCrystal","AutoHitCrystal","AutoAnchor","DoubleAnchor","SafeAnchor","AirAnchor",
    "AutoTotem","InventoryTotem","HoverTotem","AutoPot","AutoPotRefill","AutoArmor",
    "ShieldBreaker","ShieldDisabler","AutoMace","MaceSwap","StunSlam","AxeSpam",
    "TriggerBot","AimAssist","SilentAim","FakeLag","PingSpoof","FakeInv","WTap",
    "KeyPearl","AutoFirework","ElytraSwap","FastPlace","SelfDestruct","KillAura",
    "CrystalAura","AnchorAura","BedAura","ReachHack","HitboxExpand","PlayerESP",
    "XRayHack","ScaffoldWalk","AutoClicker","BowAim","Criticals","NoJumpDelay",
    "AutoDoubleHand","AutoNethPot","AutoDtap","AutoWeb","AnchorAction","AntiWeb",
    "AutoBreach","FreezePlayer","LootYeeter","AutoTPA","BaseFinder","AutoEat","AutoMine"
)

$clientSignatures = @(
    "com/slither/cyemer","com/slither/velaris","dev/lvstrng/aidsfuscator",
    "dev.krypton","skid.krypton","dev.virel","org.chainlibs",
    "meteordevelopment","meteorclient","liquidbounce","fdp-client","net.ccbluex",
    "doomsdayclient","novaclient","vape.gg","vapeclient","intent.store",
    "rise.today","aristois","impactclient","rusherhack","catlean",
    "AsteriaClient","PrestigeClient","GypsyClient","XenonClient","dqrkis.xyz",
    "WalksyOptimizer","imgui.gl3","imgui.glfw","jnativehook","phantom-refmap.json",
    "ClientPlayerInteractionManagerAccessor","LicenseCheckMixin","obfuscatedAuth",
    "sixtwo/","fivefive/","com/alan/clients","club/maxstats",
    "wtf/moonlight","me/zeroeightsix/kami","today/opai","xyz/greaj",
    "com/cheatbreaker","com/moonsworth","novoware","novoclient","pandaware",
    "moonClient","astolfo","futureClient","exhibition",
    "org/chainlibs/module/impl/modules"
    # NOTE: generic single-word or generic-pattern signatures (e.g. bare
    # "mixin/accessors", "orchard", "gypsy", "argon", "inertia", "konas")
    # were deliberately excluded here — they're either normal Mixin/Fabric
    # plumbing or common English words that show up in legitimate mod
    # packages, and matching on them alone produces false positives like
    # flagging ferritecore/moreculling/BadOptimizations for using accessors.
)

# Literal in-jar strings that show up in configs / decompiled fragments of
# cheat clients. Includes fullwidth-unicode evasion variants some clients
# use to dodge plain ASCII string scans.
$literalCheatStrings = @(
    "AutoCrystal","autocrystal","dontPlaceCrystal","dontBreakCrystal","healPotSlot",
    "canPlaceCrystalServer","AutoHitCrystal","AutoAnchor","anchortweaks","anchorMacro",
    "AutoTotem","InventoryTotem","HoverTotem","legittotem","AutoPot","speedPotSlot",
    "strengthPotSlot","AutoArmor","preventSwordBlockBreaking","preventSwordBlockAttack",
    "ShieldDisabler","ShieldBreaker","Breaking shield with axe...","AutoDoubleHand",
    "Failed to switch to mace after axe!","AutoMace","MaceSwap","SpearSwap","StunSlam",
    "findKnockbackSword","attackRegisteredThisClick","AimAssist","triggerbot",
    "Silent Rotations","FakeInv","swapBackToOriginalSlot","FakeLag","pingspoof",
    "fakePunch","mace_swap","quick_strike","macro_198","stun_slam","safe_anchor",
    "double_anchor","auto_pot_refill","walksy_optimizer","key_pearl","aim_assist",
    "auto_neth_pot","auto_dtap","trigger_bot","auto_web","AnchorAction",
    "Places two anchors for massive damage","REOFFHAND_TOTEM","webmacro","AntiWeb",
    "AutoWeb","selfdestruct","autoCrystalPlaceClock","AutoFirework","ElytraSwap",
    "NoJumpDelay","AuthBypass","obfuscatedAuth","LicenseCheckMixin","BaseFinder",
    "invsee","ItemExploit","FreezePlayer","LWFH Crystal","KeyPearl","LootYeeter",
    "FastPlace","AutoBreach","setBlockBreakingCooldown","getBlockBreakingCooldown",
    "onBlockBreaking","invokeDoAttack","invokeDoItemUse","invokeOnMouseButton",
    "POT_CHEATS","Entity.isGlowing","No Bounce","Place Delay","Break Delay",
    "Place Chance","Break Chance","Stop On Kill","Anti Weakness","Trigger Key",
    "Totem Slot","Silent Rotations","Rotation Speed","Easing Strength",
    "Glowstone Delay","Explode Delay","Explode Chance","Anchor Macro",
    "Reach Distance","Attack Delay","Breach Delay","Require Elytra",
    "Check Line of Sight","Require Crit","Predict Damage","Check Shield",
    "Predict Crystals","Blatant","Force Totem","Vertical Speed","Swap Speed",
    "Mace Priority","Min Totems","Min Pearls","Drop Interval","Loot Yeeter",
    "Horizontal Aim Speed","Web Delay","Holding Web","Hit Delay",
    "Require Hold Axe","placeInterval","breakInterval","stopOnKill",
    "activateOnRightClick","holdCrystal","KillAura","ClickAura","MultiAura",
    "ForceField","LegitAura","AimBot","AutoAim","AimLock","HeadSnap","CrystalAura",
    "AnchorAura","AnchorFill","AnchorPlace","BedAura","AutoBed","BedBomb","BedPlace",
    "BowAimbot","BowSpam","AutoBow","AutoCrit","CritBypass","AlwaysCrit",
    "ReachHack","ExtendReach","LongReach","HitboxExpand","AntiKB","NoKnockback",
    "GrimVelocity","GrimDisabler","VelocitySpoof","KBReduce","OffhandTotem",
    "TotemSwitch","Burrow","SelfTrap","HoleFiller","AntiSurround","AntiBurrow",
    "WTap","TargetStrafe","AutoGap","AutoPearl","FlyHack","CreativeFlight",
    "BoatFly","PacketFly","AirJump","SpeedHack","BHop","BunnyHop","AntiFall",
    "NoFallDamage","StepHack","FastClimb","AutoStep","HighStep","WaterWalk",
    "LiquidWalk","LavaWalk","NoSlow","NoSlowdown","NoWeb","NoSoulSand","WallHack",
    "ElytraSpeed","InstantElytra","ScaffoldWalk","FastBridge","BuildHelper",
    "AutoBridge","Nuker","InstantBreak","GhostHand","NoSwing","PlaceAssist",
    "AirPlace","AutoPlace","InstantPlace","PlayerESP","MobESP","ItemESP",
    "StorageESP","ChestESP","Tracers","NameTagsHack","XRayHack","OreFinder",
    "CaveFinder","OreESP","NewChunks","ChunkBorders","TunnelFinder","TargetHUD",
    "DoubleClicker","JitterClick","ButterflyClick","CPSBoost","ChestStealer",
    "InvManager","AutoSprint","AntiAFK","AutoRespawn","PopSwitch","FakeLatency",
    "FakePing","SpoofRotation","PositionSpoof","GameSpeed","SpeedTimer",
    "GrimBypass","VulcanBypass","MatrixBypass","AACBypass","VerusDisabler",
    "IntaveBypass","WatchdogBypass","PacketMine","PacketWalk","PacketSneak",
    "PacketCancel","PacketDupe","PacketSpam","SelfDestruct","HideClient",
    "SessionStealer","TokenLogger","TokenGrabber","DiscordToken","RemoteAccess",
    "ReverseShell","C2Server","Backdoor","KeyLogger","StashFinder","TrailFinder",
    "JNativeHook","GlobalScreen","NativeKeyListener","client-refmap.json",
    "cheat-refmap.json",
    # Fullwidth-unicode variants (common obfuscation trick to dodge ASCII scans)
    "ＡｕｔｏＣｒｙｓｔａｌ","ＡｕｔｏＨｉｔＣｒｙｓｔａｌ","ＡｕｔｏＡｎｃｈｏｒ",
    "ＤｏｕｂｌｅＡｎｃｈｏｒ","ＳａｆｅＡｎｃｈｏｒ","ＡｕｔｏＴｏｔｅｍ",
    "ＨｏｖｅｒＴｏｔｅｍ","ＩｎｖｅｎｔｏｒｙＴｏｔｅｍ","ＡｕｔｏＰｏｔ",
    "ＡｕｔｏＡｒｍｏｒ","ＳｈｉｅｌｄＤｉｓａｂｌｅｒ","ＡｕｔｏＤｏｕｂｌｅＨａｎｄ",
    "ＡｕｔｏＣｌｉｃｋｅｒ","ＡｕｔｏＭａｃｅ","ＭａｃｅＳｗａｐ","ＡｉｍＡｓｓｉｓｔ",
    "ＴｒｉｇｇｅｒＢｏｔ","Ｓｉｌｅｎｔ Ｒｏｔａｔｉｏｎｓ","ＦａｋｅＬａｇ",
    "Ｆａｋｅ Ｐｕｎｃｈ","Ａｎｔｉ Ｗｅｂ","ＡｕｔｏＷｅｂ","Ｗａｌｋｓｙ Ｏｐｔｉｍｉｚｅｒ",
    "ＥｌｙｔｒａＳｗａｐ","ＬＷＦＨ Ｃｒｙｓｔａｌ","ＫｅｙＰｅａｒｌ","Ｆａｓｔ Ｐｌａｃｅ",
    "Ａｕｔｏ Ｂｒｅａｃｈ"
)

# Known cheat-grade obfuscators / packers seen wrapping hacked-client jars
$knownCheatObfuscators = @{
    "Skidfuscator"   = @("dev/skidfuscator", "Skidfuscator", "skidfuscator.dev")
    "Paramorphism"   = @("Paramorphism", "paramorphism-", "dev/paramorphism")
    "Radon"          = @("ItzSomebody/Radon", "me/itzsomebody/radon", "Radon Obfuscator")
    "Caesium"        = @("sim0n/Caesium", "Caesium Obfuscator", "dev/sim0n/caesium")
    "Bozar"          = @("vimasig/Bozar", "Bozar Obfuscator", "com/bozar")
    "Branchlock"     = @("Branchlock", "branchlock.dev")
    "Binscure"       = @("Binscure", "com/binscure")
    "Qprotect"       = @("Qprotect", "QProtect", "mdma.dev/qprotect")
}

$allIndicators = $moduleNames + $clientSignatures

# ============================================================
#  CORE ANALYSIS FUNCTIONS
# ============================================================
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-AllZipEntries {
    # Flattens a jar plus any nested jars under META-INF/jars into one entry list.
    param($ZipArchive)
    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($e in $ZipArchive.Entries) { $entries.Add($e) }

    foreach ($nested in ($ZipArchive.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })) {
        try {
            $ms = New-Object System.IO.MemoryStream
            $nested.Open().CopyTo($ms)
            $ms.Position = 0
            $inner = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
            foreach ($ie in $inner.Entries) { $entries.Add($ie) }
        } catch {}
    }
    return $entries
}

function Analyze-Content {
    # Signature + literal-string + fullwidth-evasion scan across class/json entries.
    param([string]$file)

    $hits    = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $strHits = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

    try {
        $zip     = [System.IO.Compression.ZipFile]::OpenRead($file)
        $entries = Get-AllZipEntries -ZipArchive $zip

        foreach ($entry in $entries) {
            foreach ($sig in $allIndicators) {
                if ($entry.FullName -match [regex]::Escape($sig)) {
                    [void]$hits.Add($sig)
                }
            }
        }

        foreach ($entry in $entries) {
            if ($entry.FullName -match '\.(class|json)$' -or $entry.FullName -match 'MANIFEST\.MF') {
                try {
                    $ms = New-Object System.IO.MemoryStream
                    $entry.Open().CopyTo($ms)
                    $bytes = $ms.ToArray()
                    $ms.Dispose()

                    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
                    $utf8  = [System.Text.Encoding]::UTF8.GetString($bytes)

                    foreach ($sig in $allIndicators) {
                        if ($ascii.Contains($sig)) { [void]$hits.Add($sig) }
                    }
                    foreach ($cs in $literalCheatStrings) {
                        if ($ascii.Contains($cs) -or $utf8.Contains($cs)) { [void]$strHits.Add($cs) }
                    }
                } catch {}
            }
        }
        $zip.Dispose()
    } catch {}

    return @{ Signatures = $hits; Strings = $strHits }
}

function Analyze-Structure {
    # Class-name / package heuristics for obfuscation, plus known-obfuscator matching.
    param([string]$file)

    $flags = [System.Collections.Generic.List[string]]::new()
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($file)
        $total = 0
        $numeric = 0
        $single = 0
        $unicode = 0
        $fullwidth = 0
        $confusion = 0
        $singlePkg = 0
        $sampleBuf = [System.Text.StringBuilder]::new()
        $sampleLen = 0

        foreach ($e in $zip.Entries) {
            if ($e.FullName -match '\.class$') {
                $total++
                $name = [IO.Path]::GetFileNameWithoutExtension(($e.FullName -split '/')[-1])
                $pkg  = ($e.FullName -replace '\.class$','' -split '/')[0]

                if ($name -match '^\d+$')              { $numeric++ }
                if ($name -match '^[a-zA-Z]$')         { $single++ }
                if ($name -match '[^\x00-\x7F]')       { $unicode++ }
                if ($name -match '[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]') { $fullwidth++ }
                if ($name -match '^[Il1O0_]+$')        { $confusion++ }
                if ($pkg.Length -eq 1)                 { $singlePkg++ }

                if ($sampleLen -lt 120000 -and $e.Length -lt 100000 -and $e.Length -gt 100) {
                    try {
                        $ms = New-Object System.IO.MemoryStream
                        $e.Open().CopyTo($ms)
                        $txt = [System.Text.Encoding]::ASCII.GetString($ms.ToArray())
                        $ms.Dispose()
                        [void]$sampleBuf.Append($txt)
                        $sampleLen += $txt.Length
                    } catch {}
                }
            }
        }
        $zip.Dispose()

        if ($total -lt 6) { return $flags }

        $p = { param($n) [math]::Round(($n / $total) * 100) }

        if ((& $p $numeric) -ge 20)    { $flags.Add("Numeric class names ($((& $p $numeric))%)") }
        if ((& $p $single) -ge 15)     { $flags.Add("Single-letter class names ($((& $p $single))%)") }
        if ((& $p $unicode) -ge 12)    { $flags.Add("Unicode class names ($((& $p $unicode))%)") }
        if ($fullwidth -gt 0)          { $flags.Add("Fullwidth Unicode class names ($fullwidth classes)") }
        if ((& $p $confusion) -ge 8)   { $flags.Add("Confusion characters (Il1O0/_) ($((& $p $confusion))%)") }
        if ($singlePkg -ge 8)          { $flags.Add("Single-letter package structure") }

        $sampleStr = $sampleBuf.ToString()
        foreach ($obfName in $knownCheatObfuscators.Keys) {
            foreach ($pat in $knownCheatObfuscators[$obfName]) {
                if ($sampleStr.Contains($pat)) {
                    $flags.Add("Known cheat-grade obfuscator: $obfName")
                    break
                }
            }
        }
    } catch {}
    return $flags
}

$knownLegitModIds = @(
    "vmp-fabric","vmp","lithium","sodium","iris","fabric-api",
    "modmenu","ferrite-core","ferritecore","lazydfu","starlight",
    "entityculling","moreculling","memoryleakfix","krypton","c2me-fabric",
    "smoothboot-fabric","immediatelyfast","noisium","threadtweak",
    "badoptimizations","dynamic-fps","cloth-config","yet_another_config_lib_v3"
)

function Test-SuspiciousNestedJarName {
    # Nested jars with no version and no maven-style group prefix are a
    # common way cheat loaders smuggle a hidden payload inside an
    # innocent-looking wrapper jar.
    param([string]$JarName)
    $mavenPrefixes = @("com_","org_","net_","io_","dev_","gs_","xyz_","app_","me_","tv_")
    $base = [System.IO.Path]::GetFileNameWithoutExtension($JarName)
    if ($base -match '\d') { return $false }
    foreach ($pfx in $mavenPrefixes) { if ($base.ToLower().StartsWith($pfx)) { return $false } }
    if ($base.Length -gt 20) { return $false }
    return $true
}

function Analyze-Bypass {
    # Runtime.exec / HTTP download / HTTP exfiltration / nested-jar smuggling /
    # fake-mod-identity (a jar impersonating a well-known clean mod) detection.
    param([string]$file)

    $flags = [System.Collections.Generic.List[string]]::new()
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($file)

        # --- nested-jar smuggling check ---
        $nestedJars   = @($zip.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })
        $outerClasses = @($zip.Entries | Where-Object { $_.FullName -match "\.class$" })

        foreach ($nj in $nestedJars) {
            $njName = [System.IO.Path]::GetFileName($nj.FullName)
            if (Test-SuspiciousNestedJarName -JarName $njName) {
                $flags.Add("Suspicious nested JAR with no version/dependency naming: $njName")
            }
        }
        if ($nestedJars.Count -eq 1 -and $outerClasses.Count -lt 3) {
            $njName = [System.IO.Path]::GetFileName(($nestedJars | Select-Object -First 1).FullName)
            $flags.Add("Hollow shell jar — only $($outerClasses.Count) own class(es), just wraps: $njName")
        }

        # --- fake-mod-identity check ---
        $declaredModId = ""
        $fmj = $zip.Entries | Where-Object { $_.FullName -eq "fabric.mod.json" } | Select-Object -First 1
        if ($fmj) {
            try {
                $sr = New-Object System.IO.StreamReader($fmj.Open())
                $txt = $sr.ReadToEnd()
                $sr.Close()
                if ($txt -match '"id"\s*:\s*"([^"]+)"') { $declaredModId = $matches[1] }
            } catch {}
        }

        $entries = Get-AllZipEntries -ZipArchive $zip

        $totalClass    = 0
        $obfClass      = 0
        $runtimeExec   = $false
        $httpDownload  = $false
        $httpExfil     = $false

        foreach ($entry in $entries) {
            if ($entry.FullName -notmatch '\.class$') { continue }
            $totalClass++

            $segs = ($entry.FullName -replace '\.class$','') -split '/'
            $run = 0; $maxRun = 0
            foreach ($seg in $segs) {
                if ($seg.Length -eq 1) { $run++; if ($run -gt $maxRun) { $maxRun = $run } } else { $run = 0 }
            }
            if ($maxRun -ge 3) { $obfClass++ }

            try {
                $ms = New-Object System.IO.MemoryStream
                $entry.Open().CopyTo($ms)
                $ct = [System.Text.Encoding]::ASCII.GetString($ms.ToArray())
                $ms.Dispose()

                if ($ct -match "java/lang/Runtime" -and $ct -match "getRuntime" -and $ct -match "exec") {
                    $runtimeExec = $true
                }
                if ($ct -match "openConnection" -and $ct -match "HttpURLConnection" -and $ct -match "FileOutputStream") {
                    $httpDownload = $true
                }
                if ($ct -match "openConnection" -and $ct -match "setDoOutput" -and $ct -match "getOutputStream" -and $ct -match "getProperty") {
                    $httpExfil = $true
                }
            } catch {}
        }
        $zip.Dispose()

        $obfPct = if ($totalClass -ge 10) { [math]::Round(($obfClass / $totalClass) * 100) } else { 0 }

        if ($runtimeExec -and $obfPct -ge 25) {
            $flags.Add("Runtime.exec() found inside obfuscated code (arbitrary command execution)")
        }
        if ($httpDownload) { $flags.Add("Fetches and writes files from a remote server at runtime") }
        if ($httpExfil)    { $flags.Add("Sends data to an external server via HTTP POST") }

        $dangerSoFar = $flags.Count -gt 0
        if ($declaredModId -and ($knownLegitModIds -contains $declaredModId.ToLower()) -and $dangerSoFar) {
            $flags.Add("Impersonation — claims mod id '$declaredModId' (a known clean mod) but contains the flags above")
        }
    } catch {}
    return $flags
}

function Check-Jvm {
    $results = [System.Collections.Generic.List[string]]::new()
    $java = Get-Process javaw -ErrorAction SilentlyContinue
    if (-not $java) { $java = Get-Process java -ErrorAction SilentlyContinue }
    if (-not $java) { return $results }

    try {
        $wmi = Get-CimInstance Win32_Process -Filter "ProcessId = $($java[0].Id)" -ErrorAction SilentlyContinue
        if ($wmi.CommandLine) {
            $agents = [regex]::Matches($wmi.CommandLine, '-javaagent:([^\s"]+)')
            $legitAgents = @("jmxremote","yjp","jrebel","newrelic","jacoco","theseus")
            foreach ($a in $agents) {
                $agentPath = $a.Groups[1].Value.Trim('"').Trim("'")
                $agentName = [IO.Path]::GetFileName($agentPath)
                $isLegit = $false
                foreach ($la in $legitAgents) { if ($agentName -match $la) { $isLegit = $true; break } }
                if (-not $isLegit) {
                    $results.Add("Java agent loaded: $agentName (path: $agentPath)")
                }
            }
            if ($wmi.CommandLine -match '-Xbootclasspath') {
                $results.Add("Suspicious bootclasspath modification")
            }
            if ($wmi.CommandLine -match '-agentlib:jdwp') {
                $results.Add("JDWP debug agent active")
            }
            if ($wmi.CommandLine -match '-agentpath:') {
                $results.Add("Native agent loaded (bypasses Java sandbox)")
            }
        }
    } catch {}
    return $results
}

# ---------- Execution ----------
$jars = Get-ChildItem -Path $path -Filter *.jar -ErrorAction SilentlyContinue
if ($jars.Count -eq 0) {
    Write-Host "  No jar files found." -ForegroundColor Yellow
    exit 0
}

Write-Host "  Analyzing $($jars.Count) files..." -ForegroundColor DarkCyan
Write-Host ""

$flagged    = @()
$obfuscated = @()
$bypassed   = @()
$clean      = 0
$i = 0

foreach ($jar in $jars) {
    $i++
    Write-Host "`r  [$i/$($jars.Count)] $($jar.Name)" -NoNewline

    $contentResult = Analyze-Content $jar.FullName
    $structFlags   = Analyze-Structure $jar.FullName
    $bypassFlags   = Analyze-Bypass $jar.FullName

    $hasContentHit = ($contentResult.Signatures.Count -gt 0) -or ($contentResult.Strings.Count -gt 0)

    if ($hasContentHit) {
        $flagged += [PSCustomObject]@{
            Name       = $jar.Name
            Signatures = $contentResult.Signatures
            Strings    = $contentResult.Strings
        }
    }

    if ($bypassFlags.Count -gt 0) {
        $bypassed += [PSCustomObject]@{ Name = $jar.Name; Flags = $bypassFlags }
    }

    if (-not $hasContentHit -and $bypassFlags.Count -eq 0 -and $structFlags.Count -gt 0) {
        $obfuscated += [PSCustomObject]@{ Name = $jar.Name; Flags = $structFlags }
    }

    if (-not $hasContentHit -and $bypassFlags.Count -eq 0 -and $structFlags.Count -eq 0) {
        $clean++
    }
}
Write-Host "`r$(' ' * 70)`r" -NoNewline

$jvmIssues = Check-Jvm

# ============================================================
#  OUTPUT (kept in Magician's Reveal's original plain style)
# ============================================================
Write-Host ""
Write-Host "  Analysis Complete." -ForegroundColor Cyan
Write-Host ""

if ($flagged.Count -eq 0 -and $obfuscated.Count -eq 0 -and $bypassed.Count -eq 0 -and $jvmIssues.Count -eq 0) {
    Write-Host "  No indicators found. All $clean files appear clean." -ForegroundColor Green
}
else {
    if ($flagged.Count -gt 0) {
        Write-Host "  Flagged Files. ($($flagged.Count))" -ForegroundColor Red
        Write-Host ""
        foreach ($f in $flagged) {
            Write-Host "  $($f.Name)" -ForegroundColor Yellow
            if ($f.Signatures.Count -gt 0) {
                Write-Host "  Detected signatures:" -ForegroundColor Red
                foreach ($h in ($f.Signatures | Sort-Object)) {
                    Write-Host "    • $h" -ForegroundColor Red
                }
            }
            if ($f.Strings.Count -gt 0) {
                Write-Host "  Detected strings:" -ForegroundColor DarkYellow
                foreach ($s in ($f.Strings | Sort-Object)) {
                    Write-Host "    • $s" -ForegroundColor DarkYellow
                }
            }
            Write-Host ""
        }
    }

    if ($bypassed.Count -gt 0) {
        Write-Host "  Bypass/Injection Results. ($($bypassed.Count))" -ForegroundColor Magenta
        Write-Host ""
        foreach ($b in $bypassed) {
            Write-Host "  $($b.Name)" -ForegroundColor Yellow
            foreach ($flag in $b.Flags) {
                Write-Host "    > $flag" -ForegroundColor Magenta
            }
            Write-Host ""
        }
    }

    if ($obfuscated.Count -gt 0) {
        Write-Host "  STRUCTURAL ANOMALIES ($($obfuscated.Count))" -ForegroundColor DarkYellow
        Write-Host ""
        foreach ($o in $obfuscated) {
            Write-Host "  $($o.Name)" -ForegroundColor Yellow
            foreach ($flag in $o.Flags) {
                Write-Host "    > $flag" -ForegroundColor DarkYellow
            }
            Write-Host ""
        }
    }

    if ($jvmIssues.Count -gt 0) {
        Write-Host "  RUNTIME OBSERVATIONS" -ForegroundColor Magenta
        Write-Host ""
        foreach ($j in $jvmIssues) {
            Write-Host "    • $j" -ForegroundColor Magenta
        }
        Write-Host ""
    }
}

Write-Host "  Summary"
Write-Host "  Files analyzed : $($jars.Count)"
Write-Host "  Clean          : $clean" -ForegroundColor Green
Write-Host "  Flagged        : $($flagged.Count)" -ForegroundColor Red
Write-Host "  Bypass/Inject  : $($bypassed.Count)" -ForegroundColor Magenta
Write-Host "  Anomalies      : $($obfuscated.Count)" -ForegroundColor Yellow
Write-Host "  Runtime notes  : $($jvmIssues.Count)" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Magician's Reveal v5.1" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
