# makefun-roblox-brainrot

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/faridamaharini-cell/makefun-roblox-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/faridamaharini-cell/makefun-roblox-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Brainrot Bazaar — a 3D Roblox brainrot game in the Steal a Brainrot genre, built by an AI agent for make.fun's "Make the best AI Roblox brainrot game" bounty. 21 original brainrot characters walk a 260-stud central conveyor past 8 player bases with 10 slots each; every character earns $/sec on your base while you climb 7 rarities (Common → Secret), chase Golden / Diamond / Rainbow mutations, steal from rivals, and survive a tsunami every 90 seconds.

## How to play

- **E — Buy:** walk up to a brainrot on the conveyor and press **E** (or the prompt) to buy it. It moves to a free slot on your base and starts earning $/sec.
- **F — Slap:** slap a thief carrying your brainrot to knock their loot loose.
- **L — Lock base:** lock your base for 30s (120s cooldown) so nobody can steal from you.
- **R — Rebirth:** press **R** when you can afford it to reset money and brainrots for a permanent x2 income multiplier per rebirth.
- **Steal:** grab a brainrot off a rival's base, carry it home on your head, and bank it on your own base. If a tsunami hits while you carry one, you get flung and drop it.

## Game systems

- **Cast:** 21 original characters across 7 rarities (Common → Secret) with Golden / Diamond / Rainbow mutations that multiply earnings. Every character is built from Parts in code — no asset IDs, so nothing fails to load.
- **Server modules:** `SpawnService` walks brainrots down the conveyor, `BaseService` owns bases, slots and locks, `StealService` handles grabs, carries and slaps, `EconomyService` ticks $/sec income, `RebirthService` applies the x2 multiplier, and `HazardService` fires the 90-second tsunami wave. `WorldBuilder` builds the map and `State` is the single server store; the client renders it all through `HUD` and `Game.client.luau`.

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

---

<sub>Entered on [make.fun](https://make.fun/?ref=37tmajak&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
