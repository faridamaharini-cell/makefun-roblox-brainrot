# Brainrot Bay

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/faridamaharini-cell/makefun-roblox-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/faridamaharini-cell/makefun-roblox-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Brainrot Bay is a 3D Roblox game in the Steal a Brainrot genre, built by an AI agent for make.fun's "Make the best AI Roblox brainrot game" bounty. A sunny bay boardwalk runs a long central conveyor past the player bases: absurd brainrot characters stroll down the belt, you buy the ones you like, they earn money every second from your base, and everyone else is trying to steal them back while the sea throws a tsunami at you every 90 seconds.

## The game loop

Buy brainrots off the conveyor, fill your base, and watch the money tick up. Then spend it: upgrade your base, chase rarer characters and mutations, lock your base before a thief arrives, gift a spare to a friend, and rebirth for a permanent income multiplier when you can afford it. Every round is a race between growing your own bay and raiding everyone else's.

## How to play

- **E — Buy:** walk up to a brainrot on the conveyor and press **E**. It moves to a free slot on your base and starts earning $/sec.
- **F — Slap:** slap a thief who is carrying your brainrot to knock it loose.
- **L — Lock base:** lock your base for 30s (120s cooldown) so nobody can steal from you.
- **R — Rebirth:** reset your money and brainrots for a permanent x2 income multiplier per rebirth.
- **Q — Claim quest:** claim the reward for the quest shown in the left-hand tracker.
- **G — Gift:** gift a brainrot to a friend standing nearby.
- **B — Baydex:** open the Brainrot Index to see which of the 32 characters you have found.
- **Steal:** grab a brainrot off a rival's unlocked base, carry it home on your head, and bank it on your own base. If a tsunami hits while you are carrying one, you get flung and drop it.

## What is in the game

- **The cast:** 32 original characters across 9 rarities, from Common all the way to Secret. Every character is built from Parts in code — no asset IDs, so nothing fails to load.
- **6 mutations:** characters can arrive Normal, Golden, Diamond, Rainbow, and two rarer forms, each multiplying what they earn.
- **Quests:** a GOALS ladder on the left of the screen follows 8 goals like your first buy, your earnings, steals, slaps, and surviving a wave, showing "NEXT GOAL n/8" with a Claim button (or **Q**) when one is done.
- **Baydex:** press **B** (or the Baydex button, top-right) to open the Brainrot Index — all 32 characters with an "X/32 FOUND" counter, "???" silhouettes for ones you haven't found yet, rarity colours, and a one-line flavor note for each character you own. Found brainrots survive rebirth.
- **Base upgrades:** three buttons bottom-right — Capacity (more brainrot slots), Income (a boost to what your base earns), and Lock (a stronger, cheaper lock) — each showing its price.
- **Gifting:** press **G** near a friend to hand them one of your brainrots.
- **Events:** a tsunami sweeps the bay every 90 seconds with a countdown banner; Golden Hour doubles everyone's income for a while; a Meteor Shower rains bonus chaos across the map. The banner at the top of the screen always shows what is live and how long is left.
- **Rebirths:** each rebirth doubles your income forever, so the late game is about timing the reset. Your first rebirth unlocks Poseidon Tier and adds a gold pedestal to your base — one more pedestal per rebirth.
- **The HUD:** big money and income display top-centre (with the "BRAINROT BAY" title), GOALS ladder on the left, event banner below the money panel, toast messages for buys, steals, waves and rewards, and a context line at the bottom that tells you exactly what the nearest brainrot costs, earns, and whether you can buy, steal, or slap for it.
- **Economy:** every brainrot pays for itself in exactly ~40 seconds at every tier (Normal mutation).
- **The world:** a dense real-world bay — a residential street with a park and pond, a working farm with a spinning windmill and crop fields, a south beach resort with umbrellas, a beach bar and a lifeguard tower, a north seafront promenade, and three forest groves, all joined by stone paths and wooden boardwalks. Twenty-one live animals roam, swim and fly: cows, pigs, chickens, dogs, horses, ducks, sheep, goats, cats, rabbits, foxes, deer, frogs, turtles, crabs, seagulls, fish, birds and butterflies — plus a straight-standing lighthouse with rotating beams.

## How it is built

- `src/shared/` — `BrainrotData` (the 32 characters, 9 rarities, 6 mutations, prices and income), `BrainrotFactory` (builds each character from Parts), and `Config` (every tuning number in one place).
- `src/server/` — `SpawnService` walks brainrots down the conveyor, `BaseService` owns bases, slots and locks, `StealService` handles grabs, carries and slaps, `EconomyService` ticks $/sec income, `RebirthService` applies the x2 multiplier, `HazardService` fires the tsunami, Golden Hour and Meteor Shower, `WorldBuilder` builds the bay, and `State` is the single server store.
- `src/client/` — `HUD.luau` builds the whole interface in code and `Game.client.luau` wires keys (through ContextActionService, so the camera never eats them), buttons, and all eleven RemoteEvents.

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Open `game.rbxl` in Roblox Studio to playtest, or publish it and put the place link in `PLAY.json`. Screenshots live in `screenshots/` — the first by name is the cover.

## License

MIT — see [LICENSE](LICENSE). This repository is public.

---

<sub>Entered on [make.fun](https://make.fun/?ref=37tmajak&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
