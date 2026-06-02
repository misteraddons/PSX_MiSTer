# PSX Link SIO1 Baud Scan

Static scan of local `Z:\Games\MiSTer\games\PSX\_Link_` cue images.
Mode multipliers use PCSX-Redux SIO1 mapping: mode low bits 1=1x, 2=16x, 3=64x.

## Summary

- Titles scanned: 80
- SIO1 register stores found: 3727
- Titles with a nearby mode/baud pair: 65
- Titles without a nearby mode/baud pair: 15
- Dominant pair: mode `0x00ce`, baud `0x00d8`, multiplier `16`, nominal period `3456`, fixed-2x period `6912`.

## Focus Titles

| Title | Stores | Modes | Bauds | Multipliers | Nominal periods | Fixed 2x periods |
|---|---:|---|---|---|---|---|
| Armored Core (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Armored Core - Master of Arena (USA) (Disc 1) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Armored Core - Master of Arena (USA) (Disc 2) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Armored Core - Project Phantasma (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Assault Rigs (USA) | 36 | 0x0000,0x0004,0x00ce | 0x0000,0x0004,0x00d8 | 16 | 3456 | 6912 |
| Blast Radius (Europe) | 0 |  |  |  |  |  |
| Blast Radius (USA) | 0 |  |  |  |  |  |
| CART World Series (USA) | 84 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Descent (USA) | 12 | 0x004e |  |  |  |  |
| Descent Maximum (USA) | 12 | 0x004e |  |  |  |  |
| Doom (USA) (Rev 1) | 36 | 0x0020,0x00ce | 0x0020,0x00d8 | 16 | 512,3456 | 1024,6912 |
| Duke Nukem - Total Meltdown (USA) | 48 | 0x0052,0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Final Doom (USA) | 72 | 0x0020,0x00ce | 0x0020,0x00d8 | 16 | 512,3456 | 1024,6912 |
| Motor Toon Grand Prix (USA) | 142 | 0x0000,0x00ce | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Motor Toon Grand Prix - USA Edition (Japan) | 142 | 0x0000,0x00ce | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Motor Toon Grand Prix 2 (Europe) | 106 | 0x0000,0x00ce | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| R4 - Ridge Racer Type 4 (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Twisted Metal III (USA) (Rev 1) | 40 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Wipeout XL (USA) | 39 | 0x0000,0x00ce | 0x00d8 | 16 | 3456 | 6912 |

## Period Groups

| Nominal period | Title count | Example titles |
|---:|---:|---|
| 3456 | 65 | Andretti Racing (USA); Armored Core (USA); Armored Core - Master of Arena (USA) (Disc 1); Armored Core - Master of Arena (USA) (Disc 2); Armored Core - Project Phantasma (USA); Assault Rigs (USA); Bogey - Dead 6 (USA); Burning Road (USA); Bushido Blade (USA); Bushido Blade 2 (USA) |
| 0 | 27 | Andretti Racing (USA); Assault Rigs (USA); Burning Road (USA); Bushido Blade (USA); CART World Series (USA); Car and Driver Presents - Grand Tour Racing '98 (USA); Command & Conquer - Red Alert (USA) (Disc 1) (Allies); Command & Conquer - Red Alert (USA) (Disc 2) (Soviet); Command & Conquer - Red Alert - Retaliation (USA) (Disc 1) (Allies); Command & Conquer - Red Alert - Retaliation (USA) (Disc 2) (Soviet) |
| 48 | 3 | C1 - Circuit (Japan); Formula 1 (USA) (Rev 1); Racingroovy VS (Japan) |
| 192 | 3 | C1 - Circuit (Japan); Formula 1 (USA) (Rev 1); Racingroovy VS (Japan) |
| 4080 | 3 | Bogey - Dead 6 (USA); Leading Jockey Highbred (Japan); Sidewinder (Japan) |
| 16320 | 3 | Bogey - Dead 6 (USA); Leading Jockey Highbred (Japan); Sidewinder (Japan) |
| 512 | 2 | Doom (USA) (Rev 1); Final Doom (USA) |
| 1 | 1 | Andretti Racing (USA) |
| 32 | 1 | Metal Jacket (Japan) |
| 233 | 1 | Krazy Ivan (USA) |

## All Titles

| Title | Stores | Modes | Bauds | Multipliers | Nominal periods | Fixed 2x periods |
|---|---:|---|---|---|---|---|
| Andretti Racing (USA) | 70 | 0x0000,0x0001,0x00ce | 0x0000,0x0001,0x00d8 | 1,16 | 1,3456 | 2,6912 |
| Armored Core (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Armored Core - Master of Arena (USA) (Disc 1) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Armored Core - Master of Arena (USA) (Disc 2) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Armored Core - Project Phantasma (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Assault Rigs (USA) | 36 | 0x0000,0x0004,0x00ce | 0x0000,0x0004,0x00d8 | 16 | 3456 | 6912 |
| Ayrton Senna Kart Duel (Europe) | 33 | 0x00ce |  |  |  |  |
| Blast Radius (Europe) | 0 |  |  |  |  |  |
| Blast Radius (USA) | 0 |  |  |  |  |  |
| Bogey - Dead 6 (USA) | 36 | 0x00ce,0x00ff | 0x00d8,0x00ff | 16,64 | 3456,4080,16320 | 6912,8160,32640 |
| Burning Road (USA) | 36 | 0x0000,0x00ce | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Bushido Blade (USA) | 40 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Bushido Blade 2 (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| C1 - Circuit (Japan) | 68 | 0x0003,0x00ce | 0x0003,0x00d8 | 16,64 | 48,192,3456 | 96,384,6912 |
| Car and Driver Presents - Grand Tour Racing '98 (USA) | 39 | 0x00ce,0x1050 | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| CART World Series (USA) | 84 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Command & Conquer - Red Alert (USA) (Disc 1) (Allies) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Command & Conquer - Red Alert (USA) (Disc 2) (Soviet) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Command & Conquer - Red Alert - Retaliation (USA) (Disc 1) (Allies) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Command & Conquer - Red Alert - Retaliation (USA) (Disc 2) (Soviet) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Cool Boarders 2 (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Dead in the Water (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Descent (USA) | 12 | 0x004e |  |  |  |  |
| Descent Maximum (USA) | 12 | 0x004e |  |  |  |  |
| Destruction Derby (USA) | 24 | 0x00ce | 0x00d8 | 16 | 3456 | 6912 |
| Dodgem Arena (Europe) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Doom (USA) (Rev 1) | 36 | 0x0020,0x00ce | 0x0020,0x00d8 | 16 | 512,3456 | 1024,6912 |
| Duke Nukem - Total Meltdown (USA) | 48 | 0x0052,0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Dune 2000 (USA) | 78 | 0x00ce,0x1050 | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Explosive Racing (Europe) | 32 | 0x0000,0x00ce,0x00dc | 0x0000,0x00d8,0x00dc | 16 | 3456 | 6912 |
| Final Doom (USA) | 72 | 0x0020,0x00ce | 0x0020,0x00d8 | 16 | 512,3456 | 1024,6912 |
| Formula 1 (USA) (Rev 1) | 170 | 0x0003,0x00ce | 0x0003,0x00d8 | 16,64 | 48,192,3456 | 96,384,6912 |
| Formula 1 98 (USA) (En,Fr,De,Es,It,Fi) | 78 | 0x00ce,0x1050 | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Gekisou!! Grand Racing - Total Drivin' (Japan) | 39 | 0x00ce,0x1050 | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Independence Day (USA) | 0 |  |  |  |  |  |
| Independence Day - The Game (Europe) (En,Fr,De,Es,It,Sv) | 0 |  |  |  |  |  |
| Krazy Ivan (USA) | 37 | 0x00ce,0x00e9 | 0x00d8,0x00e9 | 1,16 | 233,3456 | 466,6912 |
| Leading Jockey Highbred (Japan) | 36 | 0x00ce,0x00ff | 0x00d8,0x00ff | 16,64 | 3456,4080,16320 | 6912,8160,32640 |
| Metal Jacket (Japan) | 35 | 0x0002,0x00ce | 0x0002,0x00d8 | 16 | 32,3456 | 64,6912 |
| Mobile Suit Z-Gundam (Japan) (Disc 1) | 33 | 0x00ce |  |  |  |  |
| Mobile Suit Z-Gundam (Japan) (Disc 2) | 33 | 0x00ce |  |  |  |  |
| Monaco Grand Prix (USA) | 0 |  |  |  |  |  |
| Monaco Grand Prix Racing Simulation 2 (Europe) (En,Fr,Es,It) | 0 |  |  |  |  |  |
| Motor Toon Grand Prix (USA) | 142 | 0x0000,0x00ce | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Motor Toon Grand Prix - USA Edition (Japan) | 142 | 0x0000,0x00ce | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Motor Toon Grand Prix 2 (Europe) | 106 | 0x0000,0x00ce | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Over Drivin' DX (Japan) | 35 | 0x00ce | 0x00d8 | 16 | 3456 | 6912 |
| PrePre Vol. 2 (Japan) | 35 | 0x00ce | 0x00d8 | 16 | 3456 | 6912 |
| Pro Pinball - Big Race USA (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| R4 - Ridge Racer Type 4 (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Racingroovy VS (Japan) | 34 | 0x0003,0x00ce | 0x0003,0x00d8 | 16,64 | 48,192,3456 | 96,384,6912 |
| Real Robots - Final Attack (Japan) | 39 | 0x00ce,0x1050 | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Red Asphalt (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Ridge Racer Revolution (USA) | 8 | 0x009e | 0x0000 | 16 |  |  |
| Road & Track Presents - The Need for Speed (USA) | 35 | 0x00ce | 0x00d8 | 16 | 3456 | 6912 |
| Robo Pit (USA) | 0 |  |  |  |  |  |
| Rock & Roll Racing 2 - Red Asphalt (Europe) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Rogue Trip - Vacation 2012 (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| San Francisco Rush - Extreme Racing (Europe) (En,Fr,De,Es,It) | 195 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| San Francisco Rush - Extreme Racing (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Shutokou Battle R (Japan) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Sidewinder (Japan) | 36 | 0x00ce,0x00ff | 0x00d8,0x00ff | 16,64 | 3456,4080,16320 | 6912,8160,32640 |
| Sidewinder USA (Japan) | 32 | 0x0000,0x00ce,0x00dc | 0x0000,0x00d8,0x00dc | 16 | 3456 | 6912 |
| Soukou Kihei Votoms Gaiden - Ao no Kishi Berserga Monogatari (Japan) (Limited Edition) | 39 | 0x00ce,0x1050 | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Streak Hoverboard Racing (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Test Drive 4 (USA) | 15 | 0x00fe |  |  |  |  |
| Test Drive Off-Road (USA) | 32 | 0x0000,0x00ce,0x00dc | 0x0000,0x00d8,0x00dc | 16 | 3456 | 6912 |
| TOCA 2 - Touring Car Challenge (USA) (En,Fr,Es) | 195 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| TOCA 2 Touring Cars (Europe) (En,Fr,De) (Rev 1) | 195 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Total Drivin (Europe) (En,Fr,De,Es,It,Pt) | 39 | 0x00ce,0x1050 | 0x0000,0x00d8 | 16 | 3456 | 6912 |
| Trick'n Snowboarder (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Tricky Sliders - Freestyle Snowboard (Japan) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Twisted Metal III (USA) (Rev 1) | 40 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Wing Over (Europe) | 33 | 0x00ce |  |  |  |  |
| WipEout (USA) | 37 | 0x00ce | 0x00d8 | 16 | 3456 | 6912 |
| WipEout 2097 (Europe) | 39 | 0x0000,0x00ce | 0x00d8 | 16 | 3456 | 6912 |
| WipEout 3 (USA) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| WipEout 3 - Special Edition (Europe) (En,Fr,De,Es,It) | 39 | 0x00ce,0x1050 | 0x00d8 | 16 | 3456 | 6912 |
| Wipeout XL (USA) | 39 | 0x0000,0x00ce | 0x00d8 | 16 | 3456 | 6912 |
| X.Racing (Japan) | 32 | 0x0000,0x00ce,0x00dc | 0x0000,0x00d8,0x00dc | 16 | 3456 | 6912 |
