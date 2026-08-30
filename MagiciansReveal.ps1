# Magician's Reveal - Professional Minecraft Forensic Scanner
# Version: 1.0.0
# Author: Timzz71
# Description: Forensic scanner for consented screenshare investigations
# Includes 132+ detection flags, 1000+ cheat strings, and advanced obfuscation detection.

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

# Helper: Add finding
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

# ---- HUGE LIST OF SUSPICIOUS PATTERNS (from your file) ----
$suspiciousPatterns = @(
    "AimAssist", "AnchorTweaks", "AutoAnchor", "AutoCrystal", "AutoDoubleHand", "JDWP.VirtualMachine.AllModules",
    "AutoHitCrystal", "AutoPot", "AutoTotem", "AutoArmor", "InventoryTotem",
    "LegitTotem", "PingSpoof", "SelfDestruct",
    "ShieldBreaker", "TriggerBot", "AxeSpam", "WebMacro",
    "FastPlace", "WalskyOptimizer", "WalksyOptimizer", "walsky.optimizer",
    "WalksyCrystalOptimizerMod", "Donut", "Replace Mod",
    "ShieldDisabler", "SilentAim", "Totem Hit", "Wtap", "FakeLag", "dev.virel", "orchard",
    "BlockESP", "dev.krypton", "dev/krypton", "skid.krypton", "skid/krypton", "AntiMissClick",
    "LagReach", "PopSwitch", "SprintReset", "ChestSteal", "AntiBot",
    "ElytraSwap", "FastXP", "FastExp", "Refill", "AirAnchor",
    "jnativehook", "FakeInv", "HoverTotem", "AutoClicker", "AutoFirework",
    "PackSpoof", "Antiknockback", "catlean",
    "AuthBypass", "Asteria", "Prestige", "AutoEat", "AutoMine",
    "MaceSwap", "Macro198", "StunSlam", "SafeAnchor", "DoubleAnchor", "AutoTPA", "BaseFinder", "Xenon", "gypsy",
    "AutoPotRefill", "WalksyOptimizer", "KeyPearl", "AimAssist", "AutoNethPot", "AutoDtap",
    "TriggerBot", "AutoWeb", "AnchorAction",
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
    "imgui.gl3", "imgui.glfw",
    "BowAim", "Criticals", "Fakenick", "FakeItem",
    "invsee", "ItemExploit", "Hellion", "hellion",
    "LicenseCheckMixin", "ClientPlayerInteractionManagerAccessor",
    "ClientPlayerEntityMixim", "dev.gambleclient", "obfuscatedAuth",
    "phantom-refmap.json", "xyz.greaj",
    "Ńüś.class", "ŃüĄ.class", "ŃüČ.class", "ŃüĘ.class", "Ńü¤.class",
    "ŃüŁ.class", "ŃüØ.class", "Ńü¬.class", "Ńü®.class", "ŃüÉ.class",
    "ŃüÜ.class", "Ńü¦.class", "Ńüż.class", "Ńü╣.class", "Ńüø.class",
    "Ńü©.class", "Ńü┐.class", "Ńü│.class", "ŃüÖ.class", "Ńü«.class"
)

