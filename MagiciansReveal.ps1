# ============================================================
#  MAGICIAN'S REVEAL  v5.0
#  Professional Minecraft Forensic Scanner
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

Write-Host ""
Write-Host "  MAGICIAN'S REVEAL" -ForegroundColor Cyan
Write-Host "  Advanced Client Analysis Engine  •  v5.0" -ForegroundColor DarkGray
Write-Host ""

# -------------------------------------------------------
# 1. Minecraft Process Validation
# -------------------------------------------------------
Write-Host "  Validating environment..." -ForegroundColor Gray

$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) { $mcProcess = Get-Process java -ErrorAction SilentlyContinue }

if (-not $mcProcess) {
    Write-Host ""
    Write-Host "  Minecraft process not found." -ForegroundColor Red
    Write-Host "  This session is INVALID." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$proc      = $mcProcess | Select-Object -First 1
$startTime = $proc.StartTime
$uptime    = (Get-Date) - $startTime

Write-Host "  Minecraft is active" -ForegroundColor Green
Write-Host "  Process : $($proc.Name)   PID : $($proc.Id)" -ForegroundColor DarkGray
Write-Host "  Uptime  : $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor DarkGray
Write-Host ""

# -------------------------------------------------------
# 2. Target Path
# -------------------------------------------------------
Write-Host "  Mods directory (press Enter for default):" -ForegroundColor Gray
$modsPath = Read-Host "  Path"

if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
}

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "  Directory not accessible." -ForegroundColor Red
    exit 1
}

Write-Host "  Target → $modsPath" -ForegroundColor DarkCyan
Write-Host ""

# -------------------------------------------------------
# 3. Indicator Lists (high-signal only)
# -------------------------------------------------------
$featureIndicators = @(
    "AutoCrystal","AutoHitCrystal","AutoAnchor","DoubleAnchor","SafeAnchor","AirAnchor",
    "AutoTotem","InventoryTotem","HoverTotem","LegitTotem","AutoPot","AutoPotRefill","AutoArmor",
    "ShieldBreaker","ShieldDisabler","AutoDoubleHand","AutoMace","MaceSwap","StunSlam","AxeSpam",
    "TriggerBot","AimAssist","SilentAim","SilentRotations","FakeLag","PingSpoof","FakeInv","WTap",
    "AutoWeb","WebMacro","KeyPearl","LootYeeter","AutoFirework","ElytraSwap","FastPlace",
    "PackSpoof","Antiknockback","AuthBypass","obfuscatedAuth","LicenseCheckMixin","BaseFinder",
    "SelfDestruct","HideClient","SessionStealer","TokenLogger","TokenGrabber","DiscordToken",
    "RemoteAccess","ReverseShell","C2Server","Backdoor","KeyLogger","StashFinder","TrailFinder",
    "KillAura","ClickAura","CrystalAura","AnchorAura","BedAura","ReachHack","HitboxExpand",
    "AntiKB","NoKnockback","PlayerESP","XRayHack","ScaffoldWalk","AutoClicker","BowAim","Criticals"
)

$clientSignatures = @(
    "com/slither/cyemer","com/slither/velaris","dev/lvstrng/aidsfuscator",
    "dev.krypton","skid.krypton","dev.virel","orchard","org.chainlibs.module.impl.modules",
    "meteordevelopment","meteorclient","liquidbounce","fdp-client","net.ccbluex",
    "doomsdayclient","novaclient","api.novaclient.lol","vape.gg","vapeclient","VapeLite",
    "intent.store","IntentClient","rise.today","riseclient.com","aristois","impactclient",
    "konas","rusherhack","catlean","Asteria","PrestigeClient","gypsy","XenonClient",
    "dqrkis.xyz","WalksyOptimizer","imgui.gl3","imgui.glfw","jnativehook",
    "phantom-refmap.json","client-refmap.json","cheat-refmap.json",
    "ClientPlayerInteractionManagerAccessor","ClientPlayerEntityMixim",
    "sixtwo/","fivefive/","mixin/accessors"
)

$allIndicators = $featureIndicators + $clientSignatures

