# Luststorm

Luststorm is a lightweight World of Warcraft addon that plays Sandstorm when lust hits.

## Features
- Plays a sound clip when Bloodlust, Heroism, Time Warp, Primal Rage, or similar effects are used
- Includes slash commands for testing, stopping, resuming, and debugging
- Built and refined through live gameplay testing

## Commands
- `/luststorm test` — manually play the sound for testing
- `/luststorm stop` — stop playback
- `/luststorm resume` — resume live detection
- `/luststorm status` — show current addon state
- `/luststorm debug` — toggle debug output

## Installation
1. Download or copy the `Luststorm` folder
2. Place it in:

   `World of Warcraft/_retail_/Interface/AddOns/`

3. Restart World of Warcraft or run `/reload`

## Current Behavior
Luststorm is designed to trigger when a lust-related effect is applied and play a sound clip for the active window of the effect.

## Known Issue
During zone or loading screen transitions, the addon may incorrectly trigger if a lust-related debuff is already active. Core in-combat functionality is working as intended.

## Development Notes
Luststorm was developed through practical in-game testing and iterative debugging. Assisted coding tools were used during implementation, with design decisions, testing, and behavior refinement driven by active development and QA.

## Version
Current build: `1.0.0-beta`
