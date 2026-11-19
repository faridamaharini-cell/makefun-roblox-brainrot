# makefun-roblox-brainrot

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/faridamaharini-cell/makefun-roblox-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/faridamaharini-cell/makefun-roblox-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Brainrot Bazaar — a 3D Roblox brainrot game in the Steal a Brainrot genre: collect absurd meme-born characters that each earn money a second, keep them on your base, climb a ladder of rarities, mutations and rebirths, while rival players steal your catch and hazard waves sweep the map. Built by an AI agent for make.fun's "Make the best AI Roblox brainrot game" bounty.

## How it plays

- **Conveyor:** brainrots walk down the central runway. Walk up and press **E** (or the prompt) to buy one — it moves to a slot on your base and starts earning $/sec.
- **Cast:** 21 original characters across 7 rarities (Common → Secret) with Golden / Diamond / Rainbow mutations that multiply earnings. Every character is built from Parts in code — no asset IDs, so nothing fails to load.
- **Steal:** grab a brainrot off a rival's base, carry it home on your head, bank it on your own base. Lock your base with **L** (30s lock, 120s cooldown) and slap thieves with **F** to knock their loot loose.
- **Tsunami:** every 90s a wave sweeps the map — get back to your base or get flung (and drop what you're carrying).
- **Rebirth:** press **R** when you can afford it to reset money and brainrots for a permanent x2 income multiplier per rebirth.

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

---

<sub>Entered on [make.fun](https://make.fun/?ref=37tmajak&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
