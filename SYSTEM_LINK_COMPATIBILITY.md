# PSX System Link Compatibility

This is the authoritative compatibility tracker for games in `Z:\Games\MiSTer\games\PSX\_Link_`. Update a row only after a paired-console test, and add a test-run entry so the result remains tied to an exact core build and fixture.

## Status definitions

| Status | Meaning |
|---|---|
| Pass | Two consoles connect and sustained gameplay completes without a link-related fault. |
| Partial | The link starts, but gameplay pauses, freezes, disconnects, or otherwise fails later. |
| Fail | The consoles cannot establish a usable link or cannot reach gameplay. |
| Not tested | No reliable paired-hardware result has been recorded. |

## Current baseline

The latest broad hardware baseline is `PSX_systemlink-71_legacy_2x_baud.rbf` at commit `213999d64a0292740d2ab61add8f7e3171a13999`. It used the legacy 2x SIO1 period, Quartus seed 13, and passed timing with setup slack `0.341 ns` and hold slack `0.107 ns`.

The register-write/ACK fix candidate compiled successfully as the current unnumbered `PSX.rbf`, but that build has `-0.104 ns` setup slack. It is not represented in the compatibility results below until a timing-clean packaged build and paired-hardware tests complete.

## Compatibility matrix

| Game | Status | Last build | Test depth | Notes |
|---|---|---|---|---|
| Andretti Racing (USA) | Pass | systemlink-71 | Linked/gameplay | Verified with legacy 2x baud build. |
| Armored Core - Master of Arena (USA) (Disc 1) | Pass | systemlink-71 | Linked/gameplay | All Armored Core titles reported working. |
| Armored Core - Master of Arena (USA) (Disc 2) | Pass | systemlink-71 | Linked/gameplay | All Armored Core titles reported working. |
| Armored Core - Project Phantasma (USA) | Pass | systemlink-71 | Linked/gameplay | All Armored Core titles reported working. |
| Armored Core (USA) | Pass | systemlink-71 | Linked/gameplay | All Armored Core titles reported working. |
| Assault Rigs (USA) | Fail | systemlink-71 | Lobby | Alternates `Waiting for other player...` between consoles; never enters gameplay. |
| Ayrton Senna Kart Duel (Europe) | Not tested | — | — | — |
| Blast Radius (Europe) | Fail | systemlink-71 | Link setup | `Invalid link - Check manual`; both consoles behave as slaves. |
| Blast Radius (USA) | Fail | systemlink-71 | Link setup | `Invalid link - Check manual`; both consoles behave as slaves. |
| Bogey - Dead 6 (USA) | Pass | systemlink-71 | Linked/gameplay | Verified with legacy 2x baud build. |
| Burning Road (USA) | Pass | systemlink-71 | Linked/gameplay | Verified with legacy 2x baud build. |
| Bushido Blade (USA) | Pass | systemlink-71 | Linked/gameplay | Verified with legacy 2x baud build. |
| Bushido Blade 2 (USA) | Pass | systemlink-71 | Linked/gameplay | Verified with legacy 2x baud build. |
| C1 - Circuit (Japan) | Pass | systemlink-71 | Linked/gameplay | Verified with legacy 2x baud build. |
| Car and Driver Presents - Grand Tour Racing '98 (USA) | Pass | systemlink-71 | Linked/gameplay | Verified with legacy 2x baud build. |
| CART World Series (USA) | Fail | systemlink-71 | Driver selection | Freezes at the player-two driver-selection screen. |
| Command & Conquer - Red Alert - Retaliation (USA) (Disc 1) (Allies) | Pass | systemlink-71 | Linked/gameplay | Command & Conquer titles reported working. |
| Command & Conquer - Red Alert - Retaliation (USA) (Disc 2) (Soviet) | Pass | systemlink-71 | Linked/gameplay | Command & Conquer titles reported working. |
| Command & Conquer - Red Alert (USA) (Disc 1) (Allies) | Pass | systemlink-71 | Linked/gameplay | Command & Conquer titles reported working. |
| Command & Conquer - Red Alert (USA) (Disc 2) (Soviet) | Pass | systemlink-71 | Linked/gameplay | Command & Conquer titles reported working. |
| Cool Boarders 2 (USA) | Not tested | — | — | — |
| Dead in the Water (USA) | Not tested | — | — | — |
| Descent (USA) | Pass | systemlink-71 | Linked/gameplay | RX idle qualification preserved; verified working. |
| Descent Maximum (USA) | Not tested | — | — | — |
| Destruction Derby (USA) | Not tested | — | — | — |
| Dodgem Arena (Europe) | Not tested | — | — | — |
| Doom (USA) (Rev 1) | Pass | systemlink-71 | Linked/gameplay | Verified working. |
| Duke Nukem - Total Meltdown (USA) | Pass | systemlink-71 | Linked/gameplay | Verified working. |
| Dune 2000 (USA) | Not tested | — | — | — |
| Explosive Racing (Europe) | Not tested | — | — | — |
| Final Doom (USA) | Not tested | — | — | — |
| Formula 1 (USA) (Rev 1) | Not tested | — | — | — |
| Formula 1 98 (USA) (En,Fr,De,Es,It,Fi) | Not tested | — | — | — |
| Gekisou!! Grand Racing - Total Drivin' (Japan) | Not tested | — | — | — |
| Independence Day - The Game (Europe) (En,Fr,De,Es,It,Sv) | Not tested | — | — | — |
| Independence Day (USA) | Not tested | — | — | — |
| Krazy Ivan (USA) | Not tested | — | — | — |
| Leading Jockey Highbred (Japan) | Not tested | — | — | — |
| Metal Jacket (Japan) | Not tested | — | — | — |
| Mobile Suit Z-Gundam (Japan) (Disc 1) | Not tested | — | — | — |
| Mobile Suit Z-Gundam (Japan) (Disc 2) | Not tested | — | — | — |
| Monaco Grand Prix (USA) | Not tested | — | — | — |
| Monaco Grand Prix Racing Simulation 2 (Europe) (En,Fr,Es,It) | Not tested | — | — | — |
| Motor Toon Grand Prix - USA Edition (Japan) | Not tested | — | — | — |
| Motor Toon Grand Prix (USA) | Pass | user report | Linked/gameplay | Reported working well; exact core build not recorded. Retest against the next release. |
| Motor Toon Grand Prix 2 (Europe) | Not tested | — | — | — |
| Over Drivin' DX (Japan) | Not tested | — | — | — |
| PrePre Vol. 2 (Japan) | Not tested | — | — | — |
| Pro Pinball - Big Race USA (USA) | Not tested | — | — | — |
| R4 - Ridge Racer Type 4 (USA) | Not tested | — | — | — |
| Racingroovy VS (Japan) | Not tested | — | — | — |
| Real Robots - Final Attack (Japan) | Not tested | — | — | — |
| Red Asphalt (USA) | Not tested | — | — | — |
| Ridge Racer Revolution (USA) | Not tested | — | — | — |
| Road & Track Presents - The Need for Speed (USA) | Not tested | — | — | — |
| Robo Pit (USA) | Not tested | — | — | — |
| Rock & Roll Racing 2 - Red Asphalt (Europe) | Not tested | — | — | — |
| Rogue Trip - Vacation 2012 (USA) | Not tested | — | — | — |
| San Francisco Rush - Extreme Racing (Europe) (En,Fr,De,Es,It) | Not tested | — | — | — |
| San Francisco Rush - Extreme Racing (USA) | Not tested | — | — | — |
| Shutokou Battle R (Japan) | Not tested | — | — | — |
| Sidewinder (Japan) | Not tested | — | — | — |
| Sidewinder USA (Japan) | Not tested | — | — | — |
| Soukou Kihei Votoms Gaiden - Ao no Kishi Berserga Monogatari (Japan) (Limited Edition) | Not tested | — | — | — |
| Streak Hoverboard Racing (USA) | Not tested | — | — | — |
| Test Drive 4 (USA) | Not tested | — | — | — |
| Test Drive Off-Road (USA) | Not tested | — | — | — |
| TOCA 2 - Touring Car Challenge (USA) (En,Fr,Es) | Not tested | — | — | — |
| TOCA 2 Touring Cars (Europe) (En,Fr,De) (Rev 1) | Not tested | — | — | — |
| Total Drivin (Europe) (En,Fr,De,Es,It,Pt) | Not tested | — | — | — |
| Trick'n Snowboarder (USA) | Not tested | — | — | — |
| Tricky Sliders - Freestyle Snowboard (Japan) | Not tested | — | — | — |
| Twisted Metal III (USA) (Rev 1) | Partial | systemlink-71 | Sustained gameplay | Links and enters gameplay, but pauses randomly during link traffic. |
| Wing Over (Europe) | Not tested | — | — | — |
| WipEout (USA) | Not tested | — | — | — |
| WipEout 2097 (Europe) | Not tested | — | — | — |
| WipEout 3 - Special Edition (Europe) (En,Fr,De,Es,It) | Not tested | — | — | — |
| WipEout 3 (USA) | Not tested | — | — | — |
| Wipeout XL (USA) | Pass | systemlink-71 | Linked/gameplay | Verified with legacy 2x baud build. |
| X.Racing (Japan) | Not tested | — | — | — |

