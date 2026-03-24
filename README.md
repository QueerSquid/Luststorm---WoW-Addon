# Luststorm

Luststorm is a lightweight World of Warcraft addon that plays Sandstorm when Bloodlust, Heroism, Time Warp, and similar effects are triggered.

## Features
- Plays a custom sound clip when Bloodlust, Heroism, Time Warp, Primal Rage, or similar effects are used
- Lightweight and simple
- Includes slash commands for testing, stopping, resuming, status checks, and debugging
- Built and refined through live gameplay testing

## Commands
- `/luststorm test` — manually plays the sound for testing
- `/luststorm stop` — stops current playback
- `/luststorm resume` — resumes live detection after testing
- `/luststorm status` — shows current addon state in chat
- `/luststorm debug` — toggles debug output in chat

## Installation
1. Download or copy the `Luststorm` folder
2. Place it in `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart World of Warcraft or run `/reload`

## Current Status
Luststorm is working properly in live combat testing, including fresh lust triggers during combat. Recent changes have also improved reload and zone transition behavior during testing.

## CurseForge
Also published on [CurseForge](https://www.curseforge.com/wow/addons/luststorm).

## Development Notes
Luststorm was developed through practical in-game testing and iterative debugging. Assisted coding tools were used during implementation, with design decisions, testing, and behavior refinement driven by active development and QA.

## Roadmap
- Continue monitoring instance and loading screen behavior during broader testing
- Collect feedback for future improvements and added features
- Refine trigger handling further if new edge cases appear

## Version
Current build: `1.0.1-beta`
