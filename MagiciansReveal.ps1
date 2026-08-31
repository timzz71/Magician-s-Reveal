# Magician's Reveal - Professional Minecraft Forensic Scanner
# Version: 2.0.2
# Author: Timzz71
# Description: Enhanced scanner with 1000+ obfuscated patterns, fixed matching.

param(
    [string]$OutputDir = $PWD.Path,
    [string]$ModsPath = "",
    [switch]$Verbose
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MAGICIAN'S REVEAL - v2.0.2" -ForegroundColor Cyan
Write-Host "  Professional Minecraft Forensic Scanner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Warning "Administrator privileges recommended for full forensic data collection."
}

if (-not $ModsPath) {
    Write-Host "Auto-detection is disabled. Please paste the full path to the mods folder you want scanned." -ForegroundColor Yellow
    $ModsPath = Read-Host "Mods folder path"
}
while ([string]::IsNullOrWhiteSpace($ModsPath)) {
    Write-Warning "No path entered."
    $ModsPath = Read-Host "Mods folder path"
}

Write-Host "[*] Mods folder: $ModsPath" -ForegroundColor Green
Write-Host "[*] Output directory: $OutputDir" -ForegroundColor Green
Write-Host ""

$script:Findings = @()
$script:FindCount = 0

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
    $script:FindCount++
    $color = if ($Tier -eq "Detection") { "Red" } elseif ($Tier -eq "Warning") { "Yellow" } else { "White" }
    Write-Host "[$Tier] $Title" -ForegroundColor $color
    if ($Message) {
        Write-Host "       -> $Message" -ForegroundColor Gray
    }
    if ($Verbose -and $Evidence) {
        Write-Host "       Evidence: $($Evidence | Out-String)" -ForegroundColor Gray
    }
}

# ============ PATTERNS ============

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

