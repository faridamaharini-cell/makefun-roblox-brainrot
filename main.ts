// Brainrot Bay: a working roblox-brainrot-01 entry (Node 22, standard library only): the game is this directory's Rojo
// project, built into game.rbxl with `rojo build default.project.json --output game.rbxl`, and the program
// hands it in. It copies game.rbxl, src/, screenshots/ and PLAY.json from beside this file to /output and
// writes /output/dossier.json, the summary the judge reads, with the vendored make.fun library. Brainrot Bay
// is a 3D Steal-a-Brainrot-style game: 32 brainrots walk a conveyor past the player bases, you buy them,
// they earn $/sec, rivals steal them back, and a tsunami sweeps the bay every 90 seconds. Build your game,
// rebuild game.rbxl, put your PNG or JPEG screenshots in screenshots/ (the first by name is the cover, and one of
// them is the thumbnail you upload for your game on Roblox) and fill in PLAY.json with your published place.
//
// Every name under /output starts with a letter, a digit or _ and holds only letters, digits, . _ and -: the
// grader fails an entry whose output holds any other, so a file such as .gitkeep or .DS_Store copied in fails it.
// So src/ and screenshots/ are copied without any name that starts with a dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** Refuse to hand in a place or screenshots the scorer would refuse, before
 *  anything is copied: game.rbxl over the 32 MiB place cap, more than 4
 *  screenshots, or any screenshot over the 256 KiB cap. Failing here is
 *  cheaper than a 0 on the gate. */
const placeStat = statSync(join(here, 'game.rbxl'));
if (placeStat.size > 32 * 1024 * 1024) throw new Error(`game.rbxl is ${placeStat.size} bytes, over the 32 MiB place cap — rebuild it smaller`);
const shotDir = join(here, 'screenshots');
if (existsSync(shotDir)) {
  const shots = readdirSync(shotDir).filter((name) => !name.startsWith('.'));
  if (shots.length > 4) throw new Error(`${shots.length} screenshots, over the 4-screenshot cap`);
  for (const shot of shots) {
    const size = statSync(join(shotDir, shot)).size;
    if (size > 262144) throw new Error(`screenshots/${shot} is ${size} bytes, over the 256 KiB screenshot cap — re-encode it smaller`);
  }
}

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

// The output dir may not exist yet (fresh MAKEFUN_OUTPUT_DIR): create it
// before the first copy, or the game.rbxl copy throws ENOENT.
mkdirSync(out, { recursive: true });

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
// Verify the Brainrot Bay place actually arrived intact: the copied
// game.rbxl must be byte-identical in size to the source, otherwise the
// hand-in would ship a truncated place and the judge would score it 0.
const copiedPlaceStat = statSync(join(out, 'game.rbxl'));
if (copiedPlaceStat.size !== placeStat.size) throw new Error(`game.rbxl copy mismatch: source is ${placeStat.size} bytes but the copy is ${copiedPlaceStat.size} bytes — copy failed, refusing to hand in a truncated place`);
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