# -------------------------------------------------------
# 4. Analysis Engine
# -------------------------------------------------------
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-ContentIndicators {
    param([string]$FilePath)

    $found = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $entries = [System.Collections.Generic.List[object]]::new()

        foreach ($e in $archive.Entries) { $entries.Add($e) }

        # Nested JARs
        foreach ($nested in ($archive.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })) {
            try {
                $ms = New-Object System.IO.MemoryStream
                $nested.Open().CopyTo($ms)
                $ms.Position = 0
                $inner = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                foreach ($ie in $inner.Entries) { $entries.Add($ie) }
                $inner.Dispose()
            } catch {}
        }

        # Entry name scan
        foreach ($entry in $entries) {
            foreach ($ind in $allIndicators) {
                if ($entry.FullName -match [regex]::Escape($ind)) {
                    [void]$found.Add($ind)
                }
            }
            if ($entry.FullName -match 'dev/lvstrng/aidsfuscator') { [void]$found.Add("dev/lvstrng/aidsfuscator") }
            if ($entry.FullName -match 'MixinExperienceOrb')     { [void]$found.Add("MixinExperienceOrb pattern") }
        }

        # Content scan
        foreach ($entry in $entries) {
            if ($entry.FullName -match '\.(class|json)$' -or $entry.FullName -match 'MANIFEST\.MF') {
                try {
                    $ms = New-Object System.IO.MemoryStream
                    $entry.Open().CopyTo($ms)
                    $bytes = $ms.ToArray()
                    $ms.Dispose()

                    $text = [System.Text.Encoding]::UTF8.GetString($bytes) +
                            [System.Text.Encoding]::ASCII.GetString($bytes)

                    foreach ($ind in $allIndicators) {
                        if ($text.Contains($ind)) { [void]$found.Add($ind) }
                    }
                } catch {}
            }
        }
        $archive.Dispose()
    } catch {}

    return $found
}

function Get-StructuralFlags {
    param([string]$FilePath)

    $flags = [System.Collections.Generic.List[string]]::new()

    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $total = 0
        $numeric = 0
        $singleLetter = 0
        $unicode = 0
        $confusion = 0
        $singlePkg = 0

        foreach ($entry in $archive.Entries) {
            if ($entry.FullName -match '\.class$') {
                $total++
                $className = [System.IO.Path]::GetFileNameWithoutExtension(($entry.FullName -split '/')[-1])
                $package   = ($entry.FullName -replace '\.class$','' -split '/')[0]

                if ($className -match '^\d+$')               { $numeric++ }
                if ($className -match '^[a-zA-Z]$')          { $singleLetter++ }
                if ($className -match '[^\x00-\x7F]')        { $unicode++ }
                if ($className -match '^[Il1O0_]+$')         { $confusion++ }
                if ($package.Length -eq 1)                  { $singlePkg++ }
            }
        }
        $archive.Dispose()

        if ($total -lt 8) { return $flags }

        $pct = { param($n) [math]::Round(($n / $total) * 100) }

        if ((& $pct $numeric) -ge 25)      { $flags.Add("Heavy numeric class names — $((& $pct $numeric))%") }
        if ((& $pct $singleLetter) -ge 20) { $flags.Add("Single-letter class names — $((& $pct $singleLetter))%") }
        if ((& $pct $unicode) -ge 15)      { $flags.Add("Unicode / non-ASCII class names — $((& $pct $unicode))%") }
        if ((& $pct $confusion) -ge 10)    { $flags.Add("Confusion-character names (Il1O0/_) — $((& $pct $confusion))%") }
        if ($singlePkg -ge 10)             { $flags.Add("Single-letter package paths (a/b/c style)") }
    } catch {}

    return $flags
}