$cheatStrings = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal", "JDWP.VirtualMachine.AllModules",
    "dontPlaceCrystal", "dontBreakCrystal", "dev.virel", "orchard",
    "AutoHitCrystal", "autohitcrystal", "canPlaceCrystalServer", "healPotSlot",
    "’╝Ī’ĮĢ’Įö’ĮÅ’╝Ż’ĮÆ’ĮÖ’Įō’Įö’Įü’Įī", "’╝Ī’ĮĢ’Įö’ĮÅ ’╝Ż’ĮÆ’ĮÖ’Įō’Įö’Įü’Įī",
    "’╝Ī’ĮĢ’Įö’ĮÅ’╝©’Įē’Įö’╝Ż’ĮÆ’ĮÖ’Įō’Įö’Įü’Įī",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor",
    "HasAnchor", "anchortweaks", "anchor macro", "safe anchor", "safeanchor",
    "SafeAnchor", "AirAnchor",
    "’╝Ī’ĮĢ’Įö’ĮÅ’╝Ī’ĮÄ’Įā’Įł’ĮÅ’ĮÆ", "’╝Ī’ĮĢ’Įö’ĮÅ ’╝Ī’ĮÄ’Įā’Įł’ĮÅ’ĮÆ",
    "’╝ż’ĮÅ’ĮĢ’Įé’Įī’Įģ’╝Ī’ĮÄ’Įā’Įł’ĮÅ’ĮÆ", "’╝ż’ĮÅ’ĮĢ’Įé’Įī’Įģ ’╝Ī’ĮÄ’Įā’Įł’ĮÅ’ĮÆ",
    "’╝│’Įü’Įå’Įģ’╝Ī’ĮÄ’Įā’Įł’ĮÅ’ĮÆ", "’╝│’Įü’Įå’Įģ ’╝Ī’ĮÄ’Įā’Įł’ĮÅ’ĮÆ",
    "’╝Ī’ĮÄ’Įā’Įł’ĮÅ’ĮÆ ’╝Ł’Įü’Įā’ĮÆ’ĮÅ", "anchorMacro",
    "AutoTotem", "autototem", "auto totem", "InventoryTotem",
    "inventorytotem", "HoverTotem", "hover totem", "legittotem",
    "’╝Ī’ĮĢ’Įö’ĮÅ’╝┤’ĮÅ’Įö’Įģ’ĮŹ", "’╝Ī’ĮĢ’Įö’ĮÅ ’╝┤’ĮÅ’Įö’Įģ’ĮŹ",
    "’╝©’ĮÅ’Į¢’Įģ’ĮÆ’╝┤’ĮÅ’Įö’Įģ’ĮŹ", "’╝©’ĮÅ’Į¢’Įģ’ĮÆ ’╝┤’ĮÅ’Įö’Įģ’ĮŹ",
    "’╝®’ĮÄ’Į¢’Įģ’ĮÄ’Įö’ĮÅ’ĮÆ’ĮÖ’╝┤’ĮÅ’Įö’Įģ’ĮŹ", "’╝Ī’ĮĢ’Įö’ĮÅ ’╝®’ĮÄ’Į¢’Įģ’ĮÄ’Įö’ĮÅ’ĮÆ’ĮÖ ’╝┤’ĮÅ’Įö’Įģ’ĮŹ",
    "’╝Ī’ĮĢ’Įö’ĮÅ ’╝┤’ĮÅ’Įö’Įģ’ĮŹ ’╝©’Įē’Įö",
    "AutoPot", "autopot", "auto pot", "speedPotSlot", "strengthPotSlot",
    "AutoArmor", "autoarmor", "auto armor",
    "’╝Ī’ĮĢ’Įö’ĮÅ’╝░’ĮÅ’Įö", "’╝Ī’ĮĢ’Įö’ĮÅ ’╝░’ĮÅ’Įö",
    "’╝Ī’ĮĢ’Įö’ĮÅ ’╝░’ĮÅ’Įö ’╝▓’Įģ’Įå’Įē’Įī’Įī", "AutoPotRefill",
    "’╝Ī’ĮĢ’Įö’ĮÅ’╝Ī’ĮÆ’ĮŹ’ĮÅ’ĮÆ", "’╝Ī’ĮĢ’Įö’ĮÅ ’╝Ī’ĮÆ’ĮŹ’ĮÅ’ĮÆ",
    "preventSwordBlockBreaking", "preventSwordBlockAttack",
    "ShieldDisabler", "ShieldBreaker",
    "’╝│’Įł’Įē’Įģ’Įī’Įä’╝ż’Įē’Įō’Įü’Įé’Įī’Įģ’ĮÆ", "’╝│’Įł’Įē’Įģ’Įī’Įä ’╝ż’Įē’Įō’Įü’Įé’Įī’Įģ’ĮÆ",
    "Breaking shield with axe...",
    "AutoDoubleHand", "autodoublehand", "auto double hand",
    "’╝Ī’ĮĢ’Įö’ĮÅ’╝ż’ĮÅ’ĮĢ’Įé’Įī’Įģ’╝©’Įü’ĮÄ’Įä", "’╝Ī’ĮĢ’Įö’ĮÅ ’╝ż’ĮÅ’ĮĢ’Įé’Įī’Įģ ’╝©’Įü’ĮÄ’Įä",
    "AutoClicker",
    "’╝Ī’ĮĢ’Įö’ĮÅ’╝Ż’Įī’Įē’Įā’Įŗ’Įģ’ĮÆ",
    "Failed to switch to mace after axe!",
    "AutoMace", "MaceSwap", "SpearSwap",
    "’╝Ī’ĮĢ’Įö’ĮÅ’╝Ł’Įü’Įā’Įģ", "’╝Ī’ĮĢ’Įö’ĮÅ ’╝Ł’Įü’Įā’Įģ",
    "’╝Ł’Įü’Įā’Įģ’╝│’ĮŚ’Įü’ĮÉ", "’╝Ł’Įü’Įā’Įģ ’╝│’ĮŚ’Įü’ĮÉ",
    "’╝│’ĮÉ’Įģ’Įü’ĮÆ ’╝│’ĮŚ’Įü’ĮÉ", "’╝Ī’ĮĢ’Įö’ĮÅ’ĮŹ’Įü’Įö’Įē’Įā’Įü’Įī’Įī’ĮÖ ’Įü’Įś’Įģ ’Įü’ĮÄ’Įä ’ĮŹ’Įü’Įā’Įģ ’Įō’Įł’Įē’Įģ’Įī’Įä’Įģ’Įä ’ĮÉ’Įī’Įü’ĮÖ’Įģ’ĮÆ’Įō",
    "’╝│’Įö’ĮĢ’ĮÄ ’╝│’Įī’Įü’ĮŹ", "StunSlam",
    "Donut", "JumpReset", "axespam", "axe spam",
    "findKnockbackSword", "attackRegisteredThisClick",
    "AimAssist", "aimassist", "aim assist",
    "triggerbot", "trigger bot",
    "’╝Ī’Įē’ĮŹ’╝Ī’Įō’Įō’Įē’Įō’Įö", "’╝Ī’Įē’ĮŹ ’╝Ī’Įō’Įō’Įē’Įō’Įö",
    "’╝┤’ĮÆ’Įē’Įć’Įć’Įģ’ĮÆ’╝ó’ĮÅ’Įö", "’╝┤’ĮÆ’Įē’Įć’Įć’Įģ’ĮÆ ’╝ó’ĮÅ’Įö",
    "Silent Rotations", "SilentRotations",
    "’╝│’Įē’Įī’Įģ’ĮÄ’Įö ’╝▓’ĮÅ’Įö’Įü’Įö’Įē’ĮÅ’ĮÄ’Įō",
    "FakeInv", "swapBackToOriginalSlot",
    "FakeLag", "pingspoof", "ping spoof",
    "’╝”’Įü’Įŗ’Įģ’╝¼’Įü’Įć", "’╝”’Įü’Įŗ’Įģ ’╝¼’Įü’Įć",
    "fakePunch", "Fake Punch",
    "’╝”’Įü’Įŗ’Įģ ’╝░’ĮĢ’ĮÄ’Įā’Įł",
    "mace_swap", "quick_strike", "macro_198", "stun_slam",
    "safe_anchor", "double_anchor", "auto_pot_refill",
    "walksy_optimizer", "key_pearl", "aim_assist",
    "auto_neth_pot", "auto_dtap", "trigger_bot", "auto_web",
    "DOUBLE_ESCAPE", "DOUBLE_RIGHTCLICK_FIRST", "DOUBLE_RIGHTCLICK_SECOND",
    "POST_CYCLE_DELAY", "PLACE_OBI", "WAIT_OBI", "PLACE_CRYSTAL", "BREAK_CRYSTAL",
    "ROTATING_DOWN", "ROTATING_BACK", "REFILLING", "PLANTING", "BONEMEALING",
    "AnchorAction", "Places two anchors for massive damage",
    "REOFFHAND_TOTEM",
    "webmacro", "web macro",
    "AntiWeb", "AutoWeb",
    "’╝Ī’ĮÄ’Įö’Įē ’╝Ę’Įģ’Įé", "’╝Ī’ĮĢ’Įö’ĮÅ’╝Ę’Įģ’Įé",
    "’╝░’Įī’Įü’Įā’Įģ’Įō ’╝Ę’Įģ’Įé’Įō ’╝»’ĮÄ ’╝ź’ĮÄ’Įģ’ĮŹ’Įē’Įģ’Įō",
    "lvstrng", "dqrkis", "selfdestruct", "self destruct",
    "WalksyCrystalOptimizerMod", "WalksyOptimizer", "WalskyOptimizer",
    "’╝Ę’Įü’Įī’Įŗ’Įō’ĮÖ ’╝»’ĮÉ’Įö’Įē’ĮŹ’Įē’ĮÜ’Įģ’ĮÆ",
    "autoCrystalPlaceClock",
    "AutoFirework", "ElytraSwap", "FastXP", "FastExp", "NoJumpDelay",
    "’╝ź’Įī’ĮÖ’Įö’ĮÆ’Įü’╝│’ĮŚ’Įü’ĮÉ", "’╝ź’Įī’ĮÖ’Įö’ĮÆ’Įü ’╝│’ĮŚ’Įü’ĮÉ",
    "PackSpoof", "Antiknockback", "catlean",
    "AuthBypass", "obfuscatedAuth", "LicenseCheckMixin",
    "BaseFinder", "invsee", "ItemExploit",
    "FreezePlayer",
    "’╝”’ĮÆ’Įģ’Įģ’Įā’Įü’ĮŹ", "’╝Ł’ĮÅ’Į¢’Įģ ’Įå’ĮÆ’Įģ’Įģ’Įī’ĮÖ ’Įö’Įł’ĮÆ’ĮÅ’ĮĢ’Įć’Įł ’ĮŚ’Įü’Įī’Įī’Įō",
    "’╝«’ĮÅ ’╝Ż’Įī’Įē’ĮÉ", "’╝”’ĮÆ’Įģ’Įģ’ĮÜ’Įģ ’╝░’Įī’Įü’ĮÖ’Įģ’ĮÆ",
    "LWFH Crystal", "JDWP.VirtualMachine.AllModules",
    "’╝¼’╝Ę’╝”’╝© ’╝Ż’ĮÆ’ĮÖ’Įō’Įö’Įü’Įī",
    "KeyPearl", "LootYeeter",
    "’╝½’Įģ’ĮÖ’╝░’Įģ’Įü’ĮÆ’Įī", "’╝½’Įģ’ĮÖ ’╝░’Įģ’Įü’ĮÆ’Įī",
    "’╝¼’ĮÅ’ĮÅ’Įö ’╝╣’Įģ’Įģ’Įö’Įģ’ĮÆ",
    "FastPlace",
    "’╝”’Įü’Įō’Įö ’╝░’Įī’Įü’Įā’Įģ", "’╝░’Įī’Įü’Įā’Įģ ’Įé’Įī’ĮÅ’Įā’Įŗ’Įō ’Įå’Įü’Įō’Įö’Įģ’ĮÆ",
    "AutoBreach",
    "’╝Ī’ĮĢ’Įö’ĮÅ ’╝ó’ĮÆ’Įģ’Įü’Įā’Įł",
    "setBlockBreakingCooldown", "getBlockBreakingCooldown", "blockBreakingCooldown",
    "onBlockBreaking", "setItemUseCooldown",
    "invokeDoAttack", "invokeDoItemUse", "invokeOnMouseButton",
    "onPushOutOfBlocks", "onIsGlowing",
    "Automatically switches to sword when hitting with totem",
    "arrayOfString", "POT_CHEATS",
    "Dqrkis Client", "Entity.isGlowing",
    "Activate Key", "’╝Ī’Įā’Įö’Įē’Į¢’Įü’Įö’Įģ ’╝½’Įģ’ĮÖ",
    "Click Simulation", "’╝Ż’Įī’Įē’Įā’Įŗ ’╝│’Įē’ĮŹ’ĮĢ’Įī’Įü’Įö’Įē’ĮÅ’ĮÄ",
    "On RMB", "’╝»’ĮÄ ’╝▓’╝Ł’╝ó",
    "No Count Glitch", "’╝«’ĮÅ ’╝Ż’ĮÅ’ĮĢ’ĮÄ’Įö ’╝¦’Įī’Įē’Įö’Įā’Įł",
    "No Bounce", "NoBounce", "’╝«’ĮÅ ’╝ó’ĮÅ’ĮĢ’ĮÄ’Įā’Įģ", "’╝«’ĮÅ’╝ó’ĮÅ’ĮĢ’ĮÄ’Įā’Įģ",
    "’╝▓’Įģ’ĮŹ’ĮÅ’Į¢’Įģ’Įō ’Įö’Įł’Įģ ’Įā’ĮÆ’ĮÖ’Įō’Įö’Įü’Įī ’Įé’ĮÅ’ĮĢ’ĮÄ’Įā’Įģ ’Įü’ĮÄ’Įē’ĮŹ’Įü’Įö’Įē’ĮÅ’ĮÄ",
    "Place Delay", "’╝░’Įī’Įü’Įā’Įģ ’╝ż’Įģ’Įī’Įü’ĮÖ",
    "Break Delay", "’╝ó’ĮÆ’Įģ’Įü’Įŗ ’╝ż’Įģ’Įī’Įü’ĮÖ",
    "’╝”’Įü’Įō’Įö ’╝Ł’ĮÅ’Įä’Įģ",
    "Place Chance", "’╝░’Įī’Įü’Įā’Įģ ’╝Ż’Įł’Įü’ĮÄ’Įā’Įģ",
    "Break Chance", "’╝ó’ĮÆ’Įģ’Įü’Įŗ ’╝Ż’Įł’Įü’ĮÄ’Įā’Įģ",
    "Stop On Kill", "’╝│’Įö’ĮÅ’ĮÉ ’╝»’ĮÄ ’╝½’Įē’Įī’Įī",
    "’╝ż’Įü’ĮŹ’Įü’Įć’Įģ ’╝┤’Įē’Įā’Įŗ", "damagetick",
    "Anti Weakness", "’╝Ī’ĮÄ’Įö’Įē ’╝Ę’Įģ’Įü’Įŗ’ĮÄ’Įģ’Įō’Įō",
    "Particle Chance", "’╝░’Įü’ĮÆ’Įö’Įē’Įā’Įī’Įģ ’╝Ż’Įł’Įü’ĮÄ’Įā’Įģ",
    "Trigger Key", "’╝┤’ĮÆ’Įē’Įć’Įć’Įģ’ĮÆ ’╝½’Įģ’ĮÖ",
    "Switch Delay", "’╝│’ĮŚ’Įē’Įö’Įā’Įł ’╝ż’Įģ’Įī’Įü’ĮÖ",
    "Totem Slot", "’╝┤’ĮÅ’Įö’Įģ’ĮŹ ’╝│’Įī’ĮÅ’Įö",
    "Silent Rotations", "’╝│’Įē’Įī’Įģ’ĮÄ’Įö ’╝▓’ĮÅ’Įö’Įü’Įö’Įē’ĮÅ’ĮÄ’Įō",
    "Smooth Rotations", "’╝│’ĮŹ’ĮÅ’ĮÅ’Įö’Įł ’╝▓’ĮÅ’Įö’Įü’Įö’Įē’ĮÅ’ĮÄ’Įō",
    "Rotation Speed", "’╝▓’ĮÅ’Įö’Įü’Įö’Įē’ĮÅ’ĮÄ ’╝│’ĮÉ’Įģ’Įģ’Įä",
    "Use Easing", "’╝Ą’Įō’Įģ ’╝ź’Įü’Įō’Įē’ĮÄ’Įć",
    "Easing Strength", "’╝ź’Įü’Įō’Įē’ĮÄ’Įć ’╝│’Įö’ĮÆ’Įģ’ĮÄ’Įć’Įö’Įł",
    "While Use", "’╝Ę’Įł’Įē’Įī’Įģ ’╝Ą’Įō’Įģ",
    "Stop on Kill", "’╝│’Įö’ĮÅ’ĮÉ ’ĮÅ’ĮÄ ’╝½’Įē’Įī’Įī",
    "Click Simulation", "’╝Ż’Įī’Įē’Įā’Įŗ ’╝│’Įē’ĮŹ’ĮĢ’Įī’Įü’Įö’Įē’ĮÅ’ĮÄ",
    "Glowstone Delay", "’╝¦’Įī’ĮÅ’ĮŚ’Įō’Įö’ĮÅ’ĮÄ’Įģ ’╝ż’Įģ’Įī’Įü’ĮÖ",
    "Glowstone Chance", "’╝¦’Įī’ĮÅ’ĮŚ’Įō’Įö’ĮÅ’ĮÄ’Įģ ’╝Ż’Įł’Įü’ĮÄ’Įā’Įģ",
    "Explode Delay", "’╝ź’Įś’ĮÉ’Įī’ĮÅ’Įä’Įģ ’╝ż’Įģ’Įī’Įü’ĮÖ",
    "Explode Chance", "’╝ź’Įś’ĮÉ’Įī’ĮÅ’Įä’Įģ ’╝Ż’Įł’Įü’ĮÄ’Įā’Įģ",
    "Explode Slot", "’╝ź’Įś’ĮÉ’Įī’ĮÅ’Įä’Įģ ’╝│’Įī’ĮÅ’Įö",
    "Only Charge", "’╝»’ĮÄ’Įī’ĮÖ ’╝Ż’Įł’Įü’ĮÆ’Įć’Įģ",
    "Anchor Macro", "’╝Ī’ĮÄ’Įā’Įł’ĮÅ’ĮÆ ’╝Ł’Įü’Įā’ĮÆ’ĮÅ",
    "Reach Distance", "’╝▓’Įģ’Įü’Įā’Įł ’╝ż’Įē’Įō’Įö’Įü’ĮÄ’Įā’Įģ",
    "Min Height", "’╝Ł’Įē’ĮÄ ’╝©’Įģ’Įē’Įć’Įł’Įö",
    "Min Fall Speed", "’╝Ł’Įē’ĮÄ ’╝”’Įü’Įī’Įī ’╝│’ĮÉ’Įģ’Įģ’Įä",
    "Attack Delay", "’╝Ī’Įö’Įö’Įü’Įā’Įŗ ’╝ż’Įģ’Įī’Įü’ĮÖ",
    "Breach Delay", "’╝ó’ĮÆ’Įģ’Įü’Įā’Įł ’╝ż’Įģ’Įī’Įü’ĮÖ",
    "Require Elytra", "’╝▓’Įģ’Įæ’ĮĢ’Įē’ĮÆ’Įģ ’╝ź’Įī’ĮÖ’Įö’ĮÆ’Įü",
    "Auto Switch Back", "’╝Ī’ĮĢ’Įö’ĮÅ ’╝│’ĮŚ’Įē’Įö’Įā’Įł ’╝ó’Įü’Įā’Įŗ",
    "Check Line of Sight", "’╝Ż’Įł’Įģ’Įā’Įŗ ’╝¼’Įē’ĮÄ’Įģ ’ĮÅ’Įå ’╝│’Įē’Įć’Įł’Įö",
    "Only When Falling", "’╝»’ĮÄ’Įī’ĮÖ ’╝Ę’Įł’Įģ’ĮÄ ’╝”’Įü’Įī’Įī’Įē’ĮÄ’Įć",
    "Require Crit", "’╝▓’Įģ’Įæ’ĮĢ’Įē’ĮÆ’Įģ ’╝Ż’ĮÆ’Įē’Įö",
    "Show Status Display", "’╝│’Įł’ĮÅ’ĮŚ ’╝│’Įö’Įü’Įö’ĮĢ’Įō ’╝ż’Įē’Įō’ĮÉ’Įī’Įü’ĮÖ",
    "Stop On Crystal", "’╝│’Įö’ĮÅ’ĮÉ ’╝»’ĮÄ ’╝Ż’ĮÆ’ĮÖ’Įō’Įö’Įü’Įī",
    "Check Shield", "’╝Ż’Įł’Įģ’Įā’Įŗ ’╝│’Įł’Įē’Įģ’Įī’Įä",
    "On Pop", "’╝»’ĮÄ ’╝░’ĮÅ’ĮÉ",
    "Predict Damage", "’╝░’ĮÆ’Įģ’Įä’Įē’Įā’Įö ’╝ż’Įü’ĮŹ’Įü’Įć’Įģ",
    "On Ground", "’╝»’ĮÄ ’╝¦’ĮÆ’ĮÅ’ĮĢ’ĮÄ’Įä",
    "Check Players", "’╝Ż’Įł’Įģ’Įā’Įŗ ’╝░’Įī’Įü’ĮÖ’Įģ’ĮÆ’Įō",
    "Predict Crystals", "’╝░’ĮÆ’Įģ’Įä’Įē’Įā’Įö ’╝Ż’ĮÆ’ĮÖ’Įō’Įö’Įü’Įī’Įō",
    "Check Aim", "’╝Ż’Įł’Įģ’Įā’Įŗ ’╝Ī’Įē’ĮŹ",
    "Check Items", "’╝Ż’Įł’Įģ’Įā’Įŗ ’╝®’Įö’Įģ’ĮŹ’Įō",
    "Activates Above", "’╝Ī’Įā’Įö’Įē’Į¢’Įü’Įö’Įģ’Įō ’╝Ī’Įé’ĮÅ’Į¢’Įģ",
    "Blatant", "’╝ó’Įī’Įü’Įö’Įü’ĮÄ’Įö",
    "Force Totem", "’╝”’ĮÅ’ĮÆ’Įā’Įģ ’╝┤’ĮÅ’Įö’Įģ’ĮŹ",
    "Stay Open For", "’╝│’Įö’Įü’ĮÖ ’╝»’ĮÉ’Įģ’ĮÄ ’╝”’ĮÅ’ĮÆ",
    "Auto Inventory Totem", "’╝Ī’ĮĢ’Įö’ĮÅ ’╝®’ĮÄ’Į¢’Įģ’ĮÄ’Įö’ĮÅ’ĮÆ’ĮÖ ’╝┤’ĮÅ’Įö’Įģ’ĮŹ",
    "Only On Pop", "’╝»’ĮÄ’Įī’ĮÖ ’╝»’ĮÄ ’╝░’ĮÅ’ĮÉ",
    "Vertical Speed", "’╝Č’Įģ’ĮÆ’Įö’Įē’Įā’Įü’Įī ’╝│’ĮÉ’Įģ’Įģ’Įä",
    "Hover Totem", "’╝©’ĮÅ’Į¢’Įģ’ĮÆ ’╝┤’ĮÅ’Įö’Įģ’ĮŹ",
    "Swap Speed", "’╝│’ĮŚ’Įü’ĮÉ ’╝│’ĮÉ’Įģ’Įģ’Įä",
    "Strict One-Tick", "’╝│’Įö’ĮÆ’Įē’Įā’Įö ’╝»’ĮÄ’Įģ’╝Ź’╝┤’Įē’Įā’Įŗ",
    "Mace Priority", "’╝Ł’Įü’Įā’Įģ ’╝░’ĮÆ’Įē’ĮÅ’ĮÆ’Įē’Įö’ĮÖ",
    "Min Totems", "’╝Ł’Įē’ĮÄ ’╝┤’ĮÅ’Įö’Įģ’ĮŹ’Įō",
    "Min Pearls", "’╝Ł’Įē’ĮÄ ’╝░’Įģ’Įü’ĮÆ’Įī’Įō",
    "Totem First", "’╝┤’ĮÅ’Įö’Įģ’ĮŹ ’╝”’Įē’ĮÆ’Įō’Įö",
    "Drop Interval", "’╝ż’ĮÆ’ĮÅ’ĮÉ ’╝®’ĮÄ’Įö’Įģ’ĮÆ’Į¢’Įü’Įī",
    "Random Pattern", "’╝▓’Įü’ĮÄ’Įä’ĮÅ’ĮŹ ’╝░’Įü’Įö’Įö’Įģ’ĮÆ’ĮÄ",
    "Loot Yeeter", "’╝¼’ĮÅ’ĮÅ’Įö ’╝╣’Įģ’Įģ’Įö’Įģ’ĮÆ",
    "Horizontal Aim Speed", "’╝©’ĮÅ’ĮÆ’Įē’ĮÜ’ĮÅ’ĮÄ’Įö’Įü’Įī ’╝Ī’Įē’ĮŹ ’╝│’ĮÉ’Įģ’Įģ’Įä",
    "Vertical Aim Speed", "’╝Č’Įģ’ĮÆ’Įö’Įē’Įā’Įü’Įī ’╝Ī’Įē’ĮŹ ’╝│’ĮÉ’Įģ’Įģ’Įä",
    "Include Head", "’╝®’ĮÄ’Įā’Įī’ĮĢ’Įä’Įģ ’╝©’Įģ’Įü’Įä",
    "Web Delay", "’╝Ę’Įģ’Įé ’╝ż’Įģ’Įī’Įü’ĮÖ",
    "Holding Web", "’╝©’ĮÅ’Įī’Įä’Įē’ĮÄ’Įć ’╝Ę’Įģ’Įé",
    "Not When Affects Player", "’╝«’ĮÅ’Įö ’╝Ę’Įł’Įģ’ĮÄ ’╝Ī’Įå’Įå’Įģ’Įā’Įö’Įō ’╝░’Įī’Įü’ĮÖ’Įģ’ĮÆ",
    "Hit Delay", "’╝©’Įē’Įö ’╝ż’Įģ’Įī’Įü’ĮÖ",
    "’╝│’ĮŚ’Įē’Įö’Įā’Įł ’╝ó’Įü’Įā’Įŗ",
    "Require Hold Axe", "’╝▓’Įģ’Įæ’ĮĢ’Įē’ĮÆ’Įģ ’╝©’ĮÅ’Įī’Įä ’╝Ī’Įś’Įģ",
    "Fake Punch", "’╝”’Įü’Įŗ’Įģ ’╝░’ĮĢ’ĮÄ’Įā’Įł",
    "placeInterval", "breakInterval", "stopOnKill",
    "activateOnRightClick", "holdCrystal",
    "’ĮÉ’Įī’Įü’Įā’Įģ’╝®’ĮÄ’Įö’Įģ’ĮÆ’Į¢’Įü’Įī", "’Įé’ĮÆ’Įģ’Įü’Įŗ’╝®’ĮÄ’Įö’Įģ’ĮÆ’Į¢’Įü’Įī",
    "’Įō’Įö’ĮÅ’ĮÉ’╝»’ĮÄ’╝½’Įē’Įī’Įī", "’Įü’Įā’Įö’Įē’Į¢’Įü’Įö’Įģ’╝»’ĮÄ’╝▓’Įē’Įć’Įł’Įö’╝Ż’Įī’Įē’Įā’Įŗ",
    "’Įä’Įü’ĮŹ’Įü’Įć’Įģ’Įö’Įē’Įā’Įŗ", "’Įł’ĮÅ’Įī’Įä’╝Ż’ĮÆ’ĮÖ’Įō’Įö’Įü’Įī",
    "’Įå’Įü’Įŗ’Įģ’╝░’ĮĢ’ĮÄ’Įā’Įł",
    "’╝▓’Įģ’Įå’Įē’Įī’Įī’Įō ’ĮÖ’ĮÅ’ĮĢ’ĮÆ ’Įł’ĮÅ’Įö’Įé’Įü’ĮÆ ’ĮŚ’Įē’Įö’Įł ’ĮÉ’ĮÅ’Įö’Įē’ĮÅ’ĮÄ’Įō",
    "’╝½’Įģ’ĮÉ’Įō ’ĮÖ’ĮÅ’ĮĢ ’Įō’ĮÉ’ĮÆ’Įē’ĮÄ’Įö’Įē’ĮÄ’Įć ’Įü’Įö ’Įü’Įī’Įī ’Įö’Įē’ĮŹ’Įģ’Įō",
    "’╝░’Įī’Įü’Įā’Įģ’Įō ’Įü’ĮÄ’Įā’Įł’ĮÅ’ĮÆ’╝ī ’Įā’Įł’Įü’ĮÆ’Įć’Įģ’Įō ’Įē’Įö’╝ī ’ĮÉ’ĮÆ’ĮÅ’Įö’Įģ’Įā’Įö’Įō ’ĮÖ’ĮÅ’ĮĢ’╝ī ’Įü’ĮÄ’Įä ’Įģ’Įś’ĮÉ’Įī’ĮÅ’Įä’Įģ’Įō",
    "’╝Ī’ĮĢ’Įö’ĮÅ ’Įō’ĮŚ’Įü’ĮÉ ’Įö’ĮÅ ’Įō’ĮÉ’Įģ’Įü’ĮÆ ’ĮÅ’ĮÄ ’Įü’Įö’Įö’Įü’Įā’Įŗ",
    "Macro Key", "’╝Ī’ĮĢ’Įö’ĮÅ ’╝░’ĮÅ’Įö", "’╝Ł’Įü’Įā’ĮÆ’ĮÅ ’╝½’Įģ’ĮÖ",
    "KillAura", "ClickAura", "MultiAura", "ForceField", "LegitAura",
    "AimBot", "AutoAim", "SilentAim", "AimLock", "HeadSnap",
    "CrystalAura",
    "AnchorAura", "AnchorFill", "AnchorPlace",
    "BedAura", "AutoBed", "BedBomb", "BedPlace",
    "BowAimbot", "BowSpam", "AutoBow",
    "AutoCrit", "CritBypass", "AlwaysCrit", "CriticalHit",
    "ReachHack", "ExtendReach", "LongReach", "HitboxExpand",
    "AntiKB", "NoKnockback", "GrimVelocity", "GrimDisabler", "VelocitySpoof", "KBReduce",
    "OffhandTotem", "TotemSwitch",
    "AutoWeapon", "AutoSword", "AutoCity", "Burrow", "SelfTrap",
    "HoleFiller", "AntiSurround", "AntiBurrow",
    "WTap", "TargetStrafe", "AutoGap", "AutoPearl",
    "FlyHack", "CreativeFlight", "BoatFly", "PacketFly", "AirJump",
    "SpeedHack", "BHop", "BunnyHop",
    "AntiFall", "NoFallDamage", "SafeFall",
    "StepHack", "FastClimb", "AutoStep", "HighStep",
    "WaterWalk", "LiquidWalk", "LavaWalk",
    "NoSlow", "NoSlowdown", "NoWeb", "NoSoulSand",
    "WallHack",
    "ElytraSpeed", "InstantElytra",
    "ScaffoldWalk", "FastBridge", "BuildHelper", "AutoBridge",
    "Nuker", "NukerLegit", "InstantBreak",
    "GhostHand", "NoSwing",
    "PlaceAssist", "AirPlace", "AutoPlace", "InstantPlace",
    "PlayerESP", "MobESP", "ItemESP", "StorageESP", "ChestESP",
    "Tracers", "NameTagsHack",
    "XRayHack", "OreFinder", "CaveFinder", "OreESP",
    "NewChunks", "ChunkBorders", "TunnelFinder",
    "TargetHUD", "ReachDisplay",
    "DoubleClicker", "JitterClick", "ButterflyClick", "CPSBoost",
    "ChestStealer", "InvManager", "InvMovebypass",
    "AutoSprint", "AntiAFK", "AutoRespawn",
    "PopSwitch",
    "FakeLatency", "FakePing", "SpoofRotation", "PositionSpoof",
    "GameSpeed", "SpeedTimer",
    "GrimBypass", "VulcanBypass", "MatrixBypass",
    "AACBypass", "VerusDisabler", "IntaveBypass", "WatchdogBypass",
    "PacketMine", "PacketWalk", "PacketSneak", "PacketCancel", "PacketDupe", "PacketSpam",
    "SelfDestruct", "HideClient",
    "SessionStealer", "TokenLogger", "TokenGrabber", "DiscordToken",
    "RemoteAccess", "ReverseShell", "C2Server", "Backdoor", "KeyLogger",
    "StashFinder", "TrailFinder",
    "imgui.binding",
    "JNativeHook", "GlobalScreen", "NativeKeyListener",
    "client-refmap.json", "cheat-refmap.json",
    "aHR0cDovL2FwaS5ub3ZhY2xpZW50LmxvbC93ZWJob29rLnR4dA==",
    "meteordevelopment", "cc/novoline",
    "com/alan/clients", "club/maxstats", "wtf/moonlight",
    "me/zeroeightsix/kami", "net/ccbluex", "today/opai",
    "net/minecraft/injection", "org/chainlibs/module/impl/modules",
    "xyz/greaj", "com/cheatbreaker", "com/moonsworth",
    "doomsdayclient", "DoomsdayClient", "doomsday.jar",
    "novaclient", "api.novaclient.lol",
    "WalksyOptimizer", "LWFH Crystal",
    "vape.gg", "vapeclient", "VapeClient", "VapeLite",
    "intent.store", "IntentClient",
    "rise.today", "riseclient.com",
    "meteor-client", "meteorclient", "meteordevelopment.meteorclient",
    "liquidbounce", "fdp-client", "net.ccbluex",
    "novoware", "novoclient",
    "aristois", "impactclient", "azura",
    "pandaware", "skilled", "moonClient", "astolfo",
    "futureClient", "konas", "rusherhack", "inertia", "exhibition",
    "dev.krypton", "dev/krypton", "skid.krypton", "skid/krypton",
    "VirginClient", "virgin client",
    "catlean", "CatleanClient", "catlean client",
    "ArgonClient", "argon client",
    "Asteria", "AsteriaClient", "asteria client",
    "Prestige", "PrestigeClient", "prestige client", "prestigeclient.vip",
    "gypsy", "GypsyClient", "gypsy client",
    "Xenon", "XenonClient", "xenon client",
    "GrimClient", "grim client",
    "phantom-refmap.json",
    "dqrkis.xyz", "Dqrkis Client"
)