## Test-run log

Add the newest run at the top. Use one row per game/build combination.

| Date | Game | Status | Core/RBF | Commit | Console A role | Console B role | Assist mode | Test depth/duration | Evidence | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 2026-05-31 | Multiple titles | Mixed | `PSX_systemlink-71_legacy_2x_baud.rbf` | `213999d64a0292740d2ab61add8f7e3171a13999` | Per game | Per game | Per game | Broad paired-hardware sweep | Commit message and prior test notes | Baseline summarized in the matrix above. Split into individual rows when retested. |

## Release test checklist

- Record the exact RBF filename, commit, SHA-256, Quartus seed, setup slack, and hold slack.
- Use the same game revision on both consoles unless the game documentation requires otherwise.
- Record host/slave selections and System Link Assist settings independently for both consoles.
- Confirm both consoles reach gameplay; reaching a lobby alone is not a pass.
- Exercise sustained gameplay for at least 10 minutes before marking Pass.
- For intermittent pauses or disconnects, record MP4 and capture SIO1/USER_IO activity with SignalTap.
- Preserve the physical fixture: cable → USB3 breakout or Dupont jumpers → cable, including the manually crossed middle section.
- Attach evidence paths in the test-run log and update the compatibility matrix from the newest reliable run.

## Suggested release smoke set

Run these first because they cover known-good and distinct failure modes:

1. Doom — known-good control.
2. Descent — RX idle/back-to-back control.
3. Motor Toon Grand Prix — user-reported known-good control.
4. Duke Nukem — legacy 2x baud control.
5. Twisted Metal III — intermittent sustained-traffic failure.
6. Assault Rigs — alternating wait-state failure.
7. Blast Radius — host/slave negotiation failure.
8. CART World Series — later driver-selection freeze.