function Get-JvmObservations {
    $results = [System.Collections.Generic.List[string]]::new()

    $java = Get-Process javaw -ErrorAction SilentlyContinue
    if (-not $java) { $java = Get-Process java -ErrorAction SilentlyContinue }
    if (-not $java) { return $results }

    try {
        $wmi = Get-CimInstance Win32_Process -Filter "ProcessId = $($java[0].Id)" -ErrorAction SilentlyContinue
        if ($wmi -and $wmi.CommandLine) {
            $agentMatches = [regex]::Matches($wmi.CommandLine, '-javaagent:([^\s"]+)')
            foreach ($m in $agentMatches) {
                $agentPath = $m.Groups[1].Value.Trim('"')
                $agentName = [System.IO.Path]::GetFileName($agentPath)
                $results.Add("Java agent loaded → $agentName")
            }
            if ($wmi.CommandLine -match '-Xbootclasspath') {
                $results.Add("Bootclasspath modification detected")
            }
            if ($wmi.CommandLine -match '-agentlib:jdwp') {
                $results.Add("JDWP debug agent is active")
            }
        }
    } catch {}

    return $results
}

# -------------------------------------------------------
# 5. Execution
# -------------------------------------------------------
$jarFiles = Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction SilentlyContinue

if ($jarFiles.Count -eq 0) {
    Write-Host "  No JAR files found." -ForegroundColor Yellow
    exit 0
}

Write-Host "  Found $($jarFiles.Count) files — beginning analysis..." -ForegroundColor DarkCyan
Write-Host ""

$flagged     = @()
$anomalies   = @()
$cleanCount  = 0
$index       = 0

foreach ($jar in $jarFiles) {
    $index++
    Write-Host "`r  [$index/$($jarFiles.Count)] $($jar.Name)" -NoNewline

    $contentHits   = Get-ContentIndicators -FilePath $jar.FullName
    $structFlags   = Get-StructuralFlags   -FilePath $jar.FullName

    if ($contentHits.Count -gt 0) {
        $flagged += [PSCustomObject]@{
            FileName = $jar.Name
            Hits     = $contentHits
        }
    }
    elseif ($structFlags.Count -gt 0) {
        $anomalies += [PSCustomObject]@{
            FileName = $jar.Name
            Flags    = $structFlags
        }
    }
    else {
        $cleanCount++
    }
}
Write-Host "`r$(' ' * 80)`r" -NoNewline

$jvmNotes = Get-JvmObservations

# -------------------------------------------------------
# 6. Report
# -------------------------------------------------------
Write-Host ""
Write-Host "  RESULTS" -ForegroundColor Cyan
Write-Host ""

if ($flagged.Count -eq 0 -and $anomalies.Count -eq 0 -and $jvmNotes.Count -eq 0) {
    Write-Host "  No indicators of concern were found." -ForegroundColor Green
    Write-Host "  $cleanCount files appear clean." -ForegroundColor Green
}
else {
    if ($flagged.Count -gt 0) {
        Write-Host "  FLAGGED  ($($flagged.Count))" -ForegroundColor Red
        Write-Host ""
        foreach ($item in $flagged) {
            Write-Host "  $($item.FileName)" -ForegroundColor Yellow
            Write-Host "  Detected!" -ForegroundColor Red
            foreach ($hit in ($item.Hits | Sort-Object)) {
                Write-Host "    • $hit" -ForegroundColor Red
            }
            Write-Host ""
        }
    }

    if ($anomalies.Count -gt 0) {
        Write-Host "  STRUCTURAL ANOMALIES  ($($anomalies.Count))" -ForegroundColor DarkYellow
        Write-Host ""
        foreach ($item in $anomalies) {
            Write-Host "  $($item.FileName)" -ForegroundColor Yellow
            foreach ($flag in $item.Flags) {
                Write-Host "    > $flag" -ForegroundColor DarkYellow
            }
            Write-Host ""
        }
    }

    if ($jvmNotes.Count -gt 0) {
        Write-Host "  RUNTIME OBSERVATIONS" -ForegroundColor Magenta
        Write-Host ""
        foreach ($note in $jvmNotes) {
            Write-Host "    • $note" -ForegroundColor Magenta
        }
        Write-Host ""
    }
}

Write-Host "  SUMMARY"
Write-Host "  Total files     : $($jarFiles.Count)"
Write-Host "  Clean           : $cleanCount" -ForegroundColor Green
Write-Host "  Flagged         : $($flagged.Count)" -ForegroundColor Red
Write-Host "  Anomalies       : $($anomalies.Count)" -ForegroundColor Yellow
Write-Host "  Runtime notes   : $($jvmNotes.Count)" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Analysis finished — Magician's Reveal v5.0" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