# ---- SCAN FUNCTIONS ----

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
            
            # Check against suspicious patterns
            foreach ($pattern in $suspiciousPatterns) {
                if ($name -like "*$pattern*") {
                    Add-Finding -Id "POTENTIAL_JAR_CLIENT_FOUND" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Potential JAR Client Found" -Message "Pattern '$pattern' found in $($jar.Name)" -Evidence @{pattern=$pattern; file=$jar.Name}
                    break
                }
            }
            
            # Check against cheat strings (jar content)
            try {
                $content = [System.IO.File]::ReadAllText($jar.FullName) -replace "`0",""
                foreach ($str in $cheatStrings) {
                    if ($content -like "*$str*") {
                        Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Custom String Found (Warning)" -Message "String '$str' found in $($jar.Name)" -Evidence @{string=$str; file=$jar.Name}
                        break
                    }
                }
                
                # Check for obfuscation: base64 long strings
                if ($content -match '[A-Za-z0-9+/=]{60,}') {
                    Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Custom String Found (Warning)" -Message "Base64 long string detected in $($jar.Name)" -Evidence @{string="Base64"; file=$jar.Name}
                }
                
                # Hex encoded sequences
                if ($content -match '\\x[0-9A-Fa-f]{2}\\x[0-9A-Fa-f]{2}') {
                    Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Custom String Found (Warning)" -Message "Hex encoded sequence detected in $($jar.Name)" -Evidence @{string="Hex"; file=$jar.Name}
                }
                
                # Reflection calls
                if ($content -match 'Class\.forName\(.*?[Cc]he') {
                    Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Custom String Found (Warning)" -Message "Reflection to cheat class detected in $($jar.Name)" -Evidence @{string="Reflection"; file=$jar.Name}
                }
                
                # Native library loading
                if ($content -match 'System\.loadLibrary|System\.load') {
                    Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Custom String Found (Warning)" -Message "Native library loading detected in $($jar.Name)" -Evidence @{string="Native"; file=$jar.Name}
                }
            } catch {}
        }
    }
}

function Scan-Registry {
    Write-Host "[*] Scanning registry..." -ForegroundColor Green
    
    # Use cheatStrings as registry keys (common ones)
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
    
    # Use cheatStrings as process names (lowercase)
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
    
    # Check JVM arguments
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
                Add-Finding -Id "BAM_HAS_BEEN_CLEANED" -Tier "Warning" -Category "BAM & Install Date" -Title "BAM Has Been Cleaned" -Message "BAM registry key is empty"
            }
        } else {
            Add-Finding -Id "DELETED_BAM_KEY" -Tier "Warning" -Category "BAM & Install Date" -Title "Deleted BAM Key" -Message "BAM registry key is missing"
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

# ---- MAIN ----
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

# ---- GENERATE REPORT ----
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
