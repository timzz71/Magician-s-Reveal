# ============================================================
#  MAGICIAN'S REVEAL  v4.0
#  Professional Minecraft Forensic Scanner
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

Write-Host ""
Write-Host "  MAGICIAN'S REVEAL  v4.0" -ForegroundColor Cyan
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

# ---------- Detection lists (high signal only) ----------
$moduleNames = @(
    "AutoCrystal","AutoHitCrystal","AutoAnchor","DoubleAnchor","SafeAnchor","AirAnchor",
    "AutoTotem","InventoryTotem","HoverTotem","AutoPot","AutoPotRefill","AutoArmor",
    "ShieldBreaker","ShieldDisabler","AutoMace","MaceSwap","StunSlam","AxeSpam",
    "TriggerBot","AimAssist","SilentAim","FakeLag","PingSpoof","FakeInv","WTap",
    "KeyPearl","AutoFirework","ElytraSwap","FastPlace","SelfDestruct","KillAura",
    "CrystalAura","AnchorAura","BedAura","ReachHack","HitboxExpand","PlayerESP",
    "XRayHack","ScaffoldWalk","AutoClicker","BowAim","Criticals","NoJumpDelay"
)

$clientSignatures = @(
    "com/slither/cyemer","com/slither/velaris","dev/lvstrng/aidsfuscator",
    "dev.krypton","skid.krypton","dev.virel","orchard","org.chainlibs",
    "meteordevelopment","meteorclient","liquidbounce","fdp-client","net.ccbluex",
    "doomsdayclient","novaclient","vape.gg","vapeclient","intent.store",
    "rise.today","aristois","impactclient","konas","rusherhack","catlean",
    "Asteria","PrestigeClient","gypsy","XenonClient","dqrkis.xyz",
    "WalksyOptimizer","imgui.gl3","jnativehook","phantom-refmap.json",
    "ClientPlayerInteractionManagerAccessor","LicenseCheckMixin","obfuscatedAuth",
    "sixtwo/","fivefive/","mixin/accessors"
)

$allIndicators = $moduleNames + $clientSignatures

# ---------- Core analysis functions ----------
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Analyze-Content {
    param([string]$file)

    $hits = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($file)
        $entries = [System.Collections.Generic.List[object]]::new()
        foreach ($e in $zip.Entries) { $entries.Add($e) }

        # Include nested jars
        foreach ($nested in ($zip.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })) {
            try {
                $ms = New-Object System.IO.MemoryStream
                $nested.Open().CopyTo($ms)
                $ms.Position = 0
                $inner = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                foreach ($ie in $inner.Entries) { $entries.Add($ie) }
                $inner.Dispose()
            } catch {}
        }

        foreach ($entry in $entries) {
            foreach ($sig in $allIndicators) {
                if ($entry.FullName -match [regex]::Escape($sig)) {
                    [void]$hits.Add($sig)
                }
            }
        }

        foreach ($entry in $entries) {
            if ($entry.FullName -match '\.(class|json)$') {
                try {
                    $ms = New-Object System.IO.MemoryStream
                    $entry.Open().CopyTo($ms)
                    $data = [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
                    $ms.Dispose()
                    foreach ($sig in $allIndicators) {
                        if ($data.Contains($sig)) { [void]$hits.Add($sig) }
                    }
                } catch {}
            }
        }
        $zip.Dispose()
    } catch {}
    return $hits
}

function Analyze-Structure {
    param([string]$file)

    $flags = [System.Collections.Generic.List[string]]::new()
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($file)
        $total = 0
        $numeric = 0
        $single = 0
        $unicode = 0
        $confusion = 0
        $singlePkg = 0

        foreach ($e in $zip.Entries) {
            if ($e.FullName -match '\.class$') {
                $total++
                $name = [IO.Path]::GetFileNameWithoutExtension(($e.FullName -split '/')[-1])
                $pkg  = ($e.FullName -replace '\.class$','' -split '/')[0]

                if ($name -match '^\d+$')              { $numeric++ }
                if ($name -match '^[a-zA-Z]$')         { $single++ }
                if ($name -match '[^\x00-\x7F]')       { $unicode++ }
                if ($name -match '^[Il1O0_]+$')        { $confusion++ }
                if ($pkg.Length -eq 1)                { $singlePkg++ }
            }
        }
        $zip.Dispose()

        if ($total -lt 6) { return $flags }

        $p = { param($n) [math]::Round(($n / $total) * 100) }

        if ((& $p $numeric) -ge 20)   { $flags.Add("Numeric class names ($((& $p $numeric))%)") }
        if ((& $p $single) -ge 15)    { $flags.Add("Single-letter class names ($((& $p $single))%)") }
        if ((& $p $unicode) -ge 12)   { $flags.Add("Unicode class names ($((& $p $unicode))%)") }
        if ((& $p $confusion) -ge 8)  { $flags.Add("Confusion characters (Il1O0/_) ($((& $p $confusion))%)") }
        if ($singlePkg -ge 8)         { $flags.Add("Single-letter package structure") }
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
            foreach ($a in $agents) {
                $agentName = [IO.Path]::GetFileName($a.Groups[1].Value)
                $results.Add("Java agent loaded: $agentName")
            }
            if ($wmi.CommandLine -match '-Xbootclasspath') {
                $results.Add("Suspicious bootclasspath modification")
            }
            if ($wmi.CommandLine -match '-agentlib:jdwp') {
                $results.Add("JDWP debug agent active")
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

$flagged = @()
$obfuscated = @()
$clean = 0
$i = 0

foreach ($jar in $jars) {
    $i++
    Write-Host "`r  [$i/$($jars.Count)] $($jar.Name)" -NoNewline

    $contentHits = Analyze-Content $jar.FullName
    $structFlags = Analyze-Structure $jar.FullName

    if ($contentHits.Count -gt 0) {
        $flagged += [PSCustomObject]@{ Name = $jar.Name; Hits = $contentHits }
    }
    elseif ($structFlags.Count -gt 0) {
        $obfuscated += [PSCustomObject]@{ Name = $jar.Name; Flags = $structFlags }
    }
    else {
        $clean++
    }
}
Write-Host "`r$(' ' * 70)`r" -NoNewline

$jvmIssues = Check-Jvm

# ---------- Output ----------
Write-Host ""
Write-Host "  ANALYSIS COMPLETE" -ForegroundColor Cyan
Write-Host ""

if ($flagged.Count -eq 0 -and $obfuscated.Count -eq 0 -and $jvmIssues.Count -eq 0) {
    Write-Host "  No indicators found. All $clean files appear clean." -ForegroundColor Green
}
else {
    if ($flagged.Count -gt 0) {
        Write-Host "  FLAGGED FILES ($($flagged.Count))" -ForegroundColor Red
        Write-Host ""
        foreach ($f in $flagged) {
            Write-Host "  $($f.Name)" -ForegroundColor Yellow
            Write-Host "  Detected:" -ForegroundColor Red
            foreach ($h in ($f.Hits | Sort-Object)) {
                Write-Host "    • $h" -ForegroundColor Red
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
Write-Host "  Anomalies      : $($obfuscated.Count)" -ForegroundColor Yellow
Write-Host "  Runtime notes  : $($jvmIssues.Count)" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Magician's Reveal v4.0" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