# Obfuscated patterns - stored as a single-quoted here-string to avoid parsing issues.
$obfuscatedPatternsString = @'
xP[Z
o*-t
o*-B
]@QF
<T:Lsixtwo/cB;>Lsixtwo/az;
6cMM
G5Jzv
A4z@
bu\
oqdd
(gH:aO
1Qjv
Lorg/apache/commons/lang3/mutable/MutableObject<Lcom/mojang/datafixers/util/Pair<TT;Ljava/lang/Integer;>;>;
\:PP
isvgM
\:PL
wzbU
?T(G
}6==
}k*k*
i4EE
F#OI
E;UU
}qtp
v@T}T}
EtRqE
Q//H1
lGtt
(hhh(OOO(555(
]@RR
s_+%
</Px</Px
hD66
DMD(
o*..
oqgg
*2CC
oqgB
{`wA
Y3D=gM
([Lsixtwo/kZ;)Lsixtwo/la$us;
1Qii
1QiK
Borg/appliedenergistics/yoga/event/YogaEvent$MeasureCallbackEndData
1$fhI
TG{U
$@{S9S9
n#22
O]'*'*
L]QQ
D$HbeS
USE_FOG
}62H
(^``
}62D
\:WD
~E&Z>QQ
A%22A%22
Windows.Storage.Search.ContentIndexerQuery.GetAsync
)M4ga@r
==.>r.
?T)I
tTHTH
BII11
}qk+
>ejej
8s;Sv
i4FF
_jbb
]@~$H1
i4F{
ofwqq
u0D0D
Aq+)
)4"G
Aq+A
]@S:
o*//
Ljava/util/LinkedList<Ljdk/internal/net/http/AuthenticationFilter$CacheEntry;>;
71NN
xPEE
TGt~
TGtt
2r?I1I1
o,pU1^
A4|q
cOqhP
6cKR
[o;;
P+ji
P+jH
bu^^
JrC46
L]VV
J5HP=
`4~_D
L]V;
1QhI
:Ce[5%e[5%
n#3q
IPZLPZL
%LSISI
\:Vp
oOIzJ
jU;;
w15J
F#Mu
jU;K
jU;C
F#MZ
F#MK
i4GH
}qjj
PRe|a|a
Z@r@r
20260521055238.972Z0
o*((
71I1
33^b3b
D$Dbsj
hhhlhh\SShF::h.""h
s_)M
A4}V
A4}}
5mXvH1H1
oqaK
oqaq
P+kb
bu_Y
oqaa
6cH1
)4#A
bu_H
5Eh@TH
fU|WLd
y_]_]
TGuu
Ljava/util/List<Lnet/minecraft/class_12036$class_12040<TV;>;>;
~AI!I!
r>:>:
\:U*
}60(
&i--
'*->j
_l9mH1
{#F1F1
i4HH
w144
(^fH
i4H1
U@i&&
xpH3FF
S_&&
|GH1
!'a4a4
o*)B
;rRSV
Windows.Services.TargetedContent.TargetedContentAction.InvokeAsync
|GHL
71H1
(II)f
)4$$
s_(B
;;I11
sixtwo/bf.class
6cI1
3Ko[
oq`.
oq`>
oq``
oruoe
;|#K
P+dI
bu@B
{`rH
1QV~
vHNH1H1
Uw&3L
sx)A2
!)_)_
}qhF
}qhT
3|33L
S_%H
i4I1
i4II
|GII
s_7j
71KK
].L.L
CijLy
EvbL
71Kz
Wgngn
uG[3H
xPFF
'd0G%_
Aq(B
lGpp
Aq(k
_Tj.j.
]@VV
Pti@t@
oqcc
D$HbaI
oqcH
6,?~
1QUC
],4II
pDI;
pDIB
7x/l>rKrK
wzoo
}666
&i/w
&i//
bKCvM
F#H1
-m}Z7i>h
jdk.internal.net.http.PlainProxyConnection
71JJ
Yfq=%Qc
3KmA
o*++
s_6B
oqbb
6cGG
renderLabel(Lnet/minecraft/class_10055;Lnet/minecraft/class_4587;Lnet/minecraft/class_11659;Lnet/minecraft/class_12075;Lorg/spongepowered/asm/mixin/injection/callback/CallbackInfo;)V
{`pp
;(Lnet/minecraft/class_1792;Ljava/util/function/Predicate;)V
Q}SF
Q}SI
*ibyy
sSm|I1
J|Lw.t
net.minecraft.class_9135
net.minecraft.class_9139
me3p3p
pDHI
pDHH
pDHN
.?AV<lambda_286>@?0??initClassRegistrars@@YAXXZ@
pDHA
[+)gg
Lnet/minecraft/class_9139<Lnet/minecraft/class_9129;Lnet/minecraft/class_10266;>;
H+s1QQ
G.@I1
!t**
\:Zi
?T"7
r(F<I
Xv71u
-%1G5
F#I1
tre_z
i4KN
s_5_
wjkjk
]@H1
gkTUTU
BH'E]
Ev`F
lGrC
o*$D
]@Hu
)4'<
DM>}
)4''
A4q<
A4q1
3Kll
y\*\*
6cDD
oq]A
oq]]
P+gg
pDKK
{`qq
[o6&
wzik
n#<<
L][C
net.minecraft.class_9106
wzi5
*XS[m
!t++
/ZAx+x+
!t+F
>u7-I-I
S_"E
E;ZF
i4Lw
Hf-3I
.jbjb
Aq5(
EvaA
ns<H1
XH!`XH!`
DM?|
Aq5C
TwS}c
fVCH1
]@I1
DM?M
s_4B
t$|Hc
A4rr
oq\
A4r!
)4(B
D$kcKH
buDH
buDD
Cx\x\
P+`)
x<@m8
[o55
}4}}kKkk``W`uuCu
;|'{
class_9837.java
pDJJ
L]XX
pH=]u
}65H
i4M$
org.jose4j.jwt.consumer.SubValidator
&rw_q
Np4WdH1H1
S_!8
Aq4L
!9C7~n
DM<I
s_3&
o*&&
(Lsixtwo/mG;)Lsixtwo/jR$uc;
7C'j?
xPBm
A4sF
Cd)H1
`DDDDDD
oq__
oq_Z
[o44
NHNHT
wzkL
]L1L1
1QQ/
L]YY
L]Y[
n#:<
<Mgz0F
8jN?jjN
mBajP
\:_p
\:_I
}qcH
?T!2
&CO(mb
i4NJ
i4NN
()Lsixtwo/hL<TT;>;
71VI
D$|bkG
uU=[=[
s_2S
s_2(
Evg)
o*''
Aq3X
xPMM
Aq3F
)4*.
rD;b0!
o*'m
EvgL
o*'B
lG}F
o\^<<
xPM1
8e}SQ
oq^~
P+bb
q<18f]83p
P+b~
,bjH1
sNH11
n#;;
("w~.
wztt
?T>d
!t..
}6+J
]f\H1
jU3;
F#EE
fivefive/n$F
w1=I
fcJw]8Q
71Qw
lG~E
44[w0
Q}VV
Q}VH
Aq20
3K`d
r{Y3535
)4+;
|v^]oA
oqYY
buGR
P+cI
{`MM
1Q__
c?A+JoS
net.minecraft.class_9142
net.minecraft.class_9141
6,99
L]_{
\&>{>{
L]_*
uhD;u
!t/F
~EH!'
}qaE
jU44
}qaa
S_..
mixin/accessors/ItemInHandRendererAccessor
_jtQ
AZx6#
Aq11
)4,E
o*!!
DM3C
`R5H1=bb
)4,,
6cA|
oqXX
buH1
;|+n
#fH#fH
;|+K
pDNH
KC|b|b
buHH
{`JJ
[o1H
'\]H1
lext-ms-win-rtcore-ntuser-dc-access-l1-1-0
wzvD
Zp'_
n#99
|lNlN
gv/7L
}6)H
*t(I(I
!$%&'+,0234579=DGMRWYZ_w
5t}=6H1
_juu
E;!\
}q`B
]W}?2?2
BA$C+EWq
]@NG
o*""
71S:
]@Ny
lGx&
A4wF
Q}T0
3Kff
6c~F
{`KK
buII
buIH
i~|/ZK{pK{p
*%79jaja
1Q]B
6,7C
buI!
n#&x
n#&{
D$HbYu
\:CC
\:CE
\:CH
4QA}<LL
wzwz
L]]]
T;9;9
H5oMHMH
R\Dk(hFbLbL
jU6K
jU6Z
_jvC
1CT"bD<
Aq?M
Aq?G
DM1I
5p-KH1
xPI1
Evko
PRB/$H$H
/>`11>
Q}[C
Zp%L
3Kem
Zp%'
~pcWME=831.-,+***********))))))))))))(((((((((((('''''''&&&&&%%%%%%%%%%%%%$$$$$$$$$$$$$$$$$$##########################################################################$$$$$$$$$$$$$$$$$$%%%%%%%%%%%%%%&&&'''''''''((((((((((())))))))))))***********+,-.027<AKT_lz
oqZ6
{`H1
oqZZ
P+~Z
buJJ
{`HJ
{`HH
wzpG
L]bE
6,6H
#{EI1
}6//
w19H
HjpOO
jU7@
;3mWW
Q|7CL
H\'e'e
yHO$0$0
_jww
S_++
s_=w
]l(Ip<
4*eHY
Aq>W
Q}Zi
L8Stt
xPH1
3KdO
buK@
oqUU
leadPerLine
6,5H
{`I1
net.minecraft.class_9186
net.minecraft.class_9182
net.minecraft.class_9183
bGQk`a
mQ*q)
]!DlDl
?T;H
L]cv
njDjD
zQc&0
qH)Ti7}
{{L{ee3eOO
0ztfH
?T;;
_jpp
!t#H
(^r@
rm+m+
3$tP`
[RX^Y6
AsyncOperationCompletedHandler`1<Windows.ApplicationModel.Calls.PhoneLineDialResult>
Aq=m
71\
%[?1PI
L8Suu
xPKK
MvnmI
oqTc
DrDrDr
oqTT
buL1
]QG>]QG>
1QZ;
Zp##
6NuH1H1
6U!U!
L]`H
AsyncOperationCompletedHandler`1<Windows.System.UserProfile.SetImageFeedResult>
^R$Z$Z
)p7NN
w1;M
!t$$
}6-M
Lnet/minecraft/class_10945;
}qdd
8"cN["cN[
&H>{l
S_)m
7Y[_cbb
S_)H
#`x6H
s_;;
DM44
7t$F
{W?W?
$$lf`
VnnniiTizz;z
Q}XI
CN8>p!
Zp"E
oqWW
IG*)I!
GQ$H1H1
pDuF
buMM
q%]-{-{
wzsL
6,33
1QYY
1(-:77
}6"M
}6"D
}6""
H>}H1
NVlH1
(^p+
`A`2`'`
]klp\
!t%J
!t%d
!t%a
!_dc00f6c4e711701456d12cffea74b22b
_jrr
]4YH1H1
fc.Z
E;$H
DM55
]@CX
i6mz3
Q}_L
Q}_I
DM5T
3Kyy
s_:J
oqVV
onPlaneMapUnmasked
0~cIcI
oqV7
6,2f
-.<_ejh@keke
1QXF
n##M
cuQBK
6,22
keJL1
pDtF
67uPg
\:FJ
5VRF
wz||
L]fH
L]fC
aaa5aaaNaahhah
JU=6
5VR|
JU=*
jU+A
_jss
w1E3
(^wG
MGquj
jU++
vH3Wyy
DM*H
]@D8
[eQ(tUHUH
DM**
fc/L
S(;glw
r5znqL
H3Q##
)Y&I1
oqQC
oqQU
{`EE
6,11
5VSY
w1DI
hvvv^iiiSYYYEHHH6666%%"%
\:EE
Q#9#9
e,%De,%D%D
?T7I
JcJGd
F#ZF
_jLL
fc,F
71XX
+hTCQ
Evmm
xPww
lGG[
`:`2`'`2`"`2`
DM+A
DM+H
ZOff
!"J/H
oqPC
}}}-|||Fzzz`yyyywyy
Zp/8
1QFF
AsyncOperationCompletedHandler`1<Windows.ApplicationModel.Chat.ChatMessage>
A['7a/
n#!!
Zp/K
5VPP
6,0!
q|M`v
pDvH
\:DA
L]d+
wz~~
L]dd
}6!!
z{``5LL
[ZZrZXX^XUUJUQQ7QJJ#JCC
(MLmH
F#[L
w1GD
NjnBI
_jM1
zqlLH1
O*t]@H1
JcJH1
E;))
EvrL
xPvv
Q}\
e&gnH
_?;A@~@~
D$DbaJ
&qZ2v
EIJyJQ
oqSS
ZC"C"
1QEE
YMqbu
1QEH
D$zo/ocf
L]eB
>?~,J:
JU0H
}6&F
}6&I
?T5G
?T5I
D$|bgn
F#X#
vC7=N
71ZF
71ZZ
DM)l
7t!H
P?-?-
Q}CC
3K}}
3K}C
Fi<nhe!I
Eh#Gu
6cww
oqRR
6cwF
rritii_Z__TATTH'HH:
{`@r
P+vH
{`@@
{`@]
5VVC
5VVQ
1QDD
JU1H
00c209e2H
9"R<P
rz=j8CUzI
\:JA
-xW5W5
~Tle^e^
tIRhJ
jU/L
!hQ*g
arEEw
fc+v
^.=0n
]@8A
Df&H1
DM.*
Q}BB
ui1Bp
qb\2\2
D$Dbgb
xPp*
oqMM
z2{L{L
EL2mH
oru|&
eg/FH/FH
..(*#
1QCC
n#,L
oO}A/p-
5VW2
hMRH1H1
oX%^3[oX%^3[%^3[%^3[
\:IF
\:I1
o6rd~d~
}6$V
?T33
(Lnet/minecraft/class_1799;Ljava/util/List;)I
org/jose4j/jwk/OctetKeyPairJsonWebKey
_jH1
E;*J
~<MLI
ACx&V
S_22
x$@+\
(pL11
71dI
lGCL
lGCH
LD#/+]
(Lnet/minecraft/class_12205$class_12314;Lnet/minecraft/class_4543;)V
dMYY
H3qbDD
PVdNe
^Ue0I
oqLL
Windows.Storage.PathIO.ReadTextWithEncodingAsync
C\C!m!m
([Lnet/fabricmc/fabric/api/client/event/lifecycle/v1/ClientWorldEvents$AfterClientWorldChange;)V
6,,,
^HlE`x
{`^^
,!!r:
pDzh
wzzI
5VT&
wzzz
<#\HO
\:H!
\:H1
!t<<
}6%%
up:p:
\:HH
-7?7?
0lRH1H1
?T0O
_jI1
zNhNh
_jII
_jIH
fc)P
YGtpp
"H3hR$$
.$I1I1
PQq~H1
rW}$H1
D$DbeT
EvvL
DM,A
EvvA
ZUNUN
]@:K
DM,L
uv)I1
6crO
3Krr
}6dzSH
..@-A@@:T@@@g@@@z@@@
3KrI
:r+RJH
1QAS
W9E6U
5VU{
5VU_
pD}L
7ob!&
?T1a
jU""
K{HHH
F#TT
hFGxx
_jJ%
fc&I
3g<g<
Evww
RUaT
lGMM
Q}GD
.|7Q
_bIbI
,GAA8
ZO``
{`\E
\''"\AA9\ZZM\s\Z\
h=]>L
Zp))
reduce_water_ambient_spawns
|{QL1
:wno9
FcQPH
Kptqx
>#$s
"W]W]
!t>C
s^lhss
!t>J
_1Wi[
JU5K
sixtwo/ng.class
o-"PJ
F#UJ
F#UU
E;/S
.|66
ZOaa
fc'K
RUbb
xP|A
=/a0z+
)(FFFFFLsixtwo/mG;FLsixtwo/mG;)Lsixtwo/id;
Zp(H
D$DbkP
oqI1
(%BkI1
oqI!
oqII
B9p6R]
{`]D
Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager.StartAppInstallWithTelemetryAsync
5V[I
A'9HH
{<RU]m
JU6E
i(%ji(%j
PGZ1El
M.J.J
|=66
o-"SY
aU]aH
%j@U=!
jU$$
(Ljava/lang/String;Ljava/lang/Throwable;)Ljava/util/concurrent/CompletableFuture;
F#RL
S_>>
grIH1
xW:||
fc$d
RUcI
D$|byc
'[:|=q
JzC!}
(:;HH
P-OSr
H3Q**
^uhuh
I)LjV
oqHH
oqHx
fs-Th7
Zp77
Hd#'<HH
oqH1
Xal6&H1
h;7NU_#
9mxs&
1QN)
n#))
L]l/
D$HbJe
v[wBI
(MH3hh
|=7F
px]x]
JU77
"/#L#L
CetK
LJ#""
_jEE
9~o0&
(H{mqmq
.|4y
h\PVu
]@>B
ZOoL
ZOoo
RUd6
lGH1
EvzL
Nt<t<
u^AI1I1
7t((
Evzu
xP~F
6cnI
oqKD
oqKK
P+MW
F"G!H!H
{`[[
L]mI
R_I_I
L]mm
1QMM
6,'B
CewL
JU(H
5VYY
jE'HH
5VYC
+5H1H1
<A\R~8
casuj48bimqguzbng82otwc74jqgwtyh7c49hul1e985o6yx6ssh3884jvs9jknjry2l30ouyb10yb9zyj1pchn3vwxxln0jcm8b
JU((
a0>6F
o-"UT
`nn~I1
,$E$E
WICMapGuidToShortName
.|3b
E;00
.|3I
71bQ
lGI1
ZOlr
DM!!
lGI!
Hy@TM
QGvHH
RUeM
]@?E
DM!F
lGII
xPy4
s0]9]9
7t))
m\L1L1
8D8B
oqJJ
6,&s
Zp5D
C<(s{N>
GGG}GGGdGGELGG;33G*
L]rL
sHNv%
?%oVV
grNE-$t
!t22
w1I!
w1I1
n`d>d>
_jGM
F#QQ
_jGy
gy@B7y@B7y
_jG6
E;33
fc#I
fc##
RUff
71mW
Evxx
71mC
lGJJ
DM&A
lGJA
RUfK
RUfH
RUfL
]@00
3KtF
W_1.#
|e#wjp
$5g81x'J8J8
oz:?xcU#
6clD
oqEE
9P6$.
(H/I1I1
P+O@
_v^v^
{`YI
bu;J
bu;*
GAKK3
1QKf
7t6J
6,%I
o'Urr
\v&O)44
5V_c
1Cr1>{
JU*u
w1HD
3xi9H
|=:$
jF&F&
!t33
JU*J
w1H1
w1H,
1C_=mL
!1*-s
S_:H
u0](@@
ZOjj
ZOjv
Q}I1
RUgH
8D:J
8D:8
Q}II
D$DbnN
6cmm
>2e<H
P+H1
oqDG
oqDD
5V\H
b\O\O
5V\
Cepv
Cepp
L]p=
*Eg(0
CepE
@C8nw
>fe{
|=;;
\:pm
'`L1L1
NSpBuWpBuW
!t44
o-"V.
>#./
S_9]
w1K}
_jAH
$mI1I1
[.[n[.[n
r3EHH
lGTC
.|00
H3+Rpp
4u)TH
H3Q55
Q}H1
6cjC
oqGG
9Mb%m_j
dMVV
Ej8F)K
6cja
ZOk_
P+IT
{`WL
3d3d3
P+I1
1QII
5V]u
5V]]
5V]>
aHIaHI
pDeJ
\:ww
L]qq
>fdE
!t5D
L]qP
>#/F
!t5J
9?~84
dC,c%%
v~/~/
w1JJ
ye+EH
zwBcz
E;44
.|??
ZIUst
S_8H
DM%L
2HI<M5z
P\kF%F%
.|?_
s8)8)
Ad>d>
N{{{hhfh
Uo&44
xPeG
xPee
;6X35I
dMWL
>fgg
L]vv
1QH1
1QHH
5VBw
JU-C
G+P6_.P5
,Q:H1
>#,A
WebRuntime.Extensions.BrowsingExtension.PostIsolatedMessageAsync
o-"Xb
oldbb
o-"X&
o-"X$
xKlJc
<M:ad
}+%Mhj
?fD98t
71ii
fc?-
fc??
RUj\
3KH1
Ev|I
7t2T
dMTK
class_243;Lsixtwo/ou;Lsixtwo/mw;(Lsixtwo/ot;Lsixtwo/mw;Lsixtwo/gclass_1657;Lsixt43;F)Lnet/minecr_49c1b9baee51c40be53ef034ca671f5_66e465280dfe8cff83ce4ffa5c2a248e822856f94e7f10d_c1c347717e11df0dbcd871156222b44_f5ab03348f0563c9dc451f469b5faa3_519ee5493ccc946bddd7f2b4a91db05_eb06ce8ce82096d6e901c9c954df3c9_ef880767e57308b2e2bbb6f48771263hasVisibleChips
o&cCC
dMTd
(%\MI
HLT6~Q
{`UU
{`Uh
kNNYk
lastPopulateStamp
5VCb
6,!b
1Q7e
\@NINI
&9&99R&RRl&ll
L]wI
L]wH
\:um
Ce}?
!t77
o-"[G
JU.B
JU.P
w1Tm
!t7S
S_FL
e{Dz
H5rvvPH
fc<<
(Lsixtwo/kl$ug;)V
0]Dff
Ljava/util/List<Lsixtwo/nd;>;
Ev}H
xPgg
H32{GG
Q}MM
.|=f
6ciF
oq@@
Q4LH1
7t3E
1$fO{
x<@Ih
L$4A0
pDff
%1)1)
>#*H
>#*6
>#*7
\:tL
\:tH
U(gVv#y
|sq%I
9s2s%
.?AV<lambda_148>@?0??initClassRegistrars@@YAXXZ@
1~(Ja
_j]>
?xj+j+
_j]D
.|<L
_j]]
.wAHAH
fc=n
c(Lnet/caffeinemc/mods/sodium/client/render/chunk/vertex/format/ChunkVertexEncoder$Vertex;FFFIFFFI)V
NSNfNSNf
..&"&&$$!$%%
Q}L1
yu,OH1
71kF
lGPJ
ZOw>
@+(TE
dMJ0
xPfH
xPfF
H3Q11
Wal;Y;Y
Zp>>
6cfH
LLLFLLLXXLXmmLm
7Sl$g
D$HbAy
oqCC
pDii
1Q5"
P+EE
1Q50
bu!L
bu!V
5VA0
EGH1GH1
|=<q
dkteR
kiV,fH
=U{_L
U9BH1
DN&'F
>#+J
w1VA
LD9-U
E;88
w1Vd
9QLy`0
e{FF
lGQQ
Q}s^
dMKK
1a)!H
oqBw
=@6I1
1Q4K
8D0\
5VF\
5VF<
@+]p
g;$&$&
pDhV
02J(.`N`N
|===
gH=6II
d'H1H1
r(F\5
.|:3
.|::
TQ{H%H%
.?AV?$_Func_impl_no_alloc@V<lambda_419>@?0??initClassRegistrars@@YAXXZ@XPEAUJNIEnv_@@PEAV_jclass@@@std@@
IQl]AI
]@((
e{I1
e{II
e{IM
RUnC
7t>!
dMH1
@+(VH
pDkL
pDkk
^H"jU[
[?EcUk
[kz^!I
s40VNHH
5VGw
>#))
w1PP
vvv|vuvccavIIHv00/v
o-"_E
$/CfH
Qh>h>
|0w/85c
uI*uI*I*
-!suL1
(|AI1
_jXn
S_BW
m,-,-,-
e{HH
e{HL
ZOrr
Q}qI
e{H1
Q}q|
umb|N
EvAB
7t?M
7t?A
<fWmWm
dMIZ
#HhHH
E#tsL$`
P+@W
bu$$
dMI1
8D2)
6,\
-<gNU
Zp;;
{`..
bu$G
nativeRef
1Q2H
|=##
!T!!5T55JTJHTT_STTtTTT
>fmm
o-"^v
>#6(
wM`6!
J(Ljava/lang/String;)Lnet/minecraft/class_6880<Lnet/minecraft/class_1887;>;
fqqqL
@@@|@@@h@@@U@@@A@:..@,
bYI}KqT
Db`;d+
j88A%UU
fc9A
fc9+
XeAU=
e{KK
EvFK
RUp^
EvFF
Q}pp
.|8C
.7G(j
6cbb
3KB;
redirect$cfa000$useIsolatedHandBufferSource
p|$pDfD
p|$pDfA
(Lsixtwo/bB;)I
(Lsixtwo/bB;)F
oZO&&
{`//
7t<A
XvzSl
J4i3Jx
pDmW
>fl9
;,!,!
w1RI
LEKhj
E!R!R
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
3L333LIICLL^LLLsLLL
G?$S3
_jZZ
startUseItemPost(Lorg/spongepowered/asm/mixin/injection/callback/CallbackInfo;)V
wjkGG
.|''
fc6J
RUq;
ZOps
ZOpG
71vS
RUqK
0@n@n
Zp9V
6cck
(IIIII)Lsixtwo/ie;
>foo
5VJJ
SWw0eH
>fo<
Cezz
o+H11
>0SO}
JU%%
n3<C=
wX.pu!~:7
\:~X
o-"@_
q^Oja.
rtATN
fc7|
71qA
e{MM
.|&&
?`1`-
e{M9
.|&D
Nprwr
Q}vu
M$?,M$?,
]@,h
B599
]@,F
lVe==
6c`K
dMLD
7t:8
7t::
DJkdN
{`-G
Zp88
bu';
{`--
?*MH
5VKB
@+Zo
@]EeH
\:}}
>fnn
pDoo
;bLbL
shape/liquid
f$u$u
CeeR
U@00
^3RfT
U@0Y
&.uW|
-XUXU
oWW}}
,X#x#x
}tWI1I1
wtP1#
.|%M
e{L1
q8dxd
RP!+a
lG_E
lG_I
lG_H
B5::
oHa,,
RUss
Q}uH
3KGG
dMME
dMMM
dMMI
p/>rI
rXb^],
dMMm
{`*?
K^t:H
55H"55a/55{455
lmUnm
5VH9
5VH2
6,XG
5VHn
5VH~
5VHH
|='H
o-"Bc
ENV,$
+Y+#EYE:^YYMxYYY
6LhD4~
'ZqW
QhA<D
_jUU
_jUI
iMkZ
Tmhzd
S_MA
iMkk
71ss
Q}tC
`yrz|
lGXX
EvJJ
3KF(
D$}Hs
dMBB
H3Q99
bu))
hhhzhhh``hYGGhB--h*
bu)x
6,WH
6,WL
6,WC
5VIC
5VI!
#1;}y1;}y
5VI1
\:cI
>fhL
CegE
Cegg
o-"E1
NG(LI1
_jVL
RKeFeF
T1L1L
_jV\
w1^^
ZNH11
(Ljava/util/Set;)Lsixtwo/cz;
iMjI
fc22
e{NI
d0jDL
RUu\
xPii
xPiB
B5<D
xPi,
]@//
dMCC
ZO|I
rWzJz
bu*J
bu*F
?*Hk
e(8u%Lv
^/(ebeb
?*H1
Or$3L
&,/A
>fkk
Ceff
o(Mgg
w1YC
U@3!
!_9e47ba1c6c79b2bfe0db7421cc17e628
AsyncOperationCompletedHandler`1<Windows.Foundation.Uri>
\:bI
iMii
1ymym
iMiM
_jW9
CCTHH
KHquH
fc33
XII2IK;KKe,ee~
[$Q$H1
EvH1
B5==
e{QQ
71}H
EvHH
RUvC
GJ=~N?
7tFF
8D+E
Q}zz
7^OI1
Q}zE
8D++
11WJ~]
?*I1
}2]!,
?H.?H.
6,U2
5VON
>fjF
5VOe
xINNc
!.A!.A
.bITI,
&,.e
\:as
~c_H1
X&sH
X&sq
Rq,q,
+TMHnTMHn
requireType
71|K
]@!!
@p$|H
7tGm
QnWH1
B5>j
FE@[T
5Rc4HH
sourceEntity;affectedState
ZOzn
6SeT6SeT
P+X;
6,TT
5Jc5Jc
1Q:J
y,/NI
{`&&
5VLc
?*JZ
x?*?*
5VL1
rkEkE
X&r2
|=++
O<hH1
ax|F`Ly
@~\oH
S-;bS-;b
fe;4G
'Z}f
'Z}}
|QOfOf
S_II
S_IM
S_IQ
]""
DQ`\d
B5?G
%{]{]
B5??
UUQH!
UUQH)
||$|bb$bII$I//$/$
?*KK
o&cqq
aMmGHH
P+YA
P+Yy
b\OMu
>ft3
X&qq
X&qF
cuQaH
X&qK
^xIHH
ko77
5VMM
|=((, "+j1t5", "+3h6h6", ">#?I",
"puiGW", "|=(J", "GEDII", "G=:H1", "\M_$4",
"X(nH1", "eePecLccv2vv", "S_H1", "_jRR", "fcNN",
"S_HH", "f7HRf7HR", "OfRlU", "PWTgg", "}9ciyN",
"71~x", "fcN7", "ZOxA", "EvOB", "]@#M",
"*=/))2IAJj)", "pvp.land", "P+ZF", "(&!&!", "org.jose4j.jwk.KeyOperations",
"k$*$*", "1Q88", "{`$V", "?*DL", "?*DG",
"5VrU", "|=)", "&,+k", "\:fH", "\:ff",
"&,+C", "O<T\1kKK", "zvU&]", "03cfff", "^o>trr",
"\:f<", "Cebw", "\:f0", "iryoh", "_jSG",
"_jSF", "}Kj+Z", "S_WW", "fcOE", "ZNH4B",
"]@$L", ".|.H", "B5!H", "/app/api/themes", "dMDD",
"z%R?{", "B5!!", "{`%L", "f>_(", "8p#4646",
"JDH1H1", "7tBB", "&/4-2)", "7tBd", "6,QC",
"ko5J", "&,**,", "6,Qf", "Cemd", "5Vsf",
"w1dT", "U@8H", "w1dd", "iMlh", "oWWee",
"H1O'O'", "o-\"KH", "0^lKp", "S_VL", "fcLC",
"ZOFI", "8D.v", "EvMM", "71xI", "8D.M",
"HUYU7HH", "8D..", "lorepvp.pl", "?*FN", "nL}@@",
"7tC]", "dMEE", ";|sH", "{`\"G", "5Vpp",
"o+H;;", "$yUII", "&,)H", "5&wH1", "o-\"Je",
";7z-y", "o-\"JW", "w1gK", "H+>---", "*W*!DWD7WW]JWWwVWW",
"iMcK", "iMcq", "HHa$aa{9{{", "RU|S", "71{{",
"'Zyy", "RU|?", "sssvos\ZsCCAs))(s", "7t@V", "xr0O\M",
"dMzz", "ZOGc", "@+L!", "?*GG", "0t|NWNW",
"$*?!J", "s{,pH>", "|=,A", "|=,,", "cq2q5353",
">#;E", "w1f,", "tIROH", "|1TH1", "V\*H1",
"H5~PHPH", "o-\"Mx", "T}cDO3cDO3", "x:{H{H", "r#Y#Y",
"S_TT", "!.zAj", "j*9I!", "]@'$", "eu.minemen.club",
"fcJG", "c`IG4", "$kRI1", "e{V6", "ZODE",
"e{VV", "|y+y+", "fcJp", "e{VH", "EvSS",
"7tAA", "7tAK", "7tAT", "dM{{", "@+MI",
"@+MM", "C:9fH", "@+M;", "Windows.ApplicationModel.UserDataAccounts.UserDataAccount.TryShowCreateContactGroupAsync",
">fsD", "1Q$$", "U+/55", "6,NH", "6,NN",
"1Q$P", "X&tF", "\"Qohb*^p", "ko22", "5VvA",
"oZ2NN", "w1aE", "w1a,", "H3<\"//", "BBXXXoo",
"~c;=~c;=", "iMa9", "zQ4H11", "bPLHH", ".|*J",
"KKK3eee3~~~3", ".**", "S_SI", "YYYkYTRRYD88Y/",
"EvP&", "fcKX", "fcKK", "fcKJ", "Q}bK",
"ZOEE", "C1fHfH", "7tNN", "e6\"\"", "8D#=",
"\Device\HarddiskVolume3\Windows\System32\WindowsCodecs.dll", "6,MC", "1Q#?",
"y7S]y7S]", "@+N>", "&,&,", ";|vM", "om\"SS",
"~y6\uL", "U@<A", "U@<I", ":@0tH1", "$g5HH",
"U@<Y", ";|vv", "]T^qZ", ")z^z^", "CeiI",
"l<lBoH1", "\BGBG", ">v;HH", "w1`A", "w1``",
"fcH_", "fcHK", "fcH1", "java/lang/constant/MethodHandleDesc$1", ".|))",
"EvQC", "EvQQ", "Q}aM", "V(Ljava/util/function/Predicate<Lnet/minecraft/class_1799;>;)Lnet/minecraft/class_1799;",
"8D\"G", "ZOBB", "P+PC", "@+OW", "@+Oi",
"*`(R\"l'", "2lflf", "P<.ry]", "B&FzA}_5g", "5Vtp",
"@\(F(F", "U@==", "Ceh9", "PfffhMhh", "rnaAB",
"\:hI", "NA(|u|u", "iMgg", "\l\"uH1H1", "iMgD",
"I2)iQ1Iq", "+T/T/", "S_QQ", "o3XSS", "sevCv",
"fcII", "ZOCG", "L8S**", "RU@e", "EvVV",
"RU@@", "RU@L", "<.iK)", "=}0II", "H3{Frr",
"vuh2vuh2", "{`?f", "gu>fH", "5Vuu", "#C|(H1H1",
"kAS%/e", "CekA", "EA~\"$J", "U@>R", "o-\"qs",
"o-\"q@", "rYT#T#", "w1b7", "Ys{8I", "`In:fH1",
"(Ljava/lang/Object;Lnet/minecraft/class_243;Lnet/minecraft/class_12211;)Ljava/lang/Object;",
"fcFM", "iMfE", "EvWB", "RUAA", "jbiyx;Y<",
"oGyVV", "B5((", "`\L\L", "@7sR'", "o]bOO",
"9F8!P", "5Vzs", "?*\\", "5VzA", ";|u<",
"ko.C", "'_-nPHH", "Cej2", "L$y$y", "X&xe",
"ko..", "O7#7#", "w1mH", "w1mL", "JH3tY00",
"o-\"pU", "iMe}", "o-\"px", "aAoH1", "iMe6",
"S___", "EL.6262", ")q,,", "r_~~", "zlU#^",
"fcGG", "ZOAA", "AibRJRJ", "p(8u*", "iFZ*iFZ*",
"RUBB", "+|_|_", "9P6H1", "e6&&", "Q}fH",
"Q}fE", "F\"\L\"", "dM|F", "e6&B", "I0>~H1",
"&,\"r", "{`=A", "8&Q(w", "1Q/L", "CeUN",
"JC;[H1", "CeU4", "u'u'&@u@?ZuZXsusouso", "w1lB",
"%6B@", "%6BH", "%6BJ", "%6BU", "%6BX",
"%6B]", "\:mO", "\:mL", "%6B}", "(Lsixtwo/mg;)I",
"CvVIb", "()Lsixtwo/oQ<Lsixtwo/oJ;>;", "S_^V", "F&B:H1H1",
"hC}~}~", "EvUU", "5|qmm", "dM}H", "e6'p",
"{yML1", "Jq[v,", "6,H1", ",,\"WEEW9_WWKxWWV",
"&,!H", "X&~?", "%6C^", "%6CC", "CeTJ",
"ko,G", "ix+-)H1", "1m={H!", ".d^d^", "sCrL0",
"r_||", "T-$ZU;", "H+O'cc", "w1oo", "w1ob",
"-/J/J", ")q*L", "javax.crypto.SecretKeyFactory", "iM{A", "fcE*",
"<=ss", "I^\"\">u", "e{_H", "RUDD", "H\"f1SHH",
"<=sG", "RUD)", "<=sI", "8DYB", "DQ`H<",
"y,IeOw", "{{|H3oo", "7tH1", "Apx\H", "5pgT,",
"fffxe^f^UEfE?+f+'", "%6@@", "6,GG", "%6@L",
"%6@H", "CeWC", "%6@$", "%6@*", "%6@4",
"5Vyy", "w1nC", "^m%=a", "0DsQD", "sixtwo/ag.class",
".d^k\"", "*pQA*pQA", "fcB7", "S_\\", "o|$`H",
"o|$`L", "ZOLL", "ZOLI", "e{^^", "UQTEU",
"7tI1", "}6@HH", "V&]FH1", "?*XX", "139!\"#\"#",
"3KUI", "7tIS", "{`88", "ADhev", "5V~~",
"5V~y", "1Q,@", "X&|K", "CeV4", "%6A=",
"%6A>", "@p<7", "%6AI", "%6AM", "U@##",
"%6Ay", "%6Ah", "%6Ao", "hv>v>", "v8@}\"}",
"r_zI", "o-\"t&", "S_[|", "r_z(", "<M:M:",
"Wgn=J", "08GoDI", "RUF@", "EvXX", "d|W_W_",
"entity/wolf/wolf_snowy_tame", ">VmdI", "Q}j;", "dMpG", "ZOM1",
"e6**", "B5-G", "?*Y&", "e1Ba|y", "$PH11",
"6,EC", "1Q+C", "@+F=", "?*YG", "<oH3B!!",
"()Lsixtwo/pX;;", "&,>E", "&,>L", "%6FF",
"%6FA", "%6Fm", "%6Fj", "%6Fd", "%6Fe",
"%6F}", "wwOSO^", "m>^hT", "%6F<", "%6F:",
"`@r@r", "*QeQe", "w1hh", "o-\"wE", "QVWoa",
"sCrqq", "<=v8", "fc@H", "O6wfH", "YQYnY?YZY)EEY",
"ZOJJ", "H&eB3U&", "8DZ_", "EvYU", "RUGt",
"QcaGaG", "?*Zd", "Q}ii", "S}byZ", "dMqq",
"P+((", "%6G~", "%6Gw", "%6Gf", "%6Gb",
"%6Ga", "%6GX", "%6GU", "%6GR", "wz\"b",
"%6GG", "ko(B", "@p>>", "U@%l", "*>r>r",
"jUyy", "&Z%wH1", "s`\"G", "\c@H1", "o-\"v8",
"'ZmG", ";7?VH", ":>3[5", "FJiI", "r_xH",
"S_YD", "###')))A", ")\TSP", "RUH1", "Ev^2",
".~(UH", "fcAA", "5Ozj2.", "RUHH", "Ev^A",
"dMvC", "dMvd", "i}t0}t0", "e6((", "{`77",
"{`7!", "P+)B", "?*[`", "5V}n", "%6D5",
"%6D8", "&,<x", "}9>3O", ">fDD", ">eF[.`>eF[.`F[.`F[.`",
"o-\"yy", "CeS9", ">fDd", "%6Dm", "%6D[",
"%6D\\", "%6DC", "%6DE", "%6DK", "RUQ4&Qd(RUQ4&Qd(",
"o-\"yH", "lUaIMl", "jUz?", "r_yy", "jUzz",
"%07u7u", "}x/*H", "A'}zfs", ")q%%", "'Znn",
"<=tt", "/!BY.Y.", "Ev_t", "_7LI}", "G`vP`vP",
"RUI1", "ZOH1", "N|rH1", ",@e,@e@e", "{`4K",
"ZOHR", "P+**", "P+*,", "e6)B", "e6)M",
"7tUU", "@+AV", "%6Eh", "%6Eq", "%6Ep",
"%6E{", "%6EE", "%6EW", "&,;;", "/%OW#^x",
"%6EX", "%6E[", "%6E2", "%6E<", "5VbE",
"reotd", "@p8:", "5Vba", "q]{L11", "U@''",
"@hd-/", "U@'s", "jU{A", "ga,a,", "uCY|CY|",
"o=\"A+", "b2naoi00ulvleb0vpqcxdt11", "o=\"Az", ")q$B",
"ZOIp", "ZOI1", "7tRP", "9F8>/", "E$yeH1",
";H{H1", "?1D;o", "X&gB", "Ce]-", "&,::",
"&,:H", "%6J<", "%6J%", "%6JH", "%6JJ",
"ko%F", "%6Jz", "%6J|", "%6Jr", "%6Jl",
"%6Jg", "Xv7vL", "w1tQ", "o=\"@+", "o=\"@(",
"S_fu", "jU||", "_<K<K", "FJjH", "}KwWX@5",
"5ttU;", "Ev]]", "Q}mH", "gcwH1", "7tSI",
"uo%#\"#\"", "aJqiI1", "{`2E", "?*V)", "{`2`",
"^:@@", "w,!h!h", "5KF(5KF(", "6,@H", "a$|$|",
"5V``", "q\f*/", "G'$ND", "&,9z", ";|cu",
"%6KD", "%6KW", "@p:M", "U@)B", "U@)7",
"%6Kp", "%6Kt", "%6K*", "X&ff", "%6K=",
"!thK", "X&fH", "ttZXZZiiAiyy'y", "H3p8**", "H1;NuNu",
"r_tn", "`8I-`2`$`2`", "UB/C.;", "AgrD;",
"?)hz:", "S_ee", ")q\"\"", "@,X]B", "zCzz`U``ffGfvv-v",
"pfUII", "e{gB", "Bqrn~V", "^:CF", "^:CC",
"ZOW|", "e{gg", "ZOW9", "?*WR", "e6,o",
"?*W2", "m*M1M1", "P+%E", "no8>kX", "&,83",
"wz/K", ";|`<", "%6HT", "%6HQ", "@7o5@7o5",
"%6H5", ">f@7", "%6H1", "wz//", "a5J,D,D",
"nordeste-idc.saveincloud.net", "!tiL", "s%d\"", "6LJJGJG",
"it.unimi.dsi.fastutil.ints.Int2ReferenceFunction", "iMrL", "m%6%6",
"E~6,#", "o=\"B,", ")q!L", "'Zj3", "S_dd",
"setWasTouchingWater", "!aH.MlMl", ")q!,", "fcZZ",
"fcZC", "Pp/8)|", "wKc=c=", "{`00", "nf44",
"SBXH1H1", "@>V,H", "o;>dd", "6,~Z", "P+&J",
"{`0H", "?*PB", ")<)$H", "jC<EI", "&,72",
"{++,#0", "&,77", ";|aJ", "%6I1", "%6I4",
"%6I6", "U@+H", "(Lnet/minecraft/class_761;Lcom/mojang/blaze3d/buffers/GpuBufferSlice;IF)V",
"%6IS", "%6IX", "%6I\\", "%6IC", "%6IK",
"X&dH", "ef\"f\"", "Ce^r", "X&dd", "o=\"Ec",
"SjfKcP@wn", "N_wj<?", "JeVsI", "(*rp2", "iMqq",
"fc[[", "FJoI", "LIGHT_MATERIAL_INDEX", "cFVgM", "6lJHH",
"K%=9", "H/`/`", "Nt<NN", "nf7d", "ZOUJ",
"ZOUU", "?*QN", "C!?+H11", "frames/0132.png", "ARIrH1",
"H:]2!$a", "yKZkV", "%6Na", "6,}2", "%6Nw",
"wz)(", "%6NI", "ko!D", "%6N\\", "%6NX",
"5Vg<", "_==+x==8", "CeYY", "%6N(", "ko!o",
"U@,;", "U@,,", "!tke", "U@,S", "jUpH",
"jUpF", "iMpj", "iMpp", "FJny", "s%ff",
"iMpV", "6m>HH", "s`--", "<=~\\", "<=~'",
"Vkd|H", "'ZT)", "r_sE", "v~/X|", "K%<<",
"e{h0", "m)j%H1", "8DRW", "nf6B", ">>>3>L>LLf>ff",
"?*RC", "66\\6MM\\J\\d\\Y{\\\\\\", "}2]HH", "&=Qp7^", "*9qH1",
"G-fHG-fH", ">%3LH", ":zTCs", "^E%9d", "5Vdg",
"X&jj", "/`H3QLdd", "6,|J", "c([Lnet/fabricmc/fabric/api/client/message/v1/ClientSendMessageEvents$AllowChat;Ljava/lang/String;)Z",
"U@-I", "Yyvpn", "%6O=", "@p66", "%6OP",
"%6O\\", "%6OX", "%6OO", "%6OL", "o-\"~b",
"!tlB", "&~!z0", "w1sJ", "!tlu", "0zt!!",
"S_aa", ")q>]", "iMww", "oN&ATAT", "x-M-M",
"uFiBm", "Zlb^0~", "-yJC_OI!I!", "dMnv", "TRSRS",
"^:GH", "l$tD+d$h", "KP4.H", "8DUC", "5Vee",
"5Vem", "5Ve;", ">fL3", "%6LN", "ko_I",
"1@!H1", "%6L(", "x(qH1", "X&ii", "%6L>",
"%6L3", "BH3I\"\"", "!tmn", "!tmm", "jUr3",
"o=\"F#", "$G<a", "o-\"ay", "s`++", "S_`.",
"'ZV6", "sZ1$1$", "fcVH", "ZOPA", "fcVV",
"`)`7`BX", "z'8II", "RUQQ", "vWuL1", "e61B",
"dMoo", "7t]]", "dMor", "FrXo#o#", ";|ec",
"%6Mi", "&,33", "%6MZ", "%6MR", "%6MM",
"o#NRR", "wz4l", "%6M=", "%6M:", "%6M$",
"5VjH", ":J@=H", "IEE/II^?IIxHII", "w1}", "_NkA_NkA",
"S9H19H1", "o-\"`f", "FJcc", "FJcE", "<=}}",
"ASdWv", "o=\"I!", "&MIMI", "(Lsixtwo/ov;Lsixtwo/ov;Lnet/minecraft/class_1297;)Lsixtwo/ov;",
"BLeHz", "ZOQF", "^6H6H", "k./.]L/.]L", "RURR",
"dMll", "FTpfr", "?*mI", "5VkB", "tze|#",
"5Vkn", "5Vka", "&,22", "%6R>", "&,2h",
"s%bb", "&,2C", "&,2I", ">fNN", "s%bF",
"%6Rx", ".$H$H", "CeE#", "%6RU", ":4FUH",
"X&oJ", "o-\"c1", "0{oH1", "GvQE", "!toI",
"getPlaintextString", "'_Nbs9&O`", "S_nD", "o=\"Hv", "jUtC",
"$G>I", "fcTJ", "e{ll", "$G>>", "'ZPK",
"<=bG", "B5Z6", "^:HH", "nf2H", "B5ZZ",
"^:H3", "^:H1", "method_32840", "e677", ".w6'+!I",
"%6Sg", "%6Si", "%6Sl", "`6SI~", "CF)G)G",
"X&nN", "ko\\B", "%6S_", ">fI!", "%6S,",
"X&nl", "wz6A", "5Vhz", "X&n:", "')[-=VV",
"jvrW\"", "o=\"Kr", "o=\"Kj", "o=\"KY", "s%mo",
"?_pH1", "q?<H1", "uFiFi", "fcU7", ")q:m",
")[JP5[JP5", "ZWFHFH", "e/y2Q", "e{oo", "e{ol",
"hA`A`", "nf=t", "UYB_t", "8DI1", "UUQTH",
"Zpff", "5|q|q", "7tXX", "DPH1H1", "P+==",
"@+tL", ">\HQTrI!", "P+=m", "0:&f0k", "s/O&H&H",
"5ViK", ">fH1", "X&ms", "5Vi{", "Ca$-$-",
"}PzKZ", "Windows.Internal.Accessibility.AccessibilityToolSettings.GetMagnifierZoomFactorAsync",
"%6P+", "ko[=", "u*K25|5|", "%6Pr", "%6Pq",
"%6Pe", "%6Pa", "y|/nH", "sixtwo/rq.class", "o-\"e'",
"e)9H1", "o=\"Jw", "fcRR", "fcRZ", "fcRC",
"iMJJ", "FJdd", "e{nn", "K%:#", "Windows.Storage.FileIO.WriteTextAsync",
"N7-Fb", "<=``", "{C-<9", "1aVq(]", "^:J)",
"ZO\\", "nf<3", "8DH1", "dMc)", "HOeZR",
"5Vn$", "@+uu", "@+uH", "%6Q[", "%6Q]",
"%6QQ", "%6QW", "@p,J", "%6Qi", "%6Qh",
"%6Q{", "wz0-", "%6Q}", "%6Qr", "net.caffeinemc.mods.sodium.client.render.viewport.frustum.Frustum",
"GvTT", "%6Q(", ".Ljava/util/Map<Ljava/lang/String;Lsixtwo/in;>;",
"%6Q,", "X&ll", "%6Q3", "X&lL", "CeFF",
"AsyncOperationCompletedHandler`1<Windows.System.AppActivationResult>", "X&l[", "gKLHH", "o=\"Ma",
"w1y`", "FJgZ", "iMII", "w1yL", "o-\"d>",
"FJgg", "!Mm6FR", "<=aC", "iMI!", "iMI1",
"kl'P<E'P<E", "o%)Zr", "K~|H", "$G99",
"rorrrVrrr<rrr#rrrrrrr", "o%)Z)", "ZO]]", "nf?L",
"vVEuEu", "e6::", "903--", "dM`)", "e6:I",
"Zpdd", "7tfL", "]|NVw", "P+??", "6c<{",
"P+?3", "&,NA", "%6Vw", "%6Ve", "%6V]",
"koYb", "L]#n", "6,uu", "%6V4", "5Voe",
"koYF", "@p/H", "%6V*", "5VoH", "Tukic",
"w1xx", "s%nE", "%xfxf", "iMH1", "2X/v)Ct",
"ovXrr", "ht%S!H", "<=ff", "<=fJ", "/8'4:;",
"r_kk", "l=/ts", "K%44", "o%)[|", "o%)[r",
"cH3ALL", "^Hv.n", "dMaF", "nf>5", "^:LL",
"nf>K", "nf>M", "8DJW", "6,tt", "8DJv",
"%_.rr", "5Vll", "H6jGm", ";|oC", "5Vl*",
";|oo", ">fUH", "&,MI", "%6Wm", "%6Wg",
"%6Wc", "%6Wx", "%6Wt", "%6WJ", "2UAA",
"%6WX", "Ce@C", "X&R@", "o-\"fB", "D$LbYt",
"o-\"f8", "3crMM", "!tdh", "!tdH", "eJiH1",
"S_iI", "o=\"O>", "fcQ.", ",2]I]I", "o%)\E",
"e{sG", "b@}eff7Q7Q", "'Z]m", "'Z]D", "MDLrI",
"6c:J", "B5_m", "B5__", "\"EZ60", "oGyaa",
"e688", "H3kFSS", "nf99", "%^A+=", "<cMnMn",
"yKZ]U", "oY3Y3", "HBAij", ";|l\\", "%6T{",
"%6TH", "%6T]", ">fT/", "%6T4", "GvWD",
"){|;H1", "iMNN", "FJxI", "s%hh", "o=\"N%",
"o-\"iw", "H{%%", "s`33", "2k'J%", "<=dA",
"'Z^A", "uOWOW", "o%)]|", "s`3t", "7qHqH",
"r_ii", "S_hh", "(iIiI", "onv-onv-", "ZOXF",
"RUYY", "xP55", "^:NN", "e{rQ", "\?4.@",
"8DLL", "?*dg", "xP5K", "Zpa%", "!+=&P+=&P",
"od$&&", ">=EZ[", "P+:H", "o+HYY", "X&PQ",
"CeBB", "H5#nBpH", "&,Ka", "%6UU", "%6UY",
"@p(8", "%6UX", "2UCC", "H+*ZZ", "field_62791",
"%6Ua", "%6Uc", "%6Um", "koVb", "6>yfII",
"GvXC", "|=Q=Q", "H{&D", "ipc&Z", "H{&&",
"K~x|", "r_ff", "8!IlH", ")q4H", "$G5-",
"$G55", "iMMM", "6oH1oH1", "$G5`", "e{uu",
"n\"h|0", "$G5J", "'Z__", "<=eF", "'Z_C",
"^-%LL", "Windows.ApplicationModel.Contacts.ContactStore.GetMeContactAsync",
"o%)^l", "!_8c034754b046ad13ec5908e0fd796ac4", "RUZ,", "@!HHH",
"A/2*8", "6c8P", "Vn.k.k", "e6>E", "nf;'",
"m@I1", "m@I@", "m@II", "/*<<", "%6ZZ",
"/*<j", "%6Zi", "%6Zc", "%6Z~", "field_62789",
"field_62787", "field_62786", "nCY8>", "&,JH",
"r<_H1", "L]'K", "L]'E", "koUn", "H+*[[",
"%6Z0", "%6Z1", "koUH", "CeMM", "%q#m",
"%q#V", "%q#\"", "%q#+", "%q#>", "qUJqUJ",
"i4V'h4V'h", "jUll", "YF,F,", "o-\"kV", "FHk.@j",
"s(('sBB@s[[Yssuoss", "s`1L", "U#%@U#%@", "C4)^r",
"vT{4~=", "B5BE", "d$,A!", "e{tI", "]Bg\\v",
"RU[C", "`pWpW", "^:PP", "\"\"DDDDD", ";/*q_",
"@+ss", "P+44", "-M)-M)M)", ">fQQ", "&,I1",
"%6[f", "%6[^", "2UEO", "/*=K", "2UEH",
"%6[H", "X&VL", "CeLL", "%6[=", "YM88",
"%6[#", "%6[%", "wz>>", "jUmI", "FJ}z",
"x(qSH", "FJ}R", "H`0`0", "%q\">", "o-\"j\"",
"#W)W)", "%q\"X", "%q\"_", "'ZYE", "%q\"b",
"%q\"f", "qmwmw", "%q\"n", "()Lnet/minecraft/class_9145<Lnet/minecraft/class_8593;>;",
"KOjhv,HH", "o=\"SY", "o=\"SC", "s`>>", "w:G.C",
"_3g{", "(Ljava/lang/String;Lsixtwo/lf;Lsixtwo/ai;)Lsixtwo/ap;",
"$G7F", "e{ww", "/+]:-@", "o%)P\\", "xP66",
"RU\\H", "e6<G", "7t`I", "B5CH", "1vU,H",
"nf%H", "B@\"@\"", "m@KH", "?*gE", "=vV+=vV+",
"Zpnt", "g*y@j@", "&,H1", "7qJe),r", "777w776]77/D77\"*7*",
"%6X<", "L]%%", "/2ruP", "PhoneInternal.Experiences.Sync.Account.SyncAccountAsync",
">fPo", "s%tD", "2UFk", "%6Xq", "%6XC",
"%6XW", "jVR:;KH", "%q!b", "%q!o", "%q!l",
"%q!m", "%q!t", "%q!~", "%q!z", "')->+@+@",
"K~{E", ")K6__", "previewBounds", "S_t^", ")q1>",
"TOs2H", "_3fH", "iMBW", "J|<I1", "<=hv",
"'ZZJ", "RU]]", "'ZZZ", "k;VmVm", "ZO$#",
"nf$L", "B5DB", "Eo'o'", "5k8]8]", "3SUUU",
"m@L,", "7taa", "uKHKH", "owY''", "q^>[JH",
"#CZ;``", ">fSS", "%6Yg", "%6Yj", "2UGt",
"%6Yx", "YM>W", "koRR", "%6YG", "X&T@",
"==F=L", "X&TM", "%6YT", "4i&xg", "%6Y/",
"6,nw", "YM>>", "o5dmI1", "!tzz", "<4CVE",
"o=\"Ug", "_3em", "o=\"UT", "jUoo", "iMAJ",
"h2!gh2!g", "4qH1H1", "0&N*N*", "$G1X", "old>>",
"'Z[@", "$G11", "<=i!", "r_bT", "o%)RR",
"~NJN~NJN", "S_sw", "RU^J", "RU^y", "xP00",
"ZO%5", "?*aa", "Zpll", "<efM9", "6c40",
"P+77", "pjMscI", "6c4z", "6c4y", "@+nI",
"=P58585", "P+7H", "@@Z&@@r6@@", "H+*__", "wz9L",
"CeI^", "CeI1", "X&[5", "&,FF", "|=rr",
"2UH1", "~c`E`E", "%6^^", "2UHH", "%6^K",
"s%vv", "zwwwwww", "0%mR%ml#l#", "%6^e", "%6^b",
"YM=w", "Gv],", "o-\"o\"", "%q'e", "%q'c",
"%q'w", "r_cc", "%q'N", "%q'H", "%q'Z",
"jU`D", "U6x6x", "o=\"T@", "_3di", "RU__",
"'ZDE", "71$4", "Jr>%X", "o%)SJ", "o%)SM",
"xP33", "H3rW**", "P+0K", "ifHfH", "8DBL",
"F5tYs", "_;I?/", "&,E'", "2UII", "LLLvKLL\ACLC0)L)",
"2UIM", "2UIL", "%6_H", "%6__", "%6_Y",
"%6_a", "|=sI", "field_62778", ">f]H", "CeH1",
"&,EE", "Gv^^", "s%qE", "%6_\"", "2UI1",
">#fH", "!t|:", "%6_9", "bDEiA", "X&ZZ",
"CeHH", "DiLjJ", "%q&b", "%q&5", "%q&&",
"u]u]u]", "c_91:Xw", ";cQ);cQ)", "wNJnN", "<=oH",
"NJ.,.", "yPPJQ", "s`:I", "S_qD", "o%)TR",
"D$}dl", "B5GA", "K%/W", "pgNgN", "d$,D1",
"^:WC", "xIw>\"-", "XN7I1", "nf!C", "/nc|S",
"?*cc", "7tlR", "6c2B", "7tll", "@+hh",
"/*:!", "EeChM", "n.-y+", "P+1H", "P+1_",
"&,DD", "%6\\k", "%6\\g", "%6\\d", "%6\\Y",
"%6\\\\", "%6\\P", "2UJJ", "%6\\J", "2S(sh",
"6,kD", "%6\\G", "CeKH", "@p!D", "%6\\7",
"%6\\4", "%6\\\"", "YM3'", "0$I$I", "L]))",
">#gg", "zIzz`I``IIGIII-III", "|=pG", "%dodo",
"%q%q", "/p;S;S", "'ZFI", "s`;;", "S_p_",
"_`H11", "ooIWW", "$G,,", "e{zl", "WEZBM",
"kQO|]MV", "/yt#w-", "LxOhL", "71&V", "B5H1",
"B5Hi", "6c3p", "/*;G", "ulITe", "m@@/",
"6,jj", "/*;;", "?*|F", "HVg86HH", "Zpii",
";|UU", "%6]4", "H&aa", "|=qd", ">f__",
"xkojdyt1e3s8bml2x17mtokk", "%6]g", "%6]p", "f}+Pp",
"%6]C", "uH,0H,0", "%6]X", "%6]P", "%6]R",
"%q$A", "9s2I1", "s`8I", "f.!{s", "K~p@",
"r_^B", "K~pI", "s`88", "o=\"Yx", "%q$<",
"&XA#)", "jUcE", "jUcQ", "iMEk", "_3aa",
"<:jH1", "i0wyA", "mLmLmL", "o%)Vh", "g/ExceptH",
")a&I}", "<=mF", "o=o\">", "i.L.L", "B5I1",
"ZO!'", "-M1M1", "WEZEZ", "B5II", ";Q2em\"",
"@+jF", "wR~D1W", "sixtwo/fr$$Lambda", "1(Ljava/util/List<Ljava/lang/String;>;)Lsixtwo/iu;",
"ZphK", ";|Z{", "7(Lcom/mojang/blaze3d/vertex/VertexFormat;[Lsixtwo/jM;)V",
"%6bb", "%6bd", "%6be", "%6bg", "%6bs",
"2ULC", "={WQA", ";|ZL", "%6bH", "koMM",
"%6b)", "2UL1", "]b+$]b+$", "%q+b", "%q+T",
"=N_Jq", "%q+O", "jUdE", "fM+Xy", "%q+(",
"o=\"XJ", "o=\"XG", "H>:_x", "qS%/[", "'Z@L",
"'Z@H", "$G.G", "PHKHK", "'Z@g", "<=R)",
"o%)WO", "H{/L", "I7\"I7\"", "5bu1I1I1", "e{|E",
"K%(@", "xP??", "nf\"G", "Zpww", "b0/I",
"m@BB", "ZpwH", "oxMnn", "brightness;factor", "o^|77",
";|[[", "Mwkm*WW", "/*5/", "7obf_", "6,hh",
"6,hA", "X&^_", "gD;z;z", "%ZK:9I", "%6c8",
"koL!", "%6cU", "%6cX", "%6cB", "%6cK",
"%6cM", "|=wL", "%6ce", "%6cl", "%q**",
"%q*$", "H{(B", "o=\"[=", "%q*}", "wrGWA",
"%q*^", "S_}}", "fceW", "Hs:s:", "K~r0",
"FJuu", "fce{", "_3oo", "K%+D", "(Ljava/util/Set;)Lsixtwo/cK;",
"<=SK", "/gyg", ".?AV?$_Func_impl_no_alloc@V<lambda_84>@?0??initClassRegistrars@@YAXXZ@XPEAUJNIEnv_@@PEAV_jclass@@@std@@",
"7thz", "e6DD", "b0.N", "jdk/internal/net/http/frame/PingFrame",
"}6PKi?", "6,gg", "/*6I", "6,gH", "8Dy^",
".?AV?$_Func_impl_no_alloc@V<lambda_317>@?0??initClassRegistrars@@YAXXZ@XPEAUJNIEnv_@@PEAV_jclass@@@std@@",
"2iHiH", "%6`F", "%6`G", "%6`B", "%6`@",
"@+dU", "%6`X", "%6`Y", "%6``", "HY^0!",
"GvCI", "$g5bP", "tngvr", "%6`.", "%6`+",
"X&]n", "H1|#|#", "%q)_", "koKK", "%q)T",
"%q)t", "!tq}", "%q)h", "K~sx", "K~ss",
"r_]]", "o=\"ZO", "%q)+", "%q)'", "jUfJ",
"jUfH", "=6:p", "/c3(Q\2,L", "<=PC", "<=PL",
"_3n;", "o=o!M", ";[B)f$,$,", ":^^H^H", "o%)I!",
"o|$@H", "o|$@I", "fc&I&I", "softness", "^VH11",
"T(Lnet/minecraft/class_243;Lnet/minecraft/class_1657;Ljava/util/function/Predicate;)V", "b0-I",
"fcbb", "K%**", "71\"I", "8Dx[", "Windows.ApplicationModel.Appointments.AppointmentStore.ShowAppointmentDetailsAsync",
"?*xF", "A)3Y3Y", "7tiI", "Pb]6-", "e6EH",
"7tii", "`\"`$`2`'`@`\"`", "/*7=", "6~*OI", ">f[[",
"h?4dc", "HeSH1SH1", "%6ak", "L]2H", "%6aa",
"X&\\", "6,fH", "%6aK", "L]2o", "koJH",
"%6a8", "H+uqbb", "%6a0", "%6a2", "%6a*",
"%6a%", "X&\\g", ".$H11", "GvDD", "LinkId=521839",
"_3mH", "_3mF", "iMYG", "6]N=ZD", "%q(5",
"%q(#", "/[i/[i", "%q(B", "%q(E", "%q(L",
"%q(O", "<=QQ", "%q(v", "renderScoreboardSidebar", "H{**",
"{kZkZ", "K~ly", "K%%I", "net.caffeinemc.mods.sodium.client.render.chunk.LocalSectionIndex",
"`M2V00", "IAsyncOperation`1<Windows.Foundation.Collections.IVectorView`1<Windows.ApplicationModel.Email.EmailMessage>>",
"=6;C", "o%)J6", "$G)`", "sZA\"ZA\"", "play.zenitmc.com",
"b0,Q", "H5e`P=H", "^:]A", "^:]I", "/*0u",
"?*yH", "m@EE", "m@EH", "?*yR", "?*yy",
"@+fI", "+Fca`H5", "@+ff", ";|^^", "%6f8",
">fZ;", "koI1", ">fZZ", "%6fn", "L]3F",
"P=5,Y", "%6fH", "%6fF", "%6fB", "E(#*H",
"D$LbJd", "koII", "!ts5", "org.jose4j.lang.InvalidKeyException", "Ce1Q",
"!ts>", "@p_X", "X&C~", "X&Cj", "%q/m",
"%q/o", "$*/iq9", "%q/s", "%q/~", "r_[[",
"o=\"\\B", "r_[L", "c8/wS", "%q/'", "%q/\"",
"%q/?", "=68E", "_3le", "FJvv", "=68Z",
"FJvD", "iMXE", "iMXX", "DknBJ", "o=o'L",
"o%)KK", "o=o'H", "K%$^", "f?o{w>", "71,I",
"H3GE00", "BnHnH", "*Lorg/apache/commons/lang3/text/StrBuilder;", "xP;C", ">+e+e",
"h<DD<DD", "8Dz(", "m@FF", "e6KI", "\"net/minecraft/class_4717$class_464",
"7twj", "ccnKH", "^w'/", "/*1<", "%6gS",
"%6gH", "@p^^", "%6gx", "%6gm", "%6gj",
"X&BH", "koHH", "koHK", ">f%%", "GvFf",
"YM4b", "%6g<", "%6g4", "%6g/", "YM44",
"L]0I", "koH1", "%q.s", "!ttK", "%q.e",
"pN2Ga", "3xixi", "%q.I", "%q.8", "%q.'",
"%q.#", ":$FII", "s%yH", "s%yI", "FJII",
"FJI1", "}rO!H!H", "(Lsixtwo/R;)V", "'ZMH", "q1qrIrI",
"$G+K", "&@&&@&&", "o%)Li", "r_XX", "+nK!g",
"S_yy", "f/N/N", "QhAhA", "b0*I", "o=o$Y",
"M8px<", "qzss", "Sy,y,", "8D}a", "x1>BF",
"8D}_", "OK43W", "219H3}33", "ZO++", "qzsI",
"qzsH", "xP:K", "?*{{", "xP:G", "oHass",
"m@GG", "A|iqSIqSI", "ZprH", "Zpr'", "e6HH",
"H1F|F|", "QaZaZ", "/*2@", "8<*D)/~~", ";|\\#",
"/*22", "m$'Y}", "XO[5$", "`~v!m", "X&A/",
"%6d:", "%6d<", "%6d'", "%6d)", "%6dP",
"%6d_", "%6d]", "2URC", "%6dF", "s%xq",
"YM+H", "YM+I", "%6d|", ".#6z", "os*os*",
"%q-<", "]::G$", ">#oK", "%q-s", "H{55",
"%q-U", "FJH3", "FJH1", "08}C-r", "fc~~",
"71.G", "(Ljava/util/Set;)Lsixtwo/cF;", "=6>_", "qzpE",
"qzpA", "$G$U", "qzpL", "o=o%$", "Y=*N-N-",
"see_through_nametag_bg", "zSH3??", "/w8~8~", "e6Ih", "ZfXfX",
"B5pm", "ZO(E", "j$I;E", "6c+(", "drJB#drJB#rJB#B#rJB#",
"1)4n}", "ZO(p", "^:^I", "i$OBd", "^:^^",
"6,bb", "8D|q", "6,bP", "?*tt", "m@XH",
"?*t]", "sound_entity", "%6eA", "%6eU", "%6e_",
"s%{u", ">f'A", "L]6H", "s%{K", "i]fHfH",
"GvH_", ">f']", "%6e-", "%6e/", "%6e4",
"koFG", "%q,I", "%q,H", "H3Br||", "%q,y",
"%q,t", "%q,m", "GvH1", "r_VH", "iM]I",
"jU[B", "$G%P", ".#7K", "$G%V", "o=o*j",
"~ont!n", "H{6^", "o=o*\\", "MDLDL", "'ZO#",
"BfNfx", "!\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"",
"o%)N2", "m<'e?", ";CzNbIbI", "B5qq", "d4#SO8",
"qzqz", "xP$D", "?*uu", "6c(B", "@+bF",
"@+b~", "/*,,", "g`9H1", "%6jx", "%6js",
"(Lnet/minecraft/class_8734;)I", "%6jf", "%6j_", "%6jP",
"6,aH", "6,aI", "H+*KK", "@p[S", "L]7&",
"L]77", "GvI1", "~|$xf", "l(Pl(P", ";uS*>",
"iM\\", "FJJJ", "5p\"9u", "%q3U", ".#47",
"%q3Z", "%q3E", "%q3t", "sssiiseOOsN66s5", "<=ZF",
"%q3g", "'ZH1", "qmw\\L", "!]YS:", ".H3X_UU",
"=6<E", "sfXtW", "{$,D}", "$G&W", "qzvv",
"/grD", "/grr", "xP'X", ".?AV<lambda_322>@?0??initClassRegistrars@@YAXXZ@",
"^:`6", "w\"<3t", "^:`A", "^:``", "8D~L",
"FTpyk", "47vOI", "m@ZZ", "6,``", "!lL11",
"%6k4", "s%Ek", "\\aH1", "%6kb", "%6kd",
"%6k}", "2UUL", "2UUH", "koDl", "2UUU",
"%6k\\", "koDD", "YM(Y", "!tH1", "%q2E",
"%q2O", "%q2h", "\\aHH", "%q2w", "r_TT",
"!tHH", "K~j|", "%q2+", "%q2/", "FJM>",
"jU]]", "%q25", "y2I2I", "jU]H", "K~j:",
"$G'X", "iMSI", "_3w\\", "'ZI1", "[lI[XH]L1",
"$Q5oH", "qzww", "<=[x", "=6=6", "K%#\"",
"o=o(>", "T,+S]", "-knM7", "b0&G", "xP&&",
",]bA", "ZO77", "B5sH", "wO;fI", "?*wD",
"?*wF", "@n#@fH", "e6L1", "7tp>", "7tpp",
"PfHyp", "&,XW", "H+*II", "%6hN", "%6hF",
"%6h}", ";|@@", "Ce??", "MzWor", "nmMqMq",
"%6hh", "%6hi", "%6h.", "%6h'", "##rLL[I",
"!tII", "\\aI*", "%q1T", "%q1R", "%q1]",
"%q1N", "t<8.z6", "oo>oVV>V<>>>#>>>>>>>", "%q12",
"%q11", "%q1$", "H&nW", "d3cn3cn", "s%DD",
"_41aa17f6cc484d20c1339697c7d730f6", "H&nn", "=62h",
"<=XX", "'ZJB", "r_UX", "K~kI", "vZ-\"+Q",
"`'BL1", "H{1T", "o%)A!", "ERdyI", "b0%J",
"fczC", "sBjPTH", "dD?9t9t", ",]cI", ".S^Tx",
"K%\"U", "xP!>", "xP!I", "A9NX~", "6c'C",
"7tqH", "d.bWZq", "/*/*", "Q(Lnet/minecraft/class_1324;Lnet/minecraft/class_6880;Lnet/minecraft/class_1322;)V",
"L_!Nb", "L]:C", ">f##", "^w)D", "M)ZiZi",
"X&DD", "H&mH", "%6i)", "|=}}", "%6iY",
"%6i_", "koBB", "%6iq", "%6ix", "GvL0",
"GvL1", "H&m:", ">#h.", "%q0\"", "!tJO",
"!tJJ", "o=\"e%", "%q0G", "%q0\\", "%q0_",
"jb$$j", "phv0$0$", "fc{I", "=633", "vIpGi",
"0p~(8z", "o=o.j", "o=o.}", "$G!", "'ZKB",
"fc{8", "<=YJ", "K;.`.`", "b0$7", "o%)BW",
"7t~z", "Q}22", "/gwR", "/gw[", "ZO5*",
"B5uS", "b0$E", "qixtegq2qmoc4mfzw9qiarsc", "j$I$I",
"^w.D", "nfWH", "D-8Kh", "^w.I", "qfZfZ",
"?*qq", "zOGG", "zOGH", "(Ljava/lang/Object;ILjava/lang/invoke/MemberName;)F",
"iiXp0", "sNHVk", "QzaII", "cZoZo", "2UXG",
"%6n^", "YM-K", "%6nf", "%6nj", "P0ye.",
"%6np", "%6nz", "\\aGG", "GvMM", "<Zc[@D[@D",
"\\aGh", "\\aGa", "!_35acdb4389e7fb53e0f0280f4c9eb881", "%6n<",
"X&KK", "%q7Y", "koAA", "%q7D", ".Ljava/util/Map<Ljava/lang/String;Lsixtwo/pY;>;",
"%q7A", "Ce9X", "%q7x", "n|<wge", "%q7w",
"GvM?", "\"4[/g=", "r_Sa", "K~ee", "_3tH",
"_3tJ", "o=\"d~", "%q7=", "FJNA", "o=\"dx",
"%q77", "%q71", "%q7'", ">E25u5u", "H{33",
"~2xQ'", "<=^^", "<=^[", "'Z4x", "EuYFk",
"ad%H=", "$G\"\"", "Thoho", "3}M,,", "|BKMK",
"fcxj", "G(`1p&mL", "pXGXG", "LLLlLLLTLLD;L;4#L#",
"8Drr", "8Drf", "Zp{A", "URI11", "/gvJ",
"^Ue`L", ";|GG", "Ljdk/internal/net/http/common/SSLTube$DelegateWrapper;",
"s,xfH", "IAsyncOperation`1<Windows.Foundation.Collections.IVectorView`1<Windows.ApplicationModel.Chat.IChatItem>>",
"%6oq", "%6of", "%6oo", "%6oS", "%6oR",
"%6oX", "H+*LL", "lJr{Br", "Fct07sC", "%6o:",
"%6o&", "D$LbAx", "%6o#", ">f--", "@pV!",
"Ce88", "Ce8.", "@9yh@9yh", "BCLHLH", "iMWW",
"FJAV", "gH)<b", "_3sA", "%q6&", "%q65",
"%q6C", "%q6@", "%q6b", "%q6w", ":|Z]j",
"H{<<", "r_P]", "7177", "7171", "R8%;%;",
"=61B", "$G#T", "o%)D0", "ZO3x", "ZO3u",
"Q}00", "o%)DD", "o%)D|", "e6PP", "b0\"D",
"/guu", "^:g+", "b%7S7S", "nfQ`", "/***",
"m@__", "ZpzK", "^w,o", "'Z'H1H1", "l$@M1",
"^w,H", "'9;*H", "%6l)", "%6l$", "%6l0",
"H&rr", "pwDDDDD", "2UZy", "@pQg", "%6ls",
"X&I!", "%6lI", "%6lN", "X&I1", "Ce;K",
"2UZT", "@pQF", "%6lV", "%q5C", "%q5\\",
"!tMM", "K~gD", "jUR,", "3i+i+", "o=\"fu",
"%q55", "_3rr", "FJ@A", "eDUgW", "iMVV",
"$G\\{", "qzxx", "vJYJ", "'Z6K", "bjecf$\\$\\",
"o=o-/", "o=o-$", "B5x5", "/gt=", "^:fH",
"B5xx", "S2(2(", "b0!!", "B5xw", "^:ff",
"hA`\"L", "^:f{", "RK2jkc^", "IJ8J8", "nfPF",
"PfH|*", "class_2824.java", "&,SS", ";#`#`",
"(Lfivefive/A;Lfivefive/A;)Lfivefive/A;", "l$@L1", "%6m]",
"u=)bu=)b", "%6mL", "H+*BB", "%6mC", ";|EE",
"%6mm", "Ce::", "&,S=", "c*~>L", "^6r?Hr?H",
"\\aB@", "GvpY", "DiLxv", "%q4t", "X&H1",
"%q4`", "%q4W", "%q4V", "%q4M", "]::H1",
"%q45", "%q41", "%q4=", "jUSK", "o=\"ii",
"!p`{8", "FJCF", "<=]H", "t9?\\t9?\\", "field_48084",
"H{>M", "o%)FW", "r_NN", "'Z77", "%/?[$H?",
"0PM1", "711(", ",]dF", "Q}6]", "%nTeSI",
"/El]!", "`\"`@`<`", "hsxW@%@%", "e6VH", "e6VK",
"7tzE", "java.text.Normalizer$Form", ";|Jr", ";|JJ",
"Q2!\":\":", "V[YMdMJM", "El?HH", "H3OE77", ">f.G",
"^w2F", "~|$pH", "~|$pL", "L]??", "Go?o?",
"=uRQ!uRQ!", "&,RD", "%6r'", "H&pP", "&,Rr",
"%6rZ", "|=ff", "%6rC", "H&pp", "%6rI",
"fM+H1", "|=fH", "%q;/", "\\aCC", "\\aCM",
"Gvqq", "H{?i", "%q;i", "field_48099", "field_48098",
"field_48097", "r_OH", "field_48093", "%q;z", "fxPxP",
"%q;X", "%q;P", "%q;V", "\"'I::", "=64*",
"FJBA", "=642", "_3px", "o=o3D", "VJ<}H11",
"=64v", "NnH+=", "3(\"HH", "o%)GO", "0p+!(HH",
"zGxYZ", "xP//", "b0?J", "4fh!_y", "B5zw",
"^:hh", "RSA_USING_SHA256", "FTpAD", "nfRR", "%|)H1H1",
"zO@@", "zO@L", "ZpGG", "ZpGH", "ks+s+",
"!kCrr", "2U]C", "%6sG", ",W}kt", "%6s]",
"%6sj", "ko|-", "%6sm", "%6ss", "%6sr",
"-~f\\-~f\\f\\", "U@q)", "tarGf", "YYYfYRYLL@Y33*Y", "@pRb",
"%6s8", "X&NG", "%q:F", "%q:i", "2n$`",
"H1%*%*", "FJEE", "iM+A", "K~bI", "FJEH",
"\"IiIi", "1nAE2", "iM+`", "=65U", "<=CC",
"0POi", "0POr", "o=o0)", "fcuF", "fcuL",
"H3=3qq", "7132", "fcuu", "nf]]", "Q}44",
"|;GHH", "xP.=", "Q}4H", "xP.M", "ZO?G",
"8Dii", "h~n;#", "zOAA", "zOAB", "GHBji",
"xP.v", "\"!\\p\"!\\p", "7txx", "_W%H1", "^w0H",
"p1X^,", "gu'I=H11", "/*&J", "%6po", "%6pk",
"%6pZ", "H+*AA", ";|H1", "%6pO", "S35-E",
"X&MK", "%6p2", "%6p>", "@pMH", "@pMI",
">f(#", "%6p.", "%!)A)", "\\aAD", "!tAH",
"Ce''", ">#sP", "2*67&", ">f&>H", "|=dK",
"$.PM-@", ".#:L", ".#:H", "s%LC", "iM*m",
"_3~I", "C|2iL", "wq/Zm", "%q9L", "vJ]F",
"o|$PL", "%q9v", "~T$Xf", "c}1j'", "6(Ljava/lang/MatchException;)Ljava/lang/MatchException;",
"o=\"jo", "=6**", "JItz+L", "=6*D", "=6*K",
"/2\"?NQ\"x", "}X.HI!", "*Q>]*Q>]", "x9D2H", "712G",
"o%)yy", "b0==", "e6UJ", "b0=]", "Q};L",
"7tyy", "S`#9#9", ":<}@kc", "X]m5E", "^w11",
";|I1", "+(Lsixtwo/oi;)Ljava/util/function/Predicate;", ";|II", ";|IH",
"%6q)", "5'm5'm", "2U_4", "U@ss", "&,oo",
"|=ee", "H&uF", "s%O|", "%6qa", "%6qe",
"%6qw", "X&LL", "%6q[", "%6qQ", "%6qS",
"%q8E", "%q8H", "%q8T", "GvtG", "%q8v",
"!tBJ", "s>HxH", ">#pJ", ">#pL", "H{:L",
"H{:F", "H{::", "&K9&K9", "%q8>", "J+M>OGPTS^UtV|W",
"=6+^", "yfF\\T", "cmiYHH", "o=o6c", "Q}:I",
"b0<D", "o%)z?", "Q}::", "pOH11", "lU1I==",
"^:md", "El?L1", "e6Z?", "nf_H", "I*`kI*`k",
"Ft{I!", "J@[*H11", "ZpDC", "&,nH", "%6vF",
"%6vA", "%6vt", "%6vu", ";|NC", "X&3L",
">f*b", "Ce!!", "HPkHH", "Gvuu", "%6v(",
"1XZ9Z9", "%q?`", "%q?c", "jZe#e#", "%q?n",
"QcwrH1H1", "%q?G", "%q?3", "jUHH", "%q??",
"%q?:", "H&t*", "AOe<gqt<Taa<x}", "H+m>>", "s%NI",
"H&tt", "jUH1", "H{;;", ".#8M", "$GZZ",
"'Z<}", "$GZ;", "0PH1", "'Z<=", "'Z<.",
"ERdoP", "sixtwo/aoo", "8Djk", "Q}99", "^:lK",
"qzbb", "m<'PJ", "{%--", "xP+L", "zOLK",
"M'[8q8q", "aYzMH", "/gn\\", "e/Vvg/Vvg", "h.|h.|",
"zJbg'", "##H1H1", "A+~$'7j", "x#|I1", "^w77",
"X&22", "^)h'j", "U@uu", "O`v?r`v?r", "%6wD",
"%6wY", "%6wX", "%6wW", "%6wQ", "|=kF",
"%6w}", ")JB'}", "%q>$", "koxx", "s%I1",
"Bh\"fI", "!tDE", "%q>g", "%q>B", "%q>N",
"%q>W", "%q>T", "jUII", "r_H1", "booobVbbb<bbb#bbbbbbb",
",]nn", "&iud&iud", "o=o4F", "71?G", "$G[`",
"LZV80L", "sixtwo/ann", "xP*H", "Q}8L", "o%)|J",
"0PKJ", "Q}8`", "b0:|", "b0:{", "b0:K",
"%www%]]]%DDD%***%", "^:o}", "actionImp", "f!:y%", "8Dm(",
"=rgN0|N0|", "mixin/PlayerItemInHandLayer", "ZpBe", "om\"mm", "|=hh",
"%6tA", "%6tP", "m1ts4c", "%6tT", "%6t\\",
"%6tb", "@pI1", "%6to", ">f4H", "(TO;TV;)V",
"H&zH", "\\a]Q", "s%H1", "1r6KH", "Gvww",
"!tE#", "kowH", "kowI", "2n+H", "Gvw'",
"%q=b", "o$k$k", "o=\"n[", "!tEE", "o=\"nF",
"%q=;", "%q==", "K~_A", "o=\"nl", "%q='",
"W_t&<", "jUJJ", "$GTx", "<=Dw", "o%)}f",
"/`kgH", "WsGbA", "ZO88", "B5``", "b09;",
",]oo", "sixtwo/amm", "5doNDg", "nfXS", "Q}??",
"ZO8G", "j?(H(H", ",Z3FiH", "ohjYY", "/glH",
"e6YY", "/*#$", "%6uu", "%6ug", "YMZw",
"5V20", "%6uj", "2UcJ", "m|jug", "kovv",
"%6uN", "@pHG", "@pH1", "!tFF", "\\%3BAu?",
"!tFQ", "|=i`", "jUKK", "H+m33", "D$R([I)f",
"=xoxo", "%q<!", "%q<\"", "%q<=", "%q<A",
"%q<C", "%q<[", "%q<n", "vJPP", "%q<q",
"o=\"qQ", "'Z??", "r_FF", "=6//", "|G{H3",
"$GU3", "ZO9H", "sixtwo/all", "o%)~+", "Q}>>",
"\"pqZH", "eoMI1", "/gcC", "/gcD", "{%..",
"qza2", "e6^K", "Q}>E", "Q}>J", "o;>77",
"b2fHH", "nYcle", "5V3h", "~|$hH", "~|$hL",
">f66", "|=nn", "H&xx", "w#NLl;h", "e>L>L",
"%6za", "Ce--", "Gvy$", "kouH", "H+*{{",
"YMYN", "Ce-D", "X&7d", "!tG3", "%qCY",
"%qCc", "K~YY", "r_GG", "o=\"p^", "2n--",
"%qC&", "%qC+", "%qC2", "%qC5", "jULL",
"jULC", "field_48016", "field_48015", "field_48014", "uS8S8",
"iM,H", "v#~_?~_?", "0PDD", "718x", "o=o;r",
":]u]u", "<=JA", "H32{77", "Q}==", "$&(HH",
"&\\nI1I1", "sixtwo/akk", "e6_H", "nfZF", "^w;C",
"zOH1", ">f11", "@pJX", "%6{~", "5V0+",
"5V0)", "5V00", ">f1\\", "oYtEE", ">#zA",
"%qBr", "%qBp", "%qBi", "c%Rt", "%qBP",
"2n,M", "%qB4", "LlieL[(", "_3G;", "field_48028",
"field_48023", "!\"\"\"\"\"!\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"",
"b06q", "WaP7ZH1", "71;9", "JxU7M", "^:ss",
"o=o8X", "nfEy", "sixtwo/ajj", "Q}<<", "I{G:H",
"qzgL", "^:s'", "Ljava/util/stream/IntPipeline$StatefulOp;",
"{p{{vivvocoofZffZOZZLBLL<3<<*!**", "zOIH", "zOI1",
"zOI!", "e6\\", "e6\\W", "m'/$'f", "g7>7>",
"H5G0F", "H+*yy", "^w88", "zERoz", ">f00",
"}n9rT", "%6x&", "T8('x", "U@zz", "T8('H",
"%6x0", "%6xN", "|=ll", "%6x_", "%6x[",
"2UfH", "$>4H4H", "%6xc", "YM_Q", "%6x~",
"w$i$i", "@pEW", "%6xx", "%6xr", ".#\"F",
"%qA'", ".#\"m", "H&~?", ".#\"h", "%qA<",
"%qA=", "H+m00", "!tYM", "r_EE", "field_48030",
"field_48032", "r_EW", "o=\"r1", "%qAW", "jUNN",
"~T$@H", "vJU%", "~T$@L", "1+Ij@", "yPPo,",
"_3FH", "JHiHH", "RZmZm", "ku\\u\\", "o=o9O",
"`]1HH", "'Z::", "o%)q%", "0PF,", "'Z:>",
"o=o9k", ">Je{?", "<=H1", ")%RKV|H", "<=HJ",
"sixtwo/aii", "<=HH", "o=o9|", "$GPI", "qzdG",
"qzdW", "o%)qK", "!*zy{zy{y{", "zGxGx", "{%+R",
"B5dN", "o5)Ha", "vL1L1", "^:rs", "{/ZW^6",
"m@lB", "^w99", "%6yR", "%6yf", "&,gg",
"s%WW", "~7%a%a", "Gv|I", "H&}L", "H+*~~",
"kzlrxb", "YM^^", "@pDH", "%q@\\", "net/minecraft/class_2879$$Lambda",
"X&4H", "%q@T", "%q@M", "c%\\A", "2n.A",
"%q@i", "%q@c", "%q@g", "#g$w,", "o=\"uE",
"_3EE", "%q@5", "r_BB", "(Lsixtwo/mz;)I", "=6#L",
"<=II", "_3E)", "=6#f", "o%)rv", "hxUxU",
"<=I1", "'Z;I", "d$,ff", "5s54NsNMhshe", "8EFEF",
",]pI", "/ElAW", "sixtwo/ahh", "Q}""", "nfGJ",
"nfGH", "B5e9", "qzeh", "m@m@", "m@mm",
"Zx4OZx4O", "dM88", "^w>I", "pA$=$=", "Iw~II",
"b!'!'", "%6~w", "%6~b", "%6~i", "%6~Z",
"5V7R", "5V7v", "`k<<", ">#y\"", "U@|L",
"|=RD", "|=RR", "jU@@", "v@T@T", "s%V^",
"FJ^I", "2n1=", "QQ?Q?", "%qG;", "%qGH",
"%qGC", "%qGY", "G%D%D", "_`HSl", "K~UG",
")qoo", "mt3:Bd3:Bd", "ppMpM", "o=o?g", "sixtwo/agg",
"ig$>$>", "o%)ss", "/gfH", "PW=W=", "e6cc",
"B5fH", "e6c:", "dM9Q", "dM9I", "dM9H",
"dM9B", "m@nP", "unpackSL", "ZpKJ", "rFaBc",
"!|`I9", "M57896044618658097711785492504343953926634992332820282019728792003956564819949",
"ddd,dddEddd^dddwwwd", "&,e{", "H&CC", "9N%'&",
"|=S5", "Ce((", "(bHtw", "H+*||", "~eKq|mKq|m",
"Ce(_", "\\aTk", "H+m55", "\\aTT", "K~VV",
"%qFz", "%qFy", "%qFt", "%qFr", "o=\"wR",
"r_@@", "%qFe", "%qFc", "%qFb", "%qFF",
"c%^^", "%qFC", "c%^@", "vJVV", "x=I|I|",
"jUAJ", "r_@;", "=6!D", "_3C`", "6G.`|",
"_3CC", "0PCM", "FJQQ", "o%)tX", "3HHAH^^A^ssAs",
"$GSS", "'Z%E", "/D$pf", "b02A", "b02k",
"X#e'e'", "o5)K2", "cxui6089jg1ns3efut2eq25i", ".?AV?$_Func_impl_no_alloc@V<lambda_400>@?0??initClassRegistrars@@YAXXZ@XPEAUJNIEnv_@@PEAV_jclass@@@std@@",
"/ge$", "sixtwo/aff", "n.h.h", "E[uvcmm", "zOUU",
"^:w-", "NUH1H1", "8Dee", "m@oo", "Bte%@",
"nfAU", "QZjPf", "^w<k", "ZpJG", "ZpJJ",
"YMSS", "%6||", "%6|s", "YMSC", "%6|w",
"%6|u", "X&99", "%6|o", "Ce++", "koo{",
"7@}~*", "%6|5", "5V5i", "5V5w", "Ce+`",
"!_9a332a05423a1129ac34ecc3748fdd21", "%qEq", "%qEa", "%qEg", "Ce+L",
"2n3^", "9CH1H1", "o=\"vu", "%qE$", "s%PA",
"9W%GJ", "H+m44", "p#U#U", "H3;y;;", "FJP1",
"vl*=d_=d_", "o%)ut", "$GL1", "o%)ud", "=6&!",
"=6&/", "<=L\"", "\"=H1H1", ")qmm", "'oDoD",
")qmK", "8Ddd", "sixtwo/aee", "Q}''", "qzhK",
"qzhE", "Wrq|%#\"", "m@`c", "ZpIy", "/gdJ",
"ZpI1", "!_a69c5a5d7faa59bd52b04e85531def3c", "@pieT", "5V:/",
">f??", ">f?9", "/mv'v'", "Ce*u", "Ce**",
"`k??", "%6}/", "&,c]", "s%SS", "&,cc",
"|=Qi", "Hq_1+HH", "%mh(h(", "%6}Z", "kon=",
"@p@N", "%6}i", "%6}}", "%6}~", "%6}w",
"dQSyw", "%qD:", ">#DD", "+$\"r\"r", "K~PE",
"2n2n", "K~PJ", "c%XX", "K~P}", "jUCC",
"%qD\\", "vJH1", "FJSC", "_3AA", "$GMj",
"<=M1", "sixtwo/add", "<=MH", "9xA%^j\\L9xA%^j\\L^j\\L",
"o%)vx", "0P]B", "o%)vZ", "qzi9", "b00s",
"^:y8", "{%&E", "B5ii", ",3PH1", "^wBB",
"H(/(/", "ZpH1", "ZpHH", "Mc{eMc{e", "*B**8B88D",
"wGsUvGsUv", "~|$`L", ">f>G", "uUblZ", "H&@H",
"\\aSy", "%qKX", "~aIKfH", "@pCD", "2n5L",
"%qKK", "/!,[,[", "%qKt", "%qKh", "IM**",
"%qKa", "%qKg", "r_?b", "!t__", "IM*H",
"K~QQ", "WhD9c", "%v.$[I", "%qK7", "K~QL",
"o-\"3/", "r_?H", "pUUUUUU", "iM$$", "o%)ww",
"<=25", "{%!C", "{%!H", "B5jF", "{%![",
"=u{A7y<H", "{%!!", ",]uD", ",]uK", "#/<W6/<W6",
"qzn>", "sixtwo/acc", "lw:w:", "8DfH", "+(Lmixin/accessors/MouseHandlerAccessor;JI)V",
"Q}%=", "nfB{", "Q}%H", "qznn", "kb*G'%%",
"/gZF", "^wCC", "[>p%'U", "^wC?", "9!r[H1",
"df`RrW", "YMPK", "@pB#", "uLxTB", ">#Bb",
"U@ap", "|=WH", "U@aK", "1[MmMm", "H+m))",
".#-r", "o-\"2s", "%qJ*", "%qJ)", "%qJ/",
"s`fH", "%qJ5", "YoHoH", "%qJN", "l|PKH1",
"&G)UU", "%qJV", "%qJn", "o=\"{;", "%qJ}",
"%qJw", "%qJt", "K~RH", "=6%%", "qzoB",
"o5)OK", "=6%j", "sixtwo/abb", "0P_G", "Q}$:",
"0P_I", "o%)hH", "kcaEH", "Q}$F", "<X3{3{",
"P4!YFF", "^:{I", "SgUSgU", "nfMM", "0:9:9",
"^w@$", "!)jiLJ", "%(fhg", "K;gL1", "H5G1<GH",
"NW4W4", "5V97", "IM(r", ">f89", "H&FF",
"3IB?H?H", "2UnI", "X&=H", "H+*qq", "!OF==",
"Windows.Graphics.Imaging.IBitmapFrameWithSoftwareBitmap.GetSoftwareBitmapTransformedAsync",
"%qI=", "H+m((", "\\aQH", "Jdxk\"^", "?\\y(E/",
">#CC", "K~SW", "K~SS", "%qIr", "r_=H",
"%qIb", "%qIa", "%qIO", "%qII", "%qIB",
"vJMM", "$GH1", "<=0#", "_3NN", "*h6%e%",
"o%)im", "H+00@@", "rQ=3U", "Q}+L", "qzl&",
"B5l8", "/gXX", "dM3H", "{%#\"", "B5lz",
"sixtwo/aaa", "javax.crypto.spec.GCMParameterSpec", ";u@?aE", "H5G?]",
"H5PkPhH", "''X\"%o", "R:AAp", "YMVV", "<\"'H1",
"kojH", "fcGH1", "H+*vv", "yp(\"s6", "D$LbkN",
"IM//", "OWJWJ", "!x.`?", "%qH`", "X&<H",
"%qHh", "choppy", "r*;+p", "|=UI", "%qHH",
"U@cT", "%qH1", "%qH!", "%qH)", "s%__",
"FJWT", "_3MM", "iM9B", "r#\"#\"", "<=1B",
"K~L1", "<=1i", "r_:>", "o%)jc", "=6[-",
"r_:K", "0PYJ", "0PYE", "K~LL", "o%)j:",
"'Z##", "o5)AA", ")qhF", ",]xx", "o5)Az",
"SE\"v4", "B5mI", "o5)As", "o=oFC", "o5)A!",
"zO_H", "dM00", "e6jj", "OheB&I", "ZpTT",
"e6jF", "3&U&U", "o_w$H", ">f::", ":~3vL",
"U@d,", "5V?M", "&,~F", "lv+v+", "|^u{lW",
"IM.i", "Q;vwcV", "YMU5", "2Upp", "|=ZH",
"koib", ".#(B", "YMU}", "\"A*&U\\", "%qO1",
"\\aoL", "Gvee", "K~MM", "%qOr", "%qOx",
"o=\"||", "iM8H", "V\\oI1", "+nKF-", "r_;D",
";|!wH", ":B?B?", ",]yS", ")qg;", "'Z,,",
"z5?m?m", "=6XA", "'Z,F", "=6X[", "o%)kj",
"/g^^", "LtBgs", "z~Ug5", "^:||", "mNnhnh",
"nfNu", "4B2#X!H1H1", "ix#x#", "cy^I1I1", "hm={I",
"^wGr", "1Xq6~6~", "Elrd+", "YMT5", "|=[_",
"*EgH1", "startAttackPre(Lorg/spongepowered/asm/mixin/injection/callback/CallbackInfoReturnable;)V",
"P=5Oi", "\"0oo", "l$@fI", "l$@fH", "l$@fM",
"l$@fL", "\\all", "@p~c", "%qNP", "%qN]",
"%qNG", "%qNI", "%qN~", "%qN}", "%qNk",
"IM-T", "r_8}", "UN(N(", "iM??", "%qN=",
"%qN$", "H+m--", "i,#P`Z?s", "-0b^NJ4;", "=6Y\\",
"=6YC", "$GKK", "'Z-=", "cDDDD", "o=oDr",
"iM?H", "iM?I", "o=oDN", "0P[[", "o|$//",
"$GK-", "OSTT", ")qf)", "<=7A", "mixin.sodium.SodiumBlockOcclusionCache",
"V*QfHH", "{%<^", "B5oo", "e{#K", "|,DNH",
"Ughgh", "j2(s|h|h", "nfI1", "m@gg", "/g]]",
"(_4_4", "^wDL", "&,||", "a]##", "Uv7*4",
"&,|!", "5V==", "H+*uu", "\"0nS", "\"0nI",
"SZ8H1", "5V=k", "IM,F", "H+T:==", "!tUU",
"c%AA", "U@fE", "U@fH", ".#VI", "oe)Ae",
"_3JX", "_3JJ", ":org/jose4j/keys/resolvers/HttpsJwksVerificationKeyResolver", "FJ(6",
"wdwwdd]dddDddd*ddd", "%qM;", "iM>>", "2n;5",
"iM>;", "FJ((", "%qM1", "%qMH", "%qMM",
"%qMF", "%qMo", "c|I!I!", "'Z.V",
"\"\"\"\"\"\"\"1\"\"\"\"\"\"\"1\"\"\"\"\"\"\"", "o=\"~7", "%qMq", "r_9r",
"Mj}36", ")qee", "o5)DD", "o=oEE", "e{\"^",
"vw::", "o=oEJ", "Q}/l", "gH3F!!", "(Ljava/util/List;F)F",
"nfH1", "nfHH", "\"0mm", "Bu@{^=y", "OMNOMN",
"XXX*XXXDXXX]X]]wXww", "^wEH", "\"ga5Vs", "`6`b`O`",
"2Us)", "U@gg", "s%[L", "H&I~", "(onzh",
"MJDE=;", "|(III", "kofJ", "HIbI1", "YMJH",
".#WW", "\\ajj", "%qL?", "H&I1", "%qL4",
"o-\"8,", ">#L1", "(((w'((^\"((D", "!tV|", "c%@e",
"!tVo", "%qLc", "%qLT", "%qLP", "2n::",
"l)W*Vj", "OSRC", "K~H1", "iM=C", ":0G^",
"o%)ns", "y=patLtL", "o=oJ:", "2KgKg", "/gSI",
"XJKaZ", "?h_b}", "Ngjsgjs", "555t554Z55,A55", "5J'J'",
"nfKK", "q3BT1", "^wJJ", "a]!Z", "KZq9\"",
"/sCNH", "\"0lI", "z0\"\"", "koee", "`k00",
",(Ljava/util/Map;)Lorg/jose4j/jwk/JsonWebKey;", "\"0ll",
"\"\"\"\"\"\"\"!\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"",
"YMI1", "(Lsixtwo/mT;)Lsixtwo/X;", "5V#p", "5V#z",
"YMI!", "X`%Rn", "%qSz", "%qS|", "~|$XH",
"%qSl", "%qS]", "~|$Xf", "H&H1", "H&H'",
"%qS/", "_3HH", "o-\";/", "o-\";,", "H+m\"\"",
"e[B[B", "GF^I1", "%7EHEH", "/ifd/exif/{ushort=42240}", "_3H1",
"$GFJ", "<=:K", "FJ**", "'Z(L", "G0IQIQ",
"o%)oc", "r_77", "+GJ\\M", "RZmHH", "`Hykrll",
")qc\\", ",]}}", "o5)Fz", "e{$G", "qzVe",
"o5)F9", "OowDg", "vw85", "\\K8\\K8", "m@zW",
"`&~~", "m@zL", "/gRY", "PfHfH", "/_L_L",
"jjd;<", "\"0kk", "MDN^v@&Q", "^wKI", "^wKB",
"ZYrF{", "X&&J", "y?>?>", "z0!!", "z0!(",
"|=_!", "sixtwo/nN.class", "z0!E", "Y+Kts", "YMH1",
"|=_C", "H&O(", "%qR2", "\\ahh", "s`nI",
"H+m!!", "%qRc", "%qRb", "%qRd", "%qRx",
"c%BB", "%qRF", "2n<J", "h7hhN7NN5777", "%qRQ",
"?5.5xIxI", "%qRT", "vJBE", "OSPP", ")qbX",
"OSP&", "iM3L", "FJ-m", "oA3VV", "$GG>",
"=6]g", "<=;;", "o%)`>", "sixtwo/azz", "qzWY",
"'Z)D", "o5)GF", "o=oHV", "o%)`|", "X`tdjdj",
"o=oHH", "top.ultimismc.com", "4EH?>MM?", "Mh__M",
"/gQK", "e6lK", "BZKBo", "^wH1", "5V!I",
"2UvA", "2Uvh", "U@j#", "\\aiL", "\\aiI",
"o$$YY", "H&NN", "H&NH", "YMOq", "`k28",
"X&%F", "%qQP", "%qQQ", "Gvk$", "%qQr",
"%qQx", "B:+UOU", "Lnhmc", "%qQg", "%qQc",
"%qQa", "3RH#3RH#", "oA3WW", "K~KF", "_3V`",
"O8VY`", "iVutS", ":0D%", "1WeL1WeL", "iM2^",
"FJ,K", "s`oL", "nj1NI1", "0PVV", "o%)av",
"OS__", "<=k`k`", "{%;C", "m\\v}(G", "Pf)I",
"o5)X&", ",]CV", ")qas", "o5)Xu", "sixtwo/ayy",
"/gP$", "%^A^A", "`&|k", "a]&H", "@+=S",
"#heoH", "^wII", "@+=t", "STSTST", "&,ww",
"kobb", "2UwI", "2UwJ", "Gvll", ">#HH",
">#H1", "t/V/H", "IM'4", "iM1|", "_3UU",
"_3UC", "FJ/J", "o-\"<A", "%qP]", "vJDD",
"%qPP", "'Z+C", "<=9H", "PQBQB", "\\[ {ID-",
"K~DD", ")q`y", "K%}L", "sixtwo/axx", ",]@%",
"o=oNb", "qzUX", ",]@+", "o%)bg", ")FI1I1",
"gYCYCY", "S6I!S6I!", "{%:H", "nfw!", "nfwo",
"`&ss", "5V''", "|=BB", "z0.c", "z0.C",
"s%&H", "2Uxi", "2UxH", "@pwJ", "iQH11",
"2nAA", "%qW0", "%qW3", ">#I1", "s%&&",
"%qW+", "o-\"?7", "\\ag\\", "H1U#\"#\"", ":0BH",
"%qW|", ":0BA", "%qWx", "%qWv", "%qWm",
"%qW`", "~~7~rr+rgg", "%qWW", "%qWS", "s`m>",
"%qWO", "OS]K", "r_33", ",]Az", "_3TL",
"_3TB", "<=>9", "&D]vlvl", "K%|J", ",]A!",
"o%)cl", "Ic=AA", "o%)cv", "<=>{", "<=>E",
"$GBB", "<=>Q", "<=>^", "o=oO>", "0PP*",
"+D*I1", "-V++", "oc4&oc4&", "IZAVAV", "/gVB",
"I[G[Q", "o5)Zr", "sixtwo/aww", "HOtDN@@", "nfvA",
"`&rP", "`&rW", "a]$$", "95H5H", "zWL)L)",
"m@~(", "Zp[e", "od$pH", "od$pL", "0Hl$@HH",
"EDDDU", "@h#.-", "EDDDD", "\"0g\"", "YMLL",
"@pvv", "r?\\Er?\\E", "Gvnn", "X&*a", "5V$~",
"%qVf", "%qVM", "%qVJ", "c%NN", "%qV,",
"U@mm", "_3S\\", "O1lsls", "IM%I", "FJ!F",
"o-\">.", "?Q^5H", "uFRB\"6", ":0A)", "=6QQ",
"$GCC", "K~FF", "K~F_", "s`jH", "r_0U",
"0PS1", "xl~l~", ",]F)", "Pf.d", "o5)[B",
"Wm^Nv", "{%4D", "1\"ng`I", "bWWwWKK]J??D7*4*!",
"qz[<", "DKtlee", ",]FF", "vw=|", "sixtwo/avv",
"\"%3HG", "nfqC", "qz[E", "fd*d*", "unpackBL",
"ZpZp", "`&qZ", "/gUU", "__x_Windows_CAI_CMachineLearning_CITensorUInt16Bit",
"f$|%|%", "^wLK", "`=X!`", "9)gsLsL", "X&))",
"H5?&H&H", "&,tD", "(Ljava/lang/Object;Ljava/lang/Object;Ljava/lang/Object;Ljava/lang/Object;I)J",
"5U~/~/", "H&RI", "H&RR", "2Uz2", "U@nn",
".#^^", "lhGQj", "\\aeB", "Gvok", "c%I1",
"%qUd", "%qUu", "c%IZ", "%qUF", "%qUW",
"OS[H", "%qU]", "OS[[", ")q}", "v~F~F",
"QqqqSWWWW>WW]$]]d", "r_1Q", "-V)I", ",]GG",
"yOGiW", "o5)\\m", "o%)e+", "Wm^I1", "sixtwo/auu",
"$G||", "$G|A", "0PR`", "Rwy=P", "e6q<",
"?D=uu", "TR5G7t", "indexBufferUpload", "[\\pPH", "a]*H",
"nfpH", "a]*i", "(Lnet/minecraft/class_1309;Lnet/minecraft/class_243;FZ)F",
"unpackAO", "#`VV", "\"0eH", "?*,B", "#`Vd",
"/Zr_Z", "*EgBB", "z0+H", "@+9I", "org.jose4j.jwe.AesGcmContentEncryptionAlgorithm$Aes192Gcm",
"|=AA", "U@o/", "2U{{", "|=A=", "`k//",
"s%#\"", "YMBB", "%qTT", "%qT^", "%qT@",
"c%HH", "%qTg", "r_.F", "K~@@", "c%H1",
"r_..", ";hWH1", "<===", "iM5Z", "s`hh",
"o=oR2", "03333333L!", "<==A", "Pf,j", ",]D4",
"P>P>P>", "Pf,,", ",]Dy", "sixtwo/att", "vw3q",
"S]t2S]t2", "nfss", "nfsi", "HHGzHzH", "m@qs",
"yc{BI", "?*-v", "oHaMM", "^wRy", "CeF4T",
"d[I[I", "ZpXu", "^wRB", "#`WW", "^wR0",
"&,ro", "&,rD", "z0*I", "2U||", "@pss",
";A6A6", "UmMmM", "2U|+", "\\acC", "D$LbfZ",
"IM:D", "|=F+", "s%\"\"", "|=FH", "c%KH",
"META-INF/maven/org.bitbucket.b_c/jose4j/pom.properties", "U@PE", "c%KD",
"s%\"o", "H&PI", "6n/0I", "%q[=", "FJ\"&",
"XXXqXXVWXWG>X>3$X$", "%q[I", "LgF5??", "%q[B",
"%q[E", "%q[[", "l\"*H1", "%q[l", "vJ{T",
"%q[b", "%q[g", "s`ii", "KC:C:", "<rgX#",
"BfNII", ",]EG", "3Ixf!H", "-V/f", "03333333M!",
",Iw{{", "O9I9I", "sixtwo/ass", "y:RsRs", "qz^v",
"o%)ge", "e6wL", "/gJJ", "~:oI*", "e6w]",
"Pf##", "#`TA", "#`TH", "/gJ\"", "O2aZZ",
"zO`m", "m@ru", "z0)+", ",lOlO", "Windows.Media.SpeechSynthesis.SpeechSynthesizer.TrySetDefaultVoiceAsync",
"&,q>", "ZH3QsL!L!", "|=GJ", "z0)K", "*e'2O",
"IM9L", "s%-E", "oE@fE", "oE@fD", "oE@fA",
"@prQ", "@prL", "YM@@", "]C3-**(((('''&&&%%%$$$###\"\"!!",
"D$LbeR", "s%-3", "%qZ5", "J\\iTOTO", "%qZ.",
"o-\"\"$", "\\a`B", "s`vm", "8>E>E", "%qZk",
"_3_/", "vJzm", "OSXf", "c%JJ", "2nDD",
"%qZE", ")qzz", "K~B4", "_3_f", "_3_L",
"0PoL", ",]JJ", "o=oPM", "o=oPx", "=6U]",
"/JDII", "<=#M", "qz_I", "qz_H", "vw11",
"/gII", "/gI1", "o5)_B", "sixtwo/arr", "GniHH",
"m@sI", "hua2I1", "unpackFO", "#`UJ", "unpackFC",
"]r'\\*", "emoteInstance", "`&333", "&,pH", "&,pK",
"&,pF", "2U~B", ",#0QS", "YMGA", "H+*aa",
"\"0b@", ")VM!Qy", "YV\\dYV\\d", "@pmm", "\\aaE",
"@,@\\PiPi", "%qYe", "IM88", "\\aa2", "2nGC",
"|=DD", "|=DL", "IM8G", "FJ$A", "$Gx{",
"P#!v%5", ":0LY", "r_-0", "vJ}}", "~T$xf",
")qyz", "{%3]", "vw6F", "Pf!I", "e{..",
"sixtwo/aqq", "nf||", "vw66", "o5)P5", "o5)P6",
"o5b)h", "/gH1", "qz\\Y", "D$})V", "pHGMy",
"unpackEM", "D$})Z", "m@tJ", "@+5G", "n.-.-",
"od$jj", "@+55", "a]..", "\"0aa", "a].^",
"^wQT", "X&,J", "t72Q2Q", "java.net.URLPermission", "VW!W!",
"|=E1", "uLx&T", "5V.H", "@plC", "U@SA",
"oE}++", "\\a~P", "@pll", "\\a~\\", "%qX3",
"\\a~L", "\\a~u", "%qXv", "2nFF", "%qXH",
"%qXP", "%qXR", "%qXW", "FJ''", "K~<<",
"81!.81!.", ",]HA", "0Pi)", "=6Kk", "o5)QP",
"sixtwo/app", "=6KK", "0Pii", ",]H1", "... (9 MB left)"
'@

# Convert the multi-line string into an array, filtering out empty lines and the "..." line.
$obfuscatedPatterns = $obfuscatedPatternsString -split "`r`n" | Where-Object { $_ -ne "" -and $_ -notmatch '^\.\.\.' }

# Combine for content matching (we'll match each pattern individually, not as a giant regex)
$allContentPatterns = $cheatStrings + $obfuscatedPatterns

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
    param($modsPath)
    Write-Host "[*] Scanning mods folder: $modsPath" -ForegroundColor Green
    if (-not (Test-Path $modsPath)) {
        Write-Warning "Mods folder not found: $modsPath"
        return
    }
    $jarFiles = Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction SilentlyContinue
    $total = $jarFiles.Count
    if ($total -eq 0) {
        Write-Host "   No JAR files found." -ForegroundColor Yellow
        return
    }
    Write-Host "   Found $total JAR files to scan." -ForegroundColor Green
    $scanned = 0
    # For each jar, check filename and content
    foreach ($jar in $jarFiles) {
        $scanned++
        Write-Progress -Activity "Scanning mods" -Status "$($jar.Name)" -PercentComplete (($scanned / $total) * 100)
        $name = $jar.BaseName.ToLower()
        
        # --- Filename: match suspicious and obfuscated patterns as literal substrings ---
        $matched = $false
        foreach ($pattern in $suspiciousPatterns) {
            if ($name.Contains($pattern.ToLower())) {
                Add-Finding -Id "POTENTIAL_JAR_CLIENT_FOUND" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Potential JAR Client Found" -Message "Suspicious pattern '$pattern' in filename: $($jar.Name)" -Evidence @{pattern=$pattern; file=$jar.Name; matchType="FilenameKnown"}
                $matched = $true
                break
            }
        }
        if (-not $matched) {
            foreach ($pattern in $obfuscatedPatterns) {
                # patterns may be mixed case, use case-insensitive
                if ($name.Contains($pattern.ToLower())) {
                    Add-Finding -Id "POTENTIAL_JAR_CLIENT_FOUND" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Potential JAR Client Found (Obfuscated)" -Message "Obfuscated pattern in filename: $($jar.Name)" -Evidence @{pattern=$pattern; file=$jar.Name; matchType="FilenameObfuscated"}
                    break
                }
            }
        }
        
        # --- Content scanning: match each pattern as a literal substring (case-insensitive) ---
        try {
            $content = [System.IO.File]::ReadAllText($jar.FullName) -replace "`0",""
            $contentLower = $content.ToLower()
            $contentMatched = $false
            foreach ($pattern in $cheatStrings) {
                if ($contentLower.Contains($pattern.ToLower())) {
                    Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Known Cheat String Match" -Message "Known cheat-related string '$pattern' found in $($jar.Name)" -Evidence @{string=$pattern; file=$jar.Name; matchType="KnownCheatString"}
                    $contentMatched = $true
                    break  # stop after first match to improve speed
                }
            }
            if (-not $contentMatched) {
                foreach ($pattern in $obfuscatedPatterns) {
                    if ($contentLower.Contains($pattern.ToLower())) {
                        Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Obfuscated Pattern Match" -Message "Obfuscated pattern '$pattern' found in $($jar.Name)" -Evidence @{string=$pattern; file=$jar.Name; matchType="ObfuscatedPattern"}
                        break
                    }
                }
            }
            # Additional checks: base64, hex, reflection, native
            if ($content -match '[A-Za-z0-9+/=]{60,}') {
                Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Base64-Encoded String Detected" -Message "Long Base64-like string detected in $($jar.Name)" -Evidence @{string="Base64"; file=$jar.Name; matchType="Base64"}
            }
            if ($content -match '\\x[0-9A-Fa-f]{2}\\x[0-9A-Fa-f]{2}') {
                Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Hex-Encoded Sequence Detected" -Message "Hex encoded sequence detected in $($jar.Name)" -Evidence @{string="Hex"; file=$jar.Name; matchType="Hex"}
            }
            if ($content -match 'Class\.forName\(.*?[Cc]he') {
                Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Reflection To Cheat Class Detected" -Message "Reflection to cheat class detected in $($jar.Name)" -Evidence @{string="Reflection"; file=$jar.Name; matchType="Reflection"}
            }
            if ($content -match 'System\.loadLibrary|System\.load') {
                Add-Finding -Id "CUSTOM_STRING_FOUND_WARNING" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Native Library Load Detected" -Message "Native library loading detected in $($jar.Name)" -Evidence @{string="Native"; file=$jar.Name; matchType="Native"}
            }
        } catch {}
    }
}

function Scan-Registry {
    # ... (rest of functions unchanged, but with category fixed)
    Write-Host "[*] Scanning registry..." -ForegroundColor Green
    $regKeys = @("Vape", "Meteor", "LiquidBounce", "Wurst", "Sigma", "Novoware", "Prestige", "Doomsday", "Argon", "Krypton", "Delta", "Elysian", "Onyx", "Lumina", "Momentum", "RavenB++", "SkidBounce", "Skidcraft", "Backdoored", "LeuxBackdoor", "SalHackSkid", "GrassWare", "AllahWare", "BBCWare", "Arsenic", "Atrium", "BleachHack", "Caizm", "Coffee", "Cranberry", "Evangelion", "FDP", "Fog", "ForgeHax", "Huzuni", "Hydrogen", "Ikea", "Jex", "Kamiblue", "Konas", "Kura", "Lambda", "LavaHack", "Mercury", "Mint", "Mirai", "NClient", "Neptunium", "Ozark", "Raion", "Rebirth", "Rift", "Selene", "Seppuku", "Silence", "Spark", "Swift", "Tensor", "Tokyo", "Trollhack", "Vertex", "Vrpos", "Xulu", "Zeon", "ZeroTwo", "Zodiac")
    foreach ($key in $regKeys) {
        $keyPath = "HKCU:\Software\$key"
        if (Test-Path $keyPath) {
            Add-Finding -Id "FOUND_IN_REGISTRY" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Found In Registry" -Message "Registry key '$key' exists" -Evidence @{value="Key $keyPath"; matchType="RegistryKey"}
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
                    Add-Finding -Id "FOUND_IN_DNSCACHE" -Tier "Warning" -Category "In-Process Memory Discoveries" -Title "Found In Dnscache" -Message "Domain '$domain' found in DNS cache" -Evidence @{domain=$domain; matchType="DnsCache"}
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
            if ($name.Contains($str.ToLower())) {
                Add-Finding -Id "CHEAT_FOUND_IN_WINDOWS_SERVICE" -Tier "Detection" -Category "Cheat Discovery in Memory" -Title "Cheat Found In Windows Service Memory" -Message "Cheat process '$str' found running" -Evidence @{service=$str; process=$p.ProcessName; matchType="RunningProcess"}
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
                    Add-Finding -Id "POTENTIAL_MALICIOUS_JVM_ARG" -Tier "Detection" -Category "Cheat Execution Evidence" -Title "Potential Malicious JVM Argument Found" -Message "JVM arg: $($Matches[0])" -Evidence @{arg=$Matches[0]; matchType="JvmArgClientBrand"}
                }
                if ($cmdLine -match "-D(xray|fly|speed|killaura|reach|scaffold)") {
                    Add-Finding -Id "POTENTIAL_MALICIOUS_JVM_ARG" -Tier "Detection" -Category "Cheat Execution Evidence" -Title "Potential Malicious JVM Argument Found" -Message "JVM arg: $($Matches[0])" -Evidence @{arg=$Matches[0]; matchType="JvmArgFeature"}
                }
                if ($cmdLine -match "-Djava\.security\.manager=" -or $cmdLine -match "-Xbootclasspath") {
                    Add-Finding -Id "POTENTIAL_MALICIOUS_JVM_ARG" -Tier "Detection" -Category "Cheat Execution Evidence" -Title "Potential Malicious JVM Argument Found" -Message "Security manager tampering detected" -Evidence @{arg="Security manager tamper"; matchType="JvmArgSecurityManager"}
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
                Add-Finding -Id "CLEARED_EVENT_LOG_SINCE_LOGON" -Tier "Warning" -Category "EventLog Tampering" -Title "Cleared Event Log Since Logon" -Message "Event log '$log' appears empty" -Evidence @{log=$log; matchType="EventLog"}
            }
        } catch {}
    }
}

# ============ MAIN ============
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[*] Starting forensic scan..." -ForegroundColor Green
Write-Host "[*] Mods path: $ModsPath" -ForegroundColor Green
Write-Host "[*] Output: $OutputDir" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$continue = Scan-Environment
if ($continue) {
    Scan-FileSystem -modsPath $ModsPath
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
$report += "`nReport generated by Magician's Reveal v2.0.2"
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
