-- WorldBuilder: builds the whole Brainrot Bay island out of plain Parts.
-- No asset ids anywhere: the beach, the 300-stud conveyor, ten bases in two
-- rows of five, the spawn plaza, palms, market stalls, lamps, bunting, the
-- animated water at the map edge and the big BRAINROT BAY sign are all made
-- here, in code. Lighting is set to Future with a warm afternoon sun.
-- v3.1: the sand beach sits clearly above the project baseplate (no more
-- grey z-fight), and a little town grew around the plaza: a detailed barn,
-- shops and houses with pitched roofs, a gatehouse, wooden fences along
-- the conveyor, round trees, bushes, crates, barrels and hay bales.
-- v3.4: the houses are two-storey and taller (HS 2.5), six tall trees sway
-- at the map edges, and ambient animals (a cow, a pig, a chicken, two
-- birds) wander and orbit — one cheap animation loop drives them all.
-- v3.5: the town is denser (two more houses, two more shops, two more
-- huts, two more stalls) and the animals are 2x bigger.
-- v3.6: as busy as possible — a second market row on each outer band, a
-- lighthouse with rotating beams, a pier with bobbing sailboats, benches,
-- flower beds, extra lamps, waving flags, more signs, five more big
-- animals (dog, horse, duck, sheep, goat) and butterflies.
-- v4 REBUILD (from the v3.6 screenshot): the town/buildings/game loop are
-- kept, but the three defects are rebuilt from zero — (1) ground: the
-- 460x400 beach left grey baseplate showing everywhere, so the ground is
-- now a full 512x512 sand plate + grass town lawns + turquoise sea bands,
-- with a runtime coverage check proving every cell is covered; (2) signs:
-- 16-30-stud AlwaysOnTop boards are gone, only small non-AlwaysOnTop
-- plates remain (one arch title, one per base, one per shop front) and
-- all free-standing sign posts are deleted; (3) brainrot visibility is
-- fixed at the source — see BrainrotFactory.placeOnSurface (measured
-- bounding-box placement, not the PIVOT_ABOVE_FEET constant) and the
-- small staggered labels there.
-- v5 VISUAL POLISH (user: the game looks ugly — make it genuinely good-
-- looking): one coordinated warm palette (sand, turquoise sea, grass,
-- cream walls, terracotta roofs) replaces the clashing rainbow; buildings
-- gain fascia, shutters, flower boxes, door frames and chimney smoke;
-- stalls show real fruit/bread goods; the plaza gets a fountain and stone
-- paths; the sea gets foam, the beach dunes and grass tufts; lighting is
-- warmer with bloom/sun-rays. Game loop, economy and the v4 measured
-- pivot (placeOnSurface) are untouched.
-- v6 DENSE REAL WORLD (user: still sunk + still lots of empty space —
-- make it like the real world, as cool as possible): (1) sinking — the
-- last absolute-Y placements are fixed at the source (palmTree and
-- marketStall now add BEACH_TOP_Y; arch posts/cap/sign and conveyor
-- lamps too), bases become real raised platforms (deck top Y=2, stone
-- skirt, entrance step) and the lighthouse is rebuilt as a tapered box
-- tower with NO cylinder rotations, so it stands perfectly straight;
-- (2) density — five new districts fill the whole 512x512 map (east
-- residential with park + pond, west farm with windmill + crop fields,
-- south beach resort, north promenade, three forest groves), plus a
-- marble statue, beach towels, a sandcastle, boulders, bushes and
-- flowers; (3) animals — nine new species (cat, rabbit, fox, deer,
-- frog, turtle, crab, seagull, fish) with per-species bob (rabbits and
-- frogs hop), fish swimming just under the sea with wagging tails and a
-- spinning windmill rotor; (4) textures — Cobblestone paths, Brick
-- windmill/well, Marble statue, Sand sandcastle, Fabric towels/umbrellas,
-- WoodPlanks boardwalks. Labels stagger 5 steps x 1.8 studs with smaller
-- billboards so they stop jumbling. Game loop, economy and the v4
-- measured pivot are untouched.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local WorldBuilder = {}

local BASE_COLORS = {
	-- v5: muted pastels, one warm family — no more saturated rainbow.
	Color3.fromRGB(232, 130, 110),
	Color3.fromRGB(130, 165, 200),
	Color3.fromRGB(150, 190, 130),
	Color3.fromRGB(225, 185, 110),
	Color3.fromRGB(175, 155, 205),
	Color3.fromRGB(110, 185, 175),
	Color3.fromRGB(220, 150, 165),
	Color3.fromRGB(235, 175, 125),
	Color3.fromRGB(140, 190, 215),
	Color3.fromRGB(160, 205, 170),
}

local BASE_Z = { -120, -60, 0, 60, 120 }
-- Slot columns: spaced 5.0 apart (was 4.4) so the 2.0x creatures (5.6-wide
-- bodies) overlap less; the outer pads end at X ±14.2, still inside the
-- 30-wide platform (half-width 15). Rows stay 8 apart.
local SLOT_COLS = { -12.5, -7.5, -2.5, 2.5, 7.5, 12.5 }
local SLOT_ROWS = { -8, 0, 8 }

-- Top of the sand beach. The project baseplate's top is at Y=0, so the
-- beach (and everything standing on it) uses this as its ground level.
local BEACH_TOP_Y = 0.2

-- Building scale: v3.3 makes the town's buildings ~1.8x bigger (Rot Ranch
-- reference), so they clearly tower over the ~5-stud player. Scaled
-- around each building's own ground centre. Every building helper
-- multiplies its widths, heights and offsets by BS.
local BS = 1.8

-- Houses are bigger and taller still (v3.4): their own scale HS ~2.5x the
-- original house, with extra-tall walls and a taller pitched roof, so they
-- read as two-storey houses towering over the player (and over the barn).
-- The corridor between the fences (X ±9) and the base platforms (X ±33)
-- is only ~24 studs wide, so the house porch is shallower than the other
-- buildings' and the houses sit at X ±27; their Z span stays inside the
-- gap between base rows, so they never touch a base platform.
local HS = 2.5

local function part(name, size, color, position, parent, material, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Position = position
	p.Parent = parent
	return p
end

-- A small board with a text label that faces the camera.
-- v4: SMALL and never AlwaysOnTop — v3.6 used 16-30-stud boards with a
-- 300x80 AlwaysOnTop billboard, so every sign in the spawn view merged
-- into one unreadable jumble that hid the brainrots behind it. Boards
-- are now at most ~7 studs wide with a 150x30 label, they sit high on a
-- single building/wall, and free-standing sign posts are gone entirely:
-- the only signs left are the one arch title, one small plate per base
-- (on its back wall, low) and one small plate per shop front.
local function signBoard(parent, position, text, textColor, boardSize)
	local board = part("Sign", boardSize or Vector3.new(7, 1.8, 0.4), Color3.fromRGB(70, 45, 30), position, parent)
	local gui = Instance.new("BillboardGui")
	gui.Name = "SignLabel"
	gui.Size = UDim2.new(0, 150, 0, 30)
	gui.AlwaysOnTop = false
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "SignText"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 220, 80)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextStrokeTransparency = 0
	label.Parent = gui
	return board, label
end

local function palmTree(parent, spot, index)
	-- v6: sit the whole palm on the sand top (BEACH_TOP_Y), not Y=0.
	spot = spot + Vector3.new(0, BEACH_TOP_Y, 0)
	local trunk = Instance.new("Part")
	trunk.Name = "PalmTrunk" .. index
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(9, 1.8, 1.8)
	trunk.Color = Color3.fromRGB(140, 95, 50)
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.CFrame = CFrame.new(spot + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Parent = parent
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		local leaf = Instance.new("Part")
		leaf.Name = "PalmLeaf" .. index .. "_" .. i
		leaf.Shape = Enum.PartType.Ball
		leaf.Size = Vector3.new(4.5, 2.2, 4.5)
		leaf.Color = (i % 2 == 0) and Color3.fromRGB(45, 165, 70) or Color3.fromRGB(60, 195, 85)
		leaf.Anchored = true
		leaf.CanCollide = false
		leaf.Position = spot + Vector3.new(math.cos(angle) * 2.6, 9.2, math.sin(angle) * 2.6)
		leaf.Parent = parent
	end
	local crown = Instance.new("Part")
	crown.Name = "PalmCrown" .. index
	crown.Shape = Enum.PartType.Ball
	crown.Size = Vector3.new(5, 4, 5)
	crown.Color = Color3.fromRGB(75, 210, 105)
	crown.Anchored = true
	crown.CanCollide = false
	crown.Position = spot + Vector3.new(0, 9.6, 0)
	crown.Parent = parent
	-- v5: coconuts under the crown.
	for i = 1, 3 do
		local nut = Instance.new("Part")
		nut.Name = "Coconut" .. index .. "_" .. i
		nut.Shape = Enum.PartType.Ball
		nut.Size = Vector3.new(1.1, 1.1, 1.1)
		nut.Color = Color3.fromRGB(120, 85, 45)
		nut.Anchored = true
		nut.CanCollide = false
		nut.Position = spot + Vector3.new(math.cos(i * 2.1) * 1.4, 8.2, math.sin(i * 2.1) * 1.4)
		nut.Parent = parent
	end
end

local function marketStall(parent, position, stripeA, stripeB, index)
	-- v6: sit the whole stall on the sand top (BEACH_TOP_Y), not Y=0.
	position = position + Vector3.new(0, BEACH_TOP_Y, 0)
	local stall = Instance.new("Folder")
	stall.Name = "Stall" .. index
	stall.Parent = parent
	part("Counter", Vector3.new(8, 2.4, 3), Color3.fromRGB(150, 100, 55), position + Vector3.new(0, 1.2, 0), stall, Enum.Material.Wood)
	for _, side in ipairs({ -1, 1 }) do
		part("StallPost", Vector3.new(0.5, 5, 0.5), Color3.fromRGB(90, 60, 35), position + Vector3.new(side * 3.8, 2.5, 0), stall, Enum.Material.Wood)
	end
	-- Striped awning: six alternating panels sloping gently forward.
	for i = 0, 5 do
		local color = (i % 2 == 0) and stripeA or stripeB
		local panel = part("Awning", Vector3.new(1.5, 0.25, 4.4), color, position + Vector3.new(-3.75 + i * 1.5, 5.2, 0.4), stall, Enum.Material.Fabric, false)
		panel.CFrame = CFrame.new(panel.Position) * CFrame.Angles(math.rad(-12), 0, 0)
	end
	-- v5: visible goods on the counter — fruit and bread, not one grey cube.
	for i, fruit in ipairs({
		{ Vector3.new(-2.2, 3.1, 0), Color3.fromRGB(240, 140, 50) },
		{ Vector3.new(-0.7, 3.1, 0), Color3.fromRGB(210, 70, 60) },
		{ Vector3.new(0.8, 3.1, 0), Color3.fromRGB(150, 195, 90) },
		{ Vector3.new(2.2, 3.1, 0), Color3.fromRGB(240, 200, 90) },
	}) do
		local f = Instance.new("Part")
		f.Name = "Fruit" .. i
		f.Shape = Enum.PartType.Ball
		f.Size = Vector3.new(1.1, 1.1, 1.1)
		f.Color = fruit[2]
		f.Anchored = true
		f.CanCollide = false
		f.Position = position + fruit[1]
		f.Parent = stall
	end
	for _, bx in ipairs({ -1.5, 1.5 }) do
		part("Bread", Vector3.new(1.4, 0.7, 1.0), Color3.fromRGB(220, 180, 120), position + Vector3.new(bx, 2.75, 0.9), stall, Enum.Material.SmoothPlastic, false)
	end
end

-- Pitched roof: two slanted panels meeting at a ridge, plus a ridge beam.
-- `center` is the ridge centre; halfSpan is the horizontal distance from
-- ridge to eave (including overhang), rise is eave-to-ridge height, len is
-- the roof length along the ridge. ridgeAxis "X" or "Z". `scale` sizes the
-- panel thickness and ridge beam (defaults to BS; houses pass HS).
local function pitchedRoof(parent, center, halfSpan, rise, len, color, ridgeAxis, scale)
	scale = scale or BS
	local slopeLen = math.sqrt(halfSpan * halfSpan + rise * rise) + 0.4
	local angle = math.atan(rise / halfSpan)
	for _, side in ipairs({ -1, 1 }) do
		local panel
		if ridgeAxis == "X" then
			panel = part("RoofPanel", Vector3.new(len, 0.4 * scale, slopeLen), color, center + Vector3.new(0, -rise / 2, side * halfSpan / 2), parent, Enum.Material.SmoothPlastic, false)
			panel.CFrame = CFrame.new(panel.Position) * CFrame.Angles(side * angle, 0, 0)
		else
			panel = part("RoofPanel", Vector3.new(slopeLen, 0.4 * scale, len), color, center + Vector3.new(side * halfSpan / 2, -rise / 2, 0), parent, Enum.Material.SmoothPlastic, false)
			panel.CFrame = CFrame.new(panel.Position) * CFrame.Angles(0, 0, -side * angle)
		end
	end
	-- v5: cream fascia boards along both eaves.
	if ridgeAxis == "X" then
		for _, side in ipairs({ -1, 1 }) do
			part("RoofFascia", Vector3.new(len, 0.5 * scale, 0.35 * scale), Color3.fromRGB(250, 240, 220), center + Vector3.new(0, -rise + 0.15, side * halfSpan), parent, Enum.Material.SmoothPlastic, false)
		end
	else
		for _, side in ipairs({ -1, 1 }) do
			part("RoofFascia", Vector3.new(0.35 * scale, 0.5 * scale, len), Color3.fromRGB(250, 240, 220), center + Vector3.new(side * halfSpan, -rise + 0.15, 0), parent, Enum.Material.SmoothPlastic, false)
		end
	end
	if ridgeAxis == "X" then
		part("RidgeBeam", Vector3.new(len, 0.6 * scale, 0.6 * scale), Color3.fromRGB(90, 60, 35), center, parent, Enum.Material.Wood)
	else
		part("RidgeBeam", Vector3.new(0.6 * scale, 0.6 * scale, len), Color3.fromRGB(90, 60, 35), center, parent, Enum.Material.Wood)
	end
end

-- A window on a wall facing +/-X: white frame + light-blue glass.
-- `scale` sizes the frame and glass (defaults to BS; houses pass HS).
local function xWindow(parent, x, y, z, facing, scale)
	scale = scale or BS
	part("WindowFrame", Vector3.new(0.2 * scale, 2.2 * scale, 2.6 * scale), Color3.fromRGB(255, 255, 255), Vector3.new(x + facing * 0.1 * scale, y, z), parent, Enum.Material.SmoothPlastic, false)
	part("WindowGlass", Vector3.new(0.26 * scale, 1.8 * scale, 2.2 * scale), Color3.fromRGB(150, 210, 255), Vector3.new(x + facing * 0.14 * scale, y, z), parent, Enum.Material.Glass, false)
	-- v5: shutters and a flower box under every window.
	for _, sz in ipairs({ -1, 1 }) do
		part("WindowShutter", Vector3.new(0.15 * scale, 2.2 * scale, 0.9 * scale), Color3.fromRGB(180, 90, 60), Vector3.new(x + facing * 0.12 * scale, y, z + sz * 1.75 * scale), parent, Enum.Material.Wood, false)
	end
	part("FlowerBox", Vector3.new(0.5 * scale, 0.5 * scale, 2.4 * scale), Color3.fromRGB(120, 80, 45), Vector3.new(x + facing * 0.3 * scale, y - 1.35 * scale, z), parent, Enum.Material.Wood, false)
	local petalColors = { Color3.fromRGB(235, 120, 150), Color3.fromRGB(240, 200, 90), Color3.fromRGB(255, 255, 255) }
	for fi, fx in ipairs({ -0.8, 0, 0.8 }) do
		part("WindowFlower", Vector3.new(0.45 * scale, 0.45 * scale, 0.45 * scale), petalColors[fi], Vector3.new(x + facing * 0.3 * scale, y - 1.0 * scale, z + fx * scale), parent, Enum.Material.SmoothPlastic, false)
	end
end

-- v5: chimney smoke — three soft puffs drifting up from a chimney top.
local function chimneySmoke(parent, x, y, z)
	for i, s in ipairs({ 1.2, 1.7, 2.2 }) do
		local puff = Instance.new("Part")
		puff.Name = "Smoke"
		puff.Shape = Enum.PartType.Ball
		puff.Size = Vector3.new(s, s, s)
		puff.Color = Color3.fromRGB(245, 245, 245)
		puff.Transparency = 0.55
		puff.Anchored = true
		puff.CanCollide = false
		puff.Position = Vector3.new(x + i * 0.5, y + i * 1.5, z)
		puff.Parent = parent
	end
end

-- A detailed two-storey beach house (v3.4: HS ~2.5x, extra-tall walls and
-- roof so it towers over the player and the barn): wood walls, white base
-- trim and a mid trim band, door + two rows of framed windows (ground and
-- second floor) on the conveyor-facing side, tall pitched roof with ridge
-- beam, chimney, and a little porch (floor, posts, striped awning). The
-- porch is shallower than the other buildings' so it clears the fences.
-- facing +1 = front toward +X, -1 = front toward -X.
local function house(parent, pos, wallColor, roofColor, facing, index)
	local home = Instance.new("Folder")
	home.Name = "House" .. index
	home.Parent = parent
	local W, D, H = 10 * HS, 8 * HS, 9 * HS
	local baseY = BEACH_TOP_Y
	part("Walls", Vector3.new(W, H, D), wallColor, pos + Vector3.new(0, baseY + H / 2, 0), home, Enum.Material.Wood)
	part("BaseTrim", Vector3.new(W + 0.4 * HS, 0.5 * HS, D + 0.4 * HS), Color3.fromRGB(255, 255, 255), pos + Vector3.new(0, baseY + 0.25 * HS, 0), home, Enum.Material.SmoothPlastic, false)
	-- Trim band between the two storeys.
	part("MidTrim", Vector3.new(W + 0.4 * HS, 0.4 * HS, D + 0.4 * HS), Color3.fromRGB(255, 255, 255), pos + Vector3.new(0, baseY + 5.6 * HS, 0), home, Enum.Material.SmoothPlastic, false)
	local faceX = pos.X + facing * (W / 2)
	part("Door", Vector3.new(0.3 * HS, 3.6 * HS, 2 * HS), Color3.fromRGB(90, 60, 35), Vector3.new(faceX + facing * 0.16 * HS, baseY + 1.8 * HS, pos.Z), home, Enum.Material.Wood)
	-- v5: cream door frame + brass knob.
	for _, pz in ipairs({ -1.3 * HS, 1.3 * HS }) do
		part("DoorFrame", Vector3.new(0.4 * HS, 3.9 * HS, 0.4 * HS), Color3.fromRGB(250, 240, 220), Vector3.new(faceX + facing * 0.2 * HS, baseY + 1.95 * HS, pos.Z + pz), home, Enum.Material.SmoothPlastic, false)
	end
	part("DoorLintel", Vector3.new(0.4 * HS, 0.4 * HS, 3.0 * HS), Color3.fromRGB(250, 240, 220), Vector3.new(faceX + facing * 0.2 * HS, baseY + 3.9 * HS, pos.Z), home, Enum.Material.SmoothPlastic, false)
	local knob = Instance.new("Part")
	knob.Name = "DoorKnob"
	knob.Shape = Enum.PartType.Ball
	knob.Size = Vector3.new(0.35 * HS, 0.35 * HS, 0.35 * HS)
	knob.Color = Color3.fromRGB(230, 185, 95)
	knob.Material = Enum.Material.Neon
	knob.Anchored = true
	knob.CanCollide = false
	knob.Position = Vector3.new(faceX + facing * 0.4 * HS, baseY + 1.8 * HS, pos.Z + 0.6 * HS)
	knob.Parent = home
	-- Two rows of windows on the front: ground floor and second floor.
	for _, wy in ipairs({ 3.6 * HS, 7.4 * HS }) do
		xWindow(home, faceX, baseY + wy, pos.Z - 2.6 * HS, facing, HS)
		xWindow(home, faceX, baseY + wy, pos.Z + 2.6 * HS, facing, HS)
	end
	local ridgeY = baseY + H + 4 * HS
	pitchedRoof(home, Vector3.new(pos.X, ridgeY, pos.Z), W / 2 + 1 * HS, 4 * HS, D + 1 * HS, roofColor, "Z", HS)
	local cx = pos.X + 3 * HS
	part("Chimney", Vector3.new(1.2 * HS, 3 * HS, 1.2 * HS), Color3.fromRGB(150, 60, 60), Vector3.new(cx, ridgeY - 1 * HS, pos.Z - 2 * HS), home, Enum.Material.SmoothPlastic)
	part("ChimneyCap", Vector3.new(1.8 * HS, 0.5 * HS, 1.8 * HS), Color3.fromRGB(90, 60, 35), Vector3.new(cx, ridgeY + 0.7 * HS, pos.Z - 2 * HS), home, Enum.Material.SmoothPlastic, false)
	chimneySmoke(home, cx, ridgeY + 1.0 * HS, pos.Z - 2 * HS)
	-- Shallower porch: floor only 2*HS deep in X, so its outer edge stops
	-- a stud short of the fences at X ±9.
	local porchX = faceX + facing * 0.8 * HS
	part("PorchFloor", Vector3.new(2 * HS, 0.3 * HS, 4.5 * HS), Color3.fromRGB(150, 100, 55), Vector3.new(porchX, baseY + 0.15 * HS, pos.Z), home, Enum.Material.Wood)
	for _, pz in ipairs({ -1.8 * HS, 1.8 * HS }) do
		part("PorchPost", Vector3.new(0.5 * HS, 4.4 * HS, 0.5 * HS), Color3.fromRGB(90, 60, 35), Vector3.new(porchX + facing * 1.0 * HS, baseY + 2.2 * HS, pos.Z + pz), home, Enum.Material.Wood)
	end
	local awn = part("PorchAwning", Vector3.new(2.2 * HS, 0.25 * HS, 4.6 * HS), roofColor, Vector3.new(porchX + facing * 0.3 * HS, baseY + 4.4 * HS, pos.Z), home, Enum.Material.Fabric, false)
	awn.CFrame = CFrame.new(awn.Position) * CFrame.Angles(0, 0, facing * math.rad(-12))
end

-- A big red barn: double doors with a beam, hayloft door + beam, windows
-- on both long sides, pitched roof (ridge along X), chimney and porch.
-- The front faces +Z (toward the plaza).
local function barn(parent, pos, wallColor, roofColor, index)
	local b = Instance.new("Folder")
	b.Name = "Barn" .. index
	b.Parent = parent
	local W, D, H = 14 * BS, 10 * BS, 9 * BS
	local baseY = BEACH_TOP_Y
	part("Walls", Vector3.new(W, H, D), wallColor, pos + Vector3.new(0, baseY + H / 2, 0), b, Enum.Material.Wood)
	part("BaseTrim", Vector3.new(W + 0.4 * BS, 0.5 * BS, D + 0.4 * BS), Color3.fromRGB(255, 255, 255), pos + Vector3.new(0, baseY + 0.25 * BS, 0), b, Enum.Material.SmoothPlastic, false)
	local faceZ = pos.Z + D / 2
	for _, dx in ipairs({ -1.3 * BS, 1.3 * BS }) do
		part("BarnDoor", Vector3.new(2.4 * BS, 4.6 * BS, 0.3 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X + dx, baseY + 2.3 * BS, faceZ + 0.16 * BS), b, Enum.Material.Wood)
	end
	part("DoorBeam", Vector3.new(5.6 * BS, 0.5 * BS, 0.35 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X, baseY + 4.9 * BS, faceZ + 0.16 * BS), b, Enum.Material.Wood)
	-- v5: cream frame around the double doors.
	for _, px in ipairs({ -2.9 * BS, 2.9 * BS }) do
		part("DoorFrame", Vector3.new(0.4 * BS, 5.0 * BS, 0.4 * BS), Color3.fromRGB(250, 240, 220), Vector3.new(pos.X + px, baseY + 2.5 * BS, faceZ + 0.2 * BS), b, Enum.Material.SmoothPlastic, false)
	end
	part("DoorLintel", Vector3.new(6.2 * BS, 0.4 * BS, 0.4 * BS), Color3.fromRGB(250, 240, 220), Vector3.new(pos.X, baseY + 5.1 * BS, faceZ + 0.2 * BS), b, Enum.Material.SmoothPlastic, false)
	part("LoftDoor", Vector3.new(2 * BS, 2 * BS, 0.3 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X, baseY + 7 * BS, faceZ + 0.16 * BS), b, Enum.Material.Wood)
	part("LoftBeam", Vector3.new(3 * BS, 0.4 * BS, 0.4 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X, baseY + 8.3 * BS, faceZ + 0.2 * BS), b, Enum.Material.Wood)
	for _, sx in ipairs({ -1, 1 }) do
		local wx = pos.X + sx * (W / 2)
		xWindow(b, wx, baseY + 4.5 * BS, pos.Z - 2.5 * BS, sx)
		xWindow(b, wx, baseY + 4.5 * BS, pos.Z + 2.5 * BS, sx)
	end
	local ridgeY = baseY + H + 3.5 * BS
	pitchedRoof(b, Vector3.new(pos.X, ridgeY, pos.Z), D / 2 + 1 * BS, 3.5 * BS, W + 1 * BS, roofColor, "X")
	part("Chimney", Vector3.new(1.2 * BS, 3 * BS, 1.2 * BS), Color3.fromRGB(150, 60, 60), Vector3.new(pos.X - 3 * BS, ridgeY - 1 * BS, pos.Z + 3 * BS), b, Enum.Material.SmoothPlastic)
	part("ChimneyCap", Vector3.new(1.8 * BS, 0.5 * BS, 1.8 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X - 3 * BS, ridgeY + 0.7 * BS, pos.Z + 3 * BS), b, Enum.Material.SmoothPlastic, false)
	chimneySmoke(b, pos.X - 3 * BS, ridgeY + 1.0 * BS, pos.Z + 3 * BS)
	local porchZ = faceZ + 1.6 * BS
	part("PorchFloor", Vector3.new(6 * BS, 0.3 * BS, 3 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(pos.X, baseY + 0.15 * BS, porchZ), b, Enum.Material.Wood)
	for _, px in ipairs({ -2.6 * BS, 2.6 * BS }) do
		part("PorchPost", Vector3.new(0.5 * BS, 5.4 * BS, 0.5 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X + px, baseY + 2.9 * BS, porchZ + 1.2 * BS), b, Enum.Material.Wood)
	end
	local awn = part("PorchAwning", Vector3.new(6.2 * BS, 0.25 * BS, 3.2 * BS), roofColor, Vector3.new(pos.X, baseY + 5.4 * BS, porchZ + 0.4 * BS), b, Enum.Material.Fabric, false)
	awn.CFrame = CFrame.new(awn.Position) * CFrame.Angles(math.rad(12), 0, 0)
	-- v5: a hay bale by the porch.
	local bale = Instance.new("Part")
	bale.Name = "HayBale"
	bale.Shape = Enum.PartType.Cylinder
	bale.Size = Vector3.new(3, 2.2, 2.2)
	bale.Color = Color3.fromRGB(230, 200, 80)
	bale.Anchored = true
	bale.CanCollide = true
	bale.Position = Vector3.new(pos.X + 5.5 * BS, baseY + 1.1 * BS, porchZ)
	bale.Parent = b
end

-- A market shop: big display window, door, striped awning, sign board,
-- pitched roof (ridge along X) and chimney. The front faces +Z.
local function shop(parent, pos, wallColor, roofColor, index, name)
	local s = Instance.new("Folder")
	s.Name = "Shop" .. index
	s.Parent = parent
	local W, D, H = 11 * BS, 9 * BS, 7 * BS
	local baseY = BEACH_TOP_Y
	part("Walls", Vector3.new(W, H, D), wallColor, pos + Vector3.new(0, baseY + H / 2, 0), s, Enum.Material.Wood)
	part("BaseTrim", Vector3.new(W + 0.4 * BS, 0.5 * BS, D + 0.4 * BS), Color3.fromRGB(255, 255, 255), pos + Vector3.new(0, baseY + 0.25 * BS, 0), s, Enum.Material.SmoothPlastic, false)
	local faceZ = pos.Z + D / 2
	part("Door", Vector3.new(2 * BS, 3.6 * BS, 0.3 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X - 2.5 * BS, baseY + 1.8 * BS, faceZ + 0.16 * BS), s, Enum.Material.Wood)
	-- v5: cream door frame.
	for _, dx in ipairs({ -1.3 * BS, 1.3 * BS }) do
		part("DoorFrame", Vector3.new(0.4 * BS, 3.9 * BS, 0.4 * BS), Color3.fromRGB(250, 240, 220), Vector3.new(pos.X - 2.5 * BS + dx, baseY + 1.95 * BS, faceZ + 0.2 * BS), s, Enum.Material.SmoothPlastic, false)
	end
	part("DoorLintel", Vector3.new(3.0 * BS, 0.4 * BS, 0.4 * BS), Color3.fromRGB(250, 240, 220), Vector3.new(pos.X - 2.5 * BS, baseY + 3.9 * BS, faceZ + 0.2 * BS), s, Enum.Material.SmoothPlastic, false)
	part("ShopWindowFrame", Vector3.new(4.5 * BS, 2.6 * BS, 0.2 * BS), Color3.fromRGB(255, 255, 255), Vector3.new(pos.X + 2 * BS, baseY + 3.4 * BS, faceZ + 0.1 * BS), s, Enum.Material.SmoothPlastic, false)
	part("ShopWindowGlass", Vector3.new(4.1 * BS, 2.2 * BS, 0.26 * BS), Color3.fromRGB(150, 210, 255), Vector3.new(pos.X + 2 * BS, baseY + 3.4 * BS, faceZ + 0.14 * BS), s, Enum.Material.Glass, false)
	xWindow(s, pos.X + W / 2, baseY + 3.6 * BS, pos.Z, 1)
	xWindow(s, pos.X - W / 2, baseY + 3.6 * BS, pos.Z, -1)
	signBoard(s, Vector3.new(pos.X, baseY + 5.8 * BS, faceZ + 0.4 * BS), name or "TIDE SHOP", Color3.fromRGB(255, 220, 80), Vector3.new(6, 1.5, 0.4))
	local ridgeY = baseY + H + 3 * BS
	pitchedRoof(s, Vector3.new(pos.X, ridgeY, pos.Z), D / 2 + 1 * BS, 3 * BS, W + 1 * BS, roofColor, "X")
	part("Chimney", Vector3.new(1.2 * BS, 3 * BS, 1.2 * BS), Color3.fromRGB(150, 60, 60), Vector3.new(pos.X + 3 * BS, ridgeY - 1 * BS, pos.Z + 2 * BS), s, Enum.Material.SmoothPlastic)
	part("ChimneyCap", Vector3.new(1.8 * BS, 0.5 * BS, 1.8 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X + 3 * BS, ridgeY + 0.7 * BS, pos.Z + 2 * BS), s, Enum.Material.SmoothPlastic, false)
	chimneySmoke(s, pos.X + 3 * BS, ridgeY + 1.0 * BS, pos.Z + 2 * BS)
	for i = 0, 2 do
		local color = (i % 2 == 0) and roofColor or Color3.fromRGB(255, 255, 255)
		local panel = part("ShopAwning", Vector3.new(1.6 * BS, 0.25 * BS, 2.2 * BS), color, Vector3.new(pos.X + 0.4 * BS + i * 1.6 * BS, baseY + 5.0 * BS, faceZ + 0.9 * BS), s, Enum.Material.Fabric, false)
		panel.CFrame = CFrame.new(panel.Position) * CFrame.Angles(math.rad(12), 0, 0)
	end
	part("PorchFloor", Vector3.new(4 * BS, 0.3 * BS, 2.5 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(pos.X - 2.5 * BS, baseY + 0.15 * BS, faceZ + 1.4 * BS), s, Enum.Material.Wood)
	-- v5: goods on display outside the shop — fruit on a table, fish in a crate.
	part("DisplayTable", Vector3.new(3.5 * BS, 1 * BS, 2 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(pos.X + 2 * BS, baseY + 0.5 * BS, faceZ + 2.2 * BS), s, Enum.Material.Wood)
	for i, fruit in ipairs({ Color3.fromRGB(240, 140, 50), Color3.fromRGB(210, 70, 60), Color3.fromRGB(150, 195, 90) }) do
		local f = Instance.new("Part")
		f.Name = "ShopFruit" .. i
		f.Shape = Enum.PartType.Ball
		f.Size = Vector3.new(1.1, 1.1, 1.1)
		f.Color = fruit
		f.Anchored = true
		f.CanCollide = false
		f.Position = Vector3.new(pos.X + (0.8 + i * 1.1) * BS, baseY + 1.55 * BS, faceZ + 2.2 * BS)
		f.Parent = s
	end
	part("FishCrate", Vector3.new(2 * BS, 1.6 * BS, 2 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(pos.X - 5.5 * BS, baseY + 0.8 * BS, faceZ + 1.6 * BS), s, Enum.Material.Wood)
	for _, fx in ipairs({ -0.5, 0.5 }) do
		part("Fish", Vector3.new(1.2 * BS, 0.35 * BS, 0.5 * BS), Color3.fromRGB(150, 185, 205), Vector3.new(pos.X - 5.5 * BS + fx * BS, baseY + 1.8 * BS, faceZ + 1.6 * BS), s, Enum.Material.SmoothPlastic, false)
	end
end

-- A small hut with a single-slope (shed) roof, door + windows on the
-- conveyor-facing side and a striped awning. facing +1 = front toward +X.
local function hut(parent, pos, wallColor, roofColor, facing, index)
	local h = Instance.new("Folder")
	h.Name = "Hut" .. index
	h.Parent = parent
	local W, D, H = 8 * BS, 7 * BS, 6 * BS
	local baseY = BEACH_TOP_Y
	part("Walls", Vector3.new(W, H, D), wallColor, pos + Vector3.new(0, baseY + H / 2, 0), h, Enum.Material.Wood)
	part("BaseTrim", Vector3.new(W + 0.4 * BS, 0.4 * BS, D + 0.4 * BS), Color3.fromRGB(255, 255, 255), pos + Vector3.new(0, baseY + 0.2 * BS, 0), h, Enum.Material.SmoothPlastic, false)
	local faceX = pos.X + facing * (W / 2)
	part("Door", Vector3.new(0.3 * BS, 3.2 * BS, 1.8 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(faceX + facing * 0.16 * BS, baseY + 1.6 * BS, pos.Z), h, Enum.Material.Wood)
	-- v5: cream door frame.
	for _, pz in ipairs({ -1.2 * BS, 1.2 * BS }) do
		part("DoorFrame", Vector3.new(0.4 * BS, 3.5 * BS, 0.4 * BS), Color3.fromRGB(250, 240, 220), Vector3.new(faceX + facing * 0.2 * BS, baseY + 1.75 * BS, pos.Z + pz), h, Enum.Material.SmoothPlastic, false)
	end
	part("DoorLintel", Vector3.new(0.4 * BS, 0.4 * BS, 2.8 * BS), Color3.fromRGB(250, 240, 220), Vector3.new(faceX + facing * 0.2 * BS, baseY + 3.5 * BS, pos.Z), h, Enum.Material.SmoothPlastic, false)
	xWindow(h, faceX, baseY + 3.4 * BS, pos.Z - 2.2 * BS, facing)
	xWindow(h, faceX, baseY + 3.4 * BS, pos.Z + 2.2 * BS, facing)
	local roof = part("ShedRoof", Vector3.new(W + 1.5 * BS, 0.35 * BS, D + 1 * BS), roofColor, Vector3.new(pos.X, baseY + H + 1.6 * BS, pos.Z), h, Enum.Material.SmoothPlastic, false)
	roof.CFrame = CFrame.new(roof.Position) * CFrame.Angles(0, 0, facing * math.rad(-20))
	local awn = part("HutAwning", Vector3.new(2.8 * BS, 0.25 * BS, 3.4 * BS), roofColor, Vector3.new(faceX + facing * 0.9 * BS, baseY + 5.2 * BS, pos.Z), h, Enum.Material.Fabric, false)
	awn.CFrame = CFrame.new(awn.Position) * CFrame.Angles(0, 0, facing * math.rad(-12))
end

-- Gatehouse over the plaza walkway: two towers, a beam and a small pitched
-- cap. Players walk between the towers toward the conveyor.
local function gatehouse(parent, pos)
	local g = Instance.new("Folder")
	g.Name = "Gatehouse"
	g.Parent = parent
	local baseY = BEACH_TOP_Y
	for _, sx in ipairs({ -1, 1 }) do
		part("GateTower", Vector3.new(3 * BS, 9 * BS, 3 * BS), Color3.fromRGB(250, 235, 205), Vector3.new(pos.X + sx * 10 * BS, baseY + 4.5 * BS, pos.Z), g, Enum.Material.SmoothPlastic)
		part("TowerCap", Vector3.new(3.8 * BS, 0.6 * BS, 3.8 * BS), Color3.fromRGB(198, 102, 62), Vector3.new(pos.X + sx * 10 * BS, baseY + 9.3 * BS, pos.Z), g, Enum.Material.SmoothPlastic, false)
	end
	part("GateBeam", Vector3.new(23 * BS, 2 * BS, 3 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(pos.X, baseY + 9.5 * BS, pos.Z), g, Enum.Material.Wood)
	pitchedRoof(g, Vector3.new(pos.X, baseY + 11.5 * BS, pos.Z), 2.5 * BS, 1.5 * BS, 24 * BS, Color3.fromRGB(175, 80, 55), "Z")
end

-- A wooden fence run along Z: posts every ~10 studs + two rails.
local function fenceRun(parent, x, zA, zB, index)
	local f = Instance.new("Folder")
	f.Name = "Fence" .. index
	f.Parent = parent
	local baseY = BEACH_TOP_Y
	local n = math.floor((zB - zA) / 10 + 0.5)
	for i = 0, n do
		local z = zA + (zB - zA) * (i / n)
		part("FencePost", Vector3.new(0.5, 3, 0.5), Color3.fromRGB(150, 100, 55), Vector3.new(x, baseY + 1.5, z), f, Enum.Material.Wood)
	end
	for _, ry in ipairs({ 1.2, 2.4 }) do
		part("FenceRail", Vector3.new(0.3, 0.3, zB - zA), Color3.fromRGB(150, 100, 55), Vector3.new(x, baseY + ry, (zA + zB) / 2), f, Enum.Material.Wood, false)
	end
end

-- A round leafy tree: trunk + three leaf balls.
local function roundTree(parent, spot, index)
	local t = Instance.new("Folder")
	t.Name = "Tree" .. index
	t.Parent = parent
	local baseY = BEACH_TOP_Y
	local trunk = Instance.new("Part")
	trunk.Name = "TreeTrunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(7, 1.6, 1.6)
	trunk.Color = Color3.fromRGB(140, 95, 50)
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.CFrame = CFrame.new(spot + Vector3.new(0, baseY + 3.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Parent = t
	for _, leaf in ipairs({
		-- v5: layered canopy — dark base, mid green, light top.
		{ Vector3.new(0, 8.5, 0), 6.5, Color3.fromRGB(55, 175, 80) },
		{ Vector3.new(-2.2, 7, 0), 4.5, Color3.fromRGB(45, 160, 70) },
		{ Vector3.new(2.2, 7, 0), 4.5, Color3.fromRGB(45, 160, 70) },
		{ Vector3.new(0, 10.2, 0), 4.5, Color3.fromRGB(90, 205, 100) },
		{ Vector3.new(-1.5, 9.2, 1.5), 3.5, Color3.fromRGB(75, 195, 90) },
	}) do
		local ball = Instance.new("Part")
		ball.Name = "TreeLeaves"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(leaf[2], leaf[2], leaf[2])
		ball.Color = leaf[3]
		ball.Anchored = true
		ball.CanCollide = false
		ball.Position = spot + leaf[1] + Vector3.new(0, baseY, 0)
		ball.Parent = t
	end
end

-- A tall tree (v3.4): ~12-stud trunk + three leaf balls, ~19 studs tall
-- in total. Returns a sway entry: the trunk and leaves are animated by
-- the single animation loop in build(), leaning/swaying a few degrees
-- around the trunk base/top. `phase` staggers the sway per tree.
local function tallTree(parent, spot, index)
	local t = Instance.new("Folder")
	t.Name = "TallTree" .. index
	t.Parent = parent
	local baseY = BEACH_TOP_Y
	local base = spot + Vector3.new(0, baseY, 0)
	local trunkLen = 12
	local trunk = Instance.new("Part")
	trunk.Name = "TallTrunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(trunkLen, 2, 2)
	trunk.Color = Color3.fromRGB(140, 95, 50)
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.CFrame = CFrame.new(base + Vector3.new(0, trunkLen / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Parent = t
	local leaves = {}
	for _, leaf in ipairs({
		{ Vector3.new(0, 2.5, 0), 9, Color3.fromRGB(60, 190, 85) },
		{ Vector3.new(-2.8, 0, 0), 6.5, Color3.fromRGB(45, 165, 75) },
		{ Vector3.new(2.8, 0, 0), 6.5, Color3.fromRGB(45, 165, 75) },
	}) do
		local ball = Instance.new("Part")
		ball.Name = "TallLeaves"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(leaf[2], leaf[2], leaf[2])
		ball.Color = leaf[3]
		ball.Anchored = true
		ball.CanCollide = false
		ball.Position = base + Vector3.new(0, trunkLen, 0) + leaf[1]
		ball.Parent = t
		table.insert(leaves, { part = ball, offset = leaf[1] })
	end
	return {
		base = base,
		trunk = trunk,
		trunkLen = trunkLen,
		leaves = leaves,
		phase = index * 1.3,
	}
end

-- Ambient animals (v3.4): built from plain Parts, BrainrotFactory-style.
-- They are PURELY decorative: no ProximityPrompt, no gameplay effect, and
-- they stay on open beach away from the conveyor and the bases. Each
-- builder returns a Model whose PrimaryPart is the body; the single
-- animation loop in build() moves them with PivotTo. All parts Anchored.
local function animalPart(name, size, color, position, parent, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Position = position
	p.Parent = parent
	return p
end

local function animalCylinder(name, diameter, length, color, position, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(length, diameter, diameter)
	p.Color = color
	p.Anchored = true
	p.CanCollide = false
	p.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	p.Parent = parent
	return p
end

-- A cow: white body with black spots, pink snout and udder, horns, tail.
-- Body centre (PrimaryPart) at model Y 2.5, feet at model Y 0.
local function buildCow()
	local model = Instance.new("Model")
	model.Name = "Cow"
	local white = Color3.fromRGB(245, 245, 245)
	local body = animalPart("Body", Vector3.new(2.4, 2.2, 4), white, Vector3.new(0, 2.5, 0), model)
	model.PrimaryPart = body
	animalPart("Head", Vector3.new(2, 1.8, 1.8), white, Vector3.new(0, 3.4, 2.4), model)
	animalPart("Snout", Vector3.new(1.4, 0.8, 0.5), Color3.fromRGB(255, 180, 200), Vector3.new(0, 3.1, 3.4), model)
	for _, sx in ipairs({ -1, 1 }) do
		animalPart("Eye", Vector3.new(0.4, 0.4, 0.12), white, Vector3.new(sx * 0.5, 3.7, 3.32), model)
		animalPart("Pupil", Vector3.new(0.2, 0.2, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.5, 3.7, 3.36), model)
		local horn = animalPart("Horn", Vector3.new(0.3, 0.8, 0.3), Color3.fromRGB(240, 220, 180), Vector3.new(sx * 0.7, 4.5, 2.4), model)
		horn.CFrame = CFrame.new(horn.Position) * CFrame.Angles(0, 0, sx * -0.3)
		animalPart("Ear", Vector3.new(0.9, 0.5, 0.15), white, Vector3.new(sx * 1.3, 3.9, 2.4), model)
		animalCylinder("Leg", 0.5, 1.4, white, Vector3.new(sx * 0.8, 0.7, 1.4), model)
		animalCylinder("Leg", 0.5, 1.4, white, Vector3.new(sx * 0.8, 0.7, -1.4), model)
		animalPart("Hoof", Vector3.new(0.55, 0.3, 0.55), Color3.fromRGB(60, 60, 60), Vector3.new(sx * 0.8, 0.15, 1.4), model)
		animalPart("Hoof", Vector3.new(0.55, 0.3, 0.55), Color3.fromRGB(60, 60, 60), Vector3.new(sx * 0.8, 0.15, -1.4), model)
		animalPart("Spot", Vector3.new(0.12, 1.0, 1.4), Color3.fromRGB(30, 30, 30), Vector3.new(sx * 1.22, 2.8, 0.5), model)
	end
	animalPart("SpotTop", Vector3.new(1.2, 0.12, 1.4), Color3.fromRGB(30, 30, 30), Vector3.new(0, 3.62, -0.8), model)
	animalPart("Udder", Vector3.new(1.2, 0.7, 1.4), Color3.fromRGB(255, 180, 200), Vector3.new(0, 1.2, -0.5), model)
	animalPart("Tail", Vector3.new(0.3, 1.6, 0.3), Color3.fromRGB(90, 60, 35), Vector3.new(0, 2.2, -2.1), model)
	local tuft = Instance.new("Part")
	tuft.Name = "TailTuft"
	tuft.Shape = Enum.PartType.Ball
	tuft.Size = Vector3.new(0.6, 0.6, 0.6)
	tuft.Color = Color3.fromRGB(60, 40, 25)
	tuft.Anchored = true
	tuft.CanCollide = false
	tuft.Position = Vector3.new(0, 1.3, -2.1)
	tuft.Parent = model
	return model, 2.5
end

-- A pig: pink ball body and head, snout, ears, little legs, curly tail.
-- Body centre (PrimaryPart) at model Y 2.0, feet at model Y 0.
local function buildPig()
	local model = Instance.new("Model")
	model.Name = "Pig"
	local pink = Color3.fromRGB(255, 170, 200)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(3.2, 3.2, 3.2)
	body.Color = pink
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 2.0, 0)
	body.Parent = model
	model.PrimaryPart = body
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.8, 1.8, 1.8)
	head.Color = pink
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, 2.7, 1.9)
	head.Parent = model
	local snout = Instance.new("Part")
	snout.Name = "Snout"
	snout.Shape = Enum.PartType.Cylinder
	snout.Size = Vector3.new(0.5, 0.9, 0.9)
	snout.Color = Color3.fromRGB(240, 130, 170)
	snout.Anchored = true
	snout.CanCollide = false
	snout.CFrame = CFrame.new(Vector3.new(0, 2.6, 2.9)) * CFrame.Angles(0, math.rad(90), 0)
	snout.Parent = model
	for _, sx in ipairs({ -1, 1 }) do
		animalPart("Eye", Vector3.new(0.25, 0.25, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.45, 2.9, 2.8), model)
		local ear = animalPart("Ear", Vector3.new(0.5, 0.7, 0.15), pink, Vector3.new(sx * 0.6, 3.6, 1.9), model)
		ear.CFrame = CFrame.new(ear.Position) * CFrame.Angles(0, 0, sx * -0.25)
		animalCylinder("Leg", 0.5, 1.0, Color3.fromRGB(240, 130, 170), Vector3.new(sx * 0.7, 0.5, 0.9), model)
		animalCylinder("Leg", 0.5, 1.0, Color3.fromRGB(240, 130, 170), Vector3.new(sx * 0.7, 0.5, -0.9), model)
	end
	local tail = animalPart("Tail", Vector3.new(0.2, 0.6, 0.2), Color3.fromRGB(240, 130, 170), Vector3.new(0, 2.3, -1.7), model)
	tail.CFrame = CFrame.new(tail.Position) * CFrame.Angles(math.rad(30), 0, 0)
	return model, 2.0
end

-- A chicken: white ball body and head, red comb, orange beak and legs.
-- Body centre (PrimaryPart) at model Y 1.6, feet at model Y 0.
local function buildChicken()
	local model = Instance.new("Model")
	model.Name = "Chicken"
	local white = Color3.fromRGB(245, 245, 245)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.2, 2.2, 2.2)
	body.Color = white
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 1.6, 0)
	body.Parent = model
	model.PrimaryPart = body
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Color = white
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, 3.1, 0.5)
	head.Parent = model
	for _, ox in ipairs({ -0.3, 0, 0.3 }) do
		animalPart("Comb", Vector3.new(0.3, 0.5, 0.3), Color3.fromRGB(220, 40, 40), Vector3.new(ox, 3.8, 0.5), model)
	end
	animalPart("Beak", Vector3.new(0.5, 0.35, 0.6), Color3.fromRGB(255, 170, 40), Vector3.new(0, 3.0, 1.25), model)
	for _, sx in ipairs({ -1, 1 }) do
		animalPart("Eye", Vector3.new(0.2, 0.2, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.3, 3.2, 1.08), model)
		animalPart("Wing", Vector3.new(0.2, 1.2, 1.4), white, Vector3.new(sx * 1.15, 1.7, 0), model)
		animalCylinder("Leg", 0.2, 1.0, Color3.fromRGB(255, 170, 40), Vector3.new(sx * 0.4, 0.5, 0), model)
		local tail = animalPart("Tail", Vector3.new(0.15, 1.2, 0.7), white, Vector3.new(sx * 0.3, 2.6, -1.1), model)
		tail.CFrame = CFrame.new(tail.Position) * CFrame.Angles(math.rad(-30), 0, 0)
	end
	return model, 1.6
end

-- A bird: small ball body, wings that flap, beak and tail. The model
-- origin is the body centre; the orbit loop PivotTos it overhead.
-- Returns the model plus the wing flap data (attach point, centre, side).
local function buildBird(color)
	local model = Instance.new("Model")
	model.Name = "Bird"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(1.2, 1.2, 1.2)
	body.Color = color
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 0, 0)
	body.Parent = model
	model.PrimaryPart = body
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(0.8, 0.8, 0.8)
	head.Color = color
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, 0.4, 0.5)
	head.Parent = model
	animalPart("Beak", Vector3.new(0.3, 0.25, 0.5), Color3.fromRGB(255, 170, 40), Vector3.new(0, 0.35, 1.0), model)
	animalPart("Tail", Vector3.new(0.8, 0.12, 1.2), color, Vector3.new(0, -0.1, -0.9), model)
	local wings = {}
	for _, sx in ipairs({ -1, 1 }) do
		local wing = animalPart("Wing", Vector3.new(2.4, 0.15, 1.0), color, Vector3.new(sx * 1.7, 0.1, 0), model)
		table.insert(wings, {
			part = wing,
			attach = Vector3.new(sx * 0.55, 0.1, 0),
			centre = Vector3.new(sx * 1.7, 0.1, 0),
			side = sx,
		})
	end
	return model, wings
end

-- A dog: brown box body and head, floppy ears, snout, tail, four legs.
-- Body centre (PrimaryPart) at model Y 1.8, feet at model Y 0.
local function buildDog()
	local model = Instance.new("Model")
	model.Name = "Dog"
	local brown = Color3.fromRGB(150, 100, 55)
	local body = animalPart("Body", Vector3.new(2.2, 1.6, 3.2), brown, Vector3.new(0, 1.8, 0), model)
	model.PrimaryPart = body
	animalPart("Head", Vector3.new(1.6, 1.6, 1.6), brown, Vector3.new(0, 2.6, 1.9), model)
	animalPart("Snout", Vector3.new(1.0, 0.6, 0.7), Color3.fromRGB(200, 150, 100), Vector3.new(0, 2.4, 2.85), model)
	animalPart("Nose", Vector3.new(0.5, 0.4, 0.2), Color3.fromRGB(30, 30, 30), Vector3.new(0, 2.5, 3.2), model)
	for _, sx in ipairs({ -1, 1 }) do
		animalPart("Eye", Vector3.new(0.3, 0.3, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.45, 2.8, 2.72), model)
		local ear = animalPart("Ear", Vector3.new(0.4, 1.0, 0.7), Color3.fromRGB(110, 70, 35), Vector3.new(sx * 0.85, 2.7, 1.9), model)
		ear.CFrame = CFrame.new(ear.Position) * CFrame.Angles(0, 0, sx * 0.2)
		animalCylinder("Leg", 0.45, 1.2, brown, Vector3.new(sx * 0.7, 0.6, 1.1), model)
		animalCylinder("Leg", 0.45, 1.2, brown, Vector3.new(sx * 0.7, 0.6, -1.1), model)
	end
	animalPart("Chest", Vector3.new(1.4, 1.0, 0.2), Color3.fromRGB(245, 235, 220), Vector3.new(0, 1.6, 1.62), model)
	local tail = animalPart("Tail", Vector3.new(0.3, 1.4, 0.3), brown, Vector3.new(0, 2.4, -1.8), model)
	tail.CFrame = CFrame.new(tail.Position) * CFrame.Angles(math.rad(-35), 0, 0)
	return model, 1.8
end

-- A horse: tall box body, long neck and head, mane, tail, four long legs.
-- Body centre (PrimaryPart) at model Y 2.6, feet at model Y 0.
local function buildHorse()
	local model = Instance.new("Model")
	model.Name = "Horse"
	local brown = Color3.fromRGB(120, 80, 40)
	local dark = Color3.fromRGB(60, 40, 25)
	local body = animalPart("Body", Vector3.new(2.6, 2.4, 4.6), brown, Vector3.new(0, 2.6, 0), model)
	model.PrimaryPart = body
	local neck = animalPart("Neck", Vector3.new(1.6, 2.4, 1.6), brown, Vector3.new(0, 3.9, 2.2), model)
	neck.CFrame = CFrame.new(neck.Position) * CFrame.Angles(math.rad(-25), 0, 0)
	animalPart("Head", Vector3.new(1.6, 1.8, 2.4), brown, Vector3.new(0, 5.0, 2.9), model)
	animalPart("Snout", Vector3.new(1.2, 1.0, 0.8), Color3.fromRGB(200, 150, 100), Vector3.new(0, 4.7, 4.1), model)
	local mane = animalPart("Mane", Vector3.new(0.5, 3.0, 1.2), dark, Vector3.new(0, 4.3, 1.3), model)
	mane.CFrame = CFrame.new(mane.Position) * CFrame.Angles(math.rad(-25), 0, 0)
	for _, sx in ipairs({ -1, 1 }) do
		animalPart("Eye", Vector3.new(0.3, 0.3, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.55, 5.2, 4.05), model)
		animalPart("Ear", Vector3.new(0.4, 0.8, 0.4), brown, Vector3.new(sx * 0.5, 6.1, 2.7), model)
		animalCylinder("Leg", 0.55, 2.2, brown, Vector3.new(sx * 0.85, 1.1, 1.6), model)
		animalCylinder("Leg", 0.55, 2.2, brown, Vector3.new(sx * 0.85, 1.1, -1.6), model)
		animalPart("Hoof", Vector3.new(0.6, 0.3, 0.6), dark, Vector3.new(sx * 0.85, 0.15, 1.6), model)
		animalPart("Hoof", Vector3.new(0.6, 0.3, 0.6), dark, Vector3.new(sx * 0.85, 0.15, -1.6), model)
	end
	local tail = animalPart("Tail", Vector3.new(0.5, 2.4, 0.5), dark, Vector3.new(0, 2.4, -2.5), model)
	tail.CFrame = CFrame.new(tail.Position) * CFrame.Angles(math.rad(15), 0, 0)
	return model, 2.6
end

-- A duck: yellow ball body and head, orange beak and legs.
-- Body centre (PrimaryPart) at model Y 1.4, feet at model Y 0.
local function buildDuck()
	local model = Instance.new("Model")
	model.Name = "Duck"
	local yellow = Color3.fromRGB(255, 220, 80)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.0, 2.0, 2.0)
	body.Color = yellow
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 1.4, 0)
	body.Parent = model
	model.PrimaryPart = body
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Color = yellow
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, 2.6, 0.6)
	head.Parent = model
	animalPart("Beak", Vector3.new(0.7, 0.25, 0.7), Color3.fromRGB(255, 140, 40), Vector3.new(0, 2.5, 1.35), model)
	for _, sx in ipairs({ -1, 1 }) do
		animalPart("Eye", Vector3.new(0.2, 0.2, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.35, 2.7, 1.18), model)
		animalPart("Wing", Vector3.new(0.2, 0.9, 1.2), yellow, Vector3.new(sx * 1.05, 1.5, 0), model)
		animalCylinder("Leg", 0.2, 0.9, Color3.fromRGB(255, 140, 40), Vector3.new(sx * 0.4, 0.45, 0), model)
	end
	return model, 1.4
end

-- A sheep: fluffy white wool ball body, dark face and legs, wool puffs.
-- Body centre (PrimaryPart) at model Y 1.8, feet at model Y 0.
local function buildSheep()
	local model = Instance.new("Model")
	model.Name = "Sheep"
	local wool = Color3.fromRGB(245, 245, 245)
	local dark = Color3.fromRGB(60, 60, 60)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(3.0, 2.6, 3.0)
	body.Color = wool
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 1.8, 0)
	body.Parent = model
	model.PrimaryPart = body
	animalPart("Head", Vector3.new(1.4, 1.2, 1.2), dark, Vector3.new(0, 2.4, 1.7), model)
	animalPart("Snout", Vector3.new(0.9, 0.6, 0.4), dark, Vector3.new(0, 2.2, 2.35), model)
	for _, ox in ipairs({ -0.9, 0, 0.9 }) do
		local puff = Instance.new("Part")
		puff.Name = "WoolPuff"
		puff.Shape = Enum.PartType.Ball
		puff.Size = Vector3.new(1.4, 1.4, 1.4)
		puff.Color = wool
		puff.Anchored = true
		puff.CanCollide = false
		puff.Position = Vector3.new(ox, 3.1, 0)
		puff.Parent = model
	end
	for _, sx in ipairs({ -1, 1 }) do
		animalPart("Eye", Vector3.new(0.25, 0.25, 0.12), Color3.fromRGB(255, 255, 255), Vector3.new(sx * 0.4, 2.6, 2.32), model)
		animalPart("Ear", Vector3.new(0.6, 0.4, 0.2), dark, Vector3.new(sx * 0.85, 2.5, 1.7), model)
		animalCylinder("Leg", 0.4, 1.2, dark, Vector3.new(sx * 0.7, 0.6, 0.9), model)
		animalCylinder("Leg", 0.4, 1.2, dark, Vector3.new(sx * 0.7, 0.6, -0.9), model)
	end
	return model, 1.8
end

-- A goat: white box body, bearded head with horns, four legs.
-- Body centre (PrimaryPart) at model Y 1.8, feet at model Y 0.
local function buildGoat()
	local model = Instance.new("Model")
	model.Name = "Goat"
	local white = Color3.fromRGB(230, 230, 230)
	local body = animalPart("Body", Vector3.new(2.2, 1.8, 3.4), white, Vector3.new(0, 1.8, 0), model)
	model.PrimaryPart = body
	animalPart("Head", Vector3.new(1.5, 1.5, 1.5), white, Vector3.new(0, 2.7, 2.0), model)
	animalPart("Snout", Vector3.new(1.0, 0.7, 0.5), Color3.fromRGB(200, 200, 200), Vector3.new(0, 2.5, 2.85), model)
	animalPart("Beard", Vector3.new(0.5, 0.8, 0.3), white, Vector3.new(0, 2.0, 2.8), model)
	for _, sx in ipairs({ -1, 1 }) do
		animalPart("Eye", Vector3.new(0.25, 0.25, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.45, 2.9, 2.72), model)
		local horn = animalPart("Horn", Vector3.new(0.3, 1.0, 0.3), Color3.fromRGB(240, 220, 180), Vector3.new(sx * 0.55, 3.6, 2.0), model)
		horn.CFrame = CFrame.new(horn.Position) * CFrame.Angles(0, 0, sx * -0.35)
		animalPart("Ear", Vector3.new(0.7, 0.4, 0.2), white, Vector3.new(sx * 0.9, 2.8, 2.0), model)
		animalCylinder("Leg", 0.4, 1.2, white, Vector3.new(sx * 0.7, 0.6, 1.1), model)
		animalCylinder("Leg", 0.4, 1.2, white, Vector3.new(sx * 0.7, 0.6, -1.1), model)
	end
	local tail = animalPart("Tail", Vector3.new(0.3, 0.6, 0.3), white, Vector3.new(0, 2.3, -1.8), model)
	tail.CFrame = CFrame.new(tail.Position) * CFrame.Angles(math.rad(-40), 0, 0)
	return model, 1.8
end

-- A butterfly: tiny body with two big colourful wings that flap. The
-- model origin is the body centre; the orbit loop PivotTos it over a
-- flower bed. Returns the model plus the wing flap data (attach point,
-- centre, side), like buildBird.
local function buildButterfly(color)
	local model = Instance.new("Model")
	model.Name = "Butterfly"
	local body = animalPart("Body", Vector3.new(0.3, 1.0, 0.3), Color3.fromRGB(40, 40, 40), Vector3.new(0, 0, 0), model)
	model.PrimaryPart = body
	for _, sx in ipairs({ -1, 1 }) do
		local antenna = animalPart("Antenna", Vector3.new(0.08, 0.7, 0.08), Color3.fromRGB(40, 40, 40), Vector3.new(sx * 0.15, 0.7, 0.2), model)
		antenna.CFrame = CFrame.new(antenna.Position) * CFrame.Angles(math.rad(20), 0, sx * -0.2)
	end
	local wings = {}
	for _, sx in ipairs({ -1, 1 }) do
		local wing = animalPart("Wing", Vector3.new(1.6, 0.1, 1.2), color, Vector3.new(sx * 0.95, 0.1, 0), model, Enum.Material.Fabric)
		table.insert(wings, {
			part = wing,
			attach = Vector3.new(sx * 0.15, 0.1, 0),
			centre = Vector3.new(sx * 0.95, 0.1, 0),
			side = sx,
		})
	end
	return model, wings
end

-- A little sailboat: wooden hull with a bow, benches, a mast, a white
-- sail and a red flag. The model origin is the hull centre (model Y
-- 0.75); the loop floats it on the water (water top Y 0.5), so the
-- pivot Y it returns is 1.25 above the water surface.
local function buildBoat()
	local model = Instance.new("Model")
	model.Name = "Boat"
	local hull = animalPart("Hull", Vector3.new(3, 1.5, 6), Color3.fromRGB(150, 100, 55), Vector3.new(0, 0.75, 0), model, Enum.Material.Wood)
	model.PrimaryPart = hull
	local bow = animalPart("Bow", Vector3.new(3, 1.2, 1.6), Color3.fromRGB(150, 100, 55), Vector3.new(0, 0.7, 3.2), model, Enum.Material.Wood)
	bow.CFrame = CFrame.new(bow.Position) * CFrame.Angles(math.rad(-30), 0, 0)
	animalPart("Bench", Vector3.new(2.6, 0.3, 0.8), Color3.fromRGB(120, 80, 40), Vector3.new(0, 1.6, -1), model, Enum.Material.Wood)
	animalPart("Bench", Vector3.new(2.6, 0.3, 0.8), Color3.fromRGB(120, 80, 40), Vector3.new(0, 1.6, 1), model, Enum.Material.Wood)
	animalCylinder("Mast", 0.3, 4.5, Color3.fromRGB(90, 60, 35), Vector3.new(0, 3.5, 0), model)
	animalPart("Sail", Vector3.new(0.2, 3.2, 2.4), Color3.fromRGB(255, 255, 255), Vector3.new(0, 3.6, -0.8), model, Enum.Material.Fabric)
	animalPart("MastFlag", Vector3.new(0.9, 0.6, 0.1), Color3.fromRGB(255, 90, 90), Vector3.new(0.6, 5.7, 0), model, Enum.Material.Fabric)
	return model, 1.25
end

-- v6: more live animals. Same contract as the v3.4 builders: return the
-- model (feet at model Y 0) plus the PrimaryPart's Y (pivotY), so the
-- wander loop can stand them on the sand and bob them. A few are hoppers
-- (rabbit, frog) — the loop reads an optional per-animal bob amplitude.
local function buildCat()
	local model = Instance.new("Model")
	model.Name = "Cat"
	local orange = Color3.fromRGB(230, 150, 70)
	local cream = Color3.fromRGB(250, 235, 210)
	local body = animalPart("Body", Vector3.new(1.8, 1.2, 2.6), orange, Vector3.new(0, 1.4, 0), model)
	model.PrimaryPart = body
	animalPart("Head", Vector3.new(1.4, 1.3, 1.4), orange, Vector3.new(0, 2.3, 1.5), model)
	for _, sx in ipairs({ -1, 1 }) do
		local ear = animalPart("Ear", Vector3.new(0.5, 0.7, 0.3), orange, Vector3.new(sx * 0.5, 3.1, 1.5), model)
		ear.CFrame = CFrame.new(ear.Position) * CFrame.Angles(0, 0, sx * -0.25)
		animalPart("Eye", Vector3.new(0.25, 0.3, 0.12), Color3.fromRGB(30, 180, 90), Vector3.new(sx * 0.35, 2.4, 2.22), model)
		animalCylinder("Leg", 0.35, 0.9, orange, Vector3.new(sx * 0.6, 0.45, 0.9), model)
		animalCylinder("Leg", 0.35, 0.9, orange, Vector3.new(sx * 0.6, 0.45, -0.9), model)
	end
	animalPart("Nose", Vector3.new(0.3, 0.2, 0.15), Color3.fromRGB(220, 120, 140), Vector3.new(0, 2.2, 2.22), model)
	animalPart("Chest", Vector3.new(1.2, 0.8, 0.2), cream, Vector3.new(0, 1.3, 1.32), model)
	local tail = animalPart("Tail", Vector3.new(0.3, 1.6, 0.3), orange, Vector3.new(0, 1.8, -1.5), model)
	tail.CFrame = CFrame.new(tail.Position) * CFrame.Angles(math.rad(-35), 0, 0)
	return model, 1.4
end

local function buildRabbit()
	local model = Instance.new("Model")
	model.Name = "Rabbit"
	local white = Color3.fromRGB(245, 245, 245)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(1.6, 1.6, 1.6)
	body.Color = white
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 1.2, 0)
	body.Parent = model
	model.PrimaryPart = body
	do
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(1.0, 1.0, 1.0)
		head.Color = white
		head.Anchored = true
		head.CanCollide = false
		head.Position = Vector3.new(0, 2.2, 0.6)
		head.Parent = model
	end
	for _, sx in ipairs({ -1, 1 }) do
		local ear = animalPart("Ear", Vector3.new(0.35, 1.4, 0.2), white, Vector3.new(sx * 0.3, 3.2, 0.6), model)
		ear.CFrame = CFrame.new(ear.Position) * CFrame.Angles(0, 0, sx * -0.12)
		animalPart("Eye", Vector3.new(0.2, 0.25, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.3, 2.3, 1.08), model)
		animalCylinder("Leg", 0.25, 0.8, white, Vector3.new(sx * 0.5, 0.4, 0.5), model)
	end
	animalPart("Nose", Vector3.new(0.25, 0.2, 0.15), Color3.fromRGB(255, 150, 180), Vector3.new(0, 2.1, 1.12), model)
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Shape = Enum.PartType.Ball
	tail.Size = Vector3.new(0.6, 0.6, 0.6)
	tail.Color = white
	tail.Anchored = true
	tail.CanCollide = false
	tail.Position = Vector3.new(0, 1.2, -0.9)
	tail.Parent = model
	return model, 1.2
end

local function buildFox()
	local model = Instance.new("Model")
	model.Name = "Fox"
	local orange = Color3.fromRGB(220, 110, 45)
	local cream = Color3.fromRGB(250, 240, 220)
	local body = animalPart("Body", Vector3.new(2.0, 1.4, 3.0), orange, Vector3.new(0, 1.6, 0), model)
	model.PrimaryPart = body
	animalPart("Head", Vector3.new(1.4, 1.4, 1.4), orange, Vector3.new(0, 2.5, 1.7), model)
	animalPart("Snout", Vector3.new(0.9, 0.6, 0.9), cream, Vector3.new(0, 2.3, 2.5), model)
	animalPart("Nose", Vector3.new(0.4, 0.3, 0.2), Color3.fromRGB(30, 30, 30), Vector3.new(0, 2.4, 2.95), model)
	for _, sx in ipairs({ -1, 1 }) do
		local ear = animalPart("Ear", Vector3.new(0.5, 0.9, 0.3), orange, Vector3.new(sx * 0.5, 3.4, 1.7), model)
		ear.CFrame = CFrame.new(ear.Position) * CFrame.Angles(0, 0, sx * -0.2)
		animalPart("Eye", Vector3.new(0.25, 0.3, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.4, 2.6, 2.42), model)
		animalCylinder("Leg", 0.4, 1.1, Color3.fromRGB(60, 40, 25), Vector3.new(sx * 0.65, 0.55, 1.0), model)
		animalCylinder("Leg", 0.4, 1.1, Color3.fromRGB(60, 40, 25), Vector3.new(sx * 0.65, 0.55, -1.0), model)
	end
	animalPart("Chest", Vector3.new(1.3, 0.9, 0.2), cream, Vector3.new(0, 1.5, 1.52), model)
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Shape = Enum.PartType.Ball
	tail.Size = Vector3.new(1.1, 1.1, 2.2)
	tail.Color = orange
	tail.Anchored = true
	tail.CanCollide = false
	tail.Position = Vector3.new(0, 1.6, -2.0)
	tail.Parent = model
	local tip = Instance.new("Part")
	tip.Name = "TailTip"
	tip.Shape = Enum.PartType.Ball
	tip.Size = Vector3.new(1.0, 1.0, 0.9)
	tip.Color = cream
	tip.Anchored = true
	tip.CanCollide = false
	tip.Position = Vector3.new(0, 1.6, -3.0)
	tip.Parent = model
	return model, 1.6
end

local function buildDeer()
	local model = Instance.new("Model")
	model.Name = "Deer"
	local brown = Color3.fromRGB(170, 120, 70)
	local cream = Color3.fromRGB(240, 225, 200)
	local body = animalPart("Body", Vector3.new(2.2, 1.8, 3.6), brown, Vector3.new(0, 2.2, 0), model)
	model.PrimaryPart = body
	local neck = animalPart("Neck", Vector3.new(1.2, 2.2, 1.2), brown, Vector3.new(0, 3.6, 1.8), model)
	neck.CFrame = CFrame.new(neck.Position) * CFrame.Angles(math.rad(-20), 0, 0)
	animalPart("Head", Vector3.new(1.3, 1.4, 2.0), brown, Vector3.new(0, 4.7, 2.5), model)
	animalPart("Snout", Vector3.new(0.9, 0.7, 0.7), cream, Vector3.new(0, 4.5, 3.5), model)
	for _, sx in ipairs({ -1, 1 }) do
		animalPart("Eye", Vector3.new(0.25, 0.3, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.45, 4.9, 3.45), model)
		animalPart("Ear", Vector3.new(0.35, 0.8, 0.3), brown, Vector3.new(sx * 0.6, 5.3, 2.4), model)
		-- Antlers: a vertical tine plus a forward branch.
		animalPart("Antler", Vector3.new(0.22, 1.6, 0.22), Color3.fromRGB(120, 90, 55), Vector3.new(sx * 0.4, 6.0, 2.3), model)
		local branch = animalPart("AntlerBranch", Vector3.new(0.18, 1.0, 0.18), Color3.fromRGB(120, 90, 55), Vector3.new(sx * 0.7, 6.1, 2.5), model)
		branch.CFrame = CFrame.new(branch.Position) * CFrame.Angles(0, 0, sx * -0.6)
		animalCylinder("Leg", 0.4, 1.9, brown, Vector3.new(sx * 0.7, 0.95, 1.3), model)
		animalCylinder("Leg", 0.4, 1.9, brown, Vector3.new(sx * 0.7, 0.95, -1.3), model)
		animalPart("Hoof", Vector3.new(0.45, 0.25, 0.45), Color3.fromRGB(50, 40, 30), Vector3.new(sx * 0.7, 0.12, 1.3), model)
		animalPart("Hoof", Vector3.new(0.45, 0.25, 0.45), Color3.fromRGB(50, 40, 30), Vector3.new(sx * 0.7, 0.12, -1.3), model)
	end
	animalPart("Belly", Vector3.new(1.6, 0.9, 2.6), cream, Vector3.new(0, 1.6, 0), model)
	animalPart("Tail", Vector3.new(0.4, 0.6, 0.4), cream, Vector3.new(0, 2.4, -1.9), model)
	return model, 2.2
end

local function buildFrog()
	local model = Instance.new("Model")
	model.Name = "Frog"
	local green = Color3.fromRGB(80, 200, 90)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(1.8, 1.2, 1.8)
	body.Color = green
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 0.9, 0)
	body.Parent = model
	model.PrimaryPart = body
	for _, sx in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.5, 0.5, 0.5)
		eye.Color = green
		eye.Anchored = true
		eye.CanCollide = false
		eye.Position = Vector3.new(sx * 0.45, 1.6, 0.5)
		eye.Parent = model
		animalPart("Pupil", Vector3.new(0.25, 0.25, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.45, 1.65, 0.75), model)
		animalCylinder("BackLeg", 0.4, 1.0, green, Vector3.new(sx * 0.7, 0.5, -0.4), model)
		animalCylinder("FrontLeg", 0.3, 0.7, green, Vector3.new(sx * 0.5, 0.35, 0.7), model)
	end
	animalPart("Belly", Vector3.new(1.2, 0.6, 1.2), Color3.fromRGB(220, 245, 190), Vector3.new(0, 0.6, 0.3), model)
	return model, 0.9
end

local function buildTurtle()
	local model = Instance.new("Model")
	model.Name = "Turtle"
	local shell = Color3.fromRGB(70, 130, 70)
	local skin = Color3.fromRGB(140, 180, 90)
	local body = Instance.new("Part")
	body.Name = "Shell"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.2, 1.4, 2.6)
	body.Color = shell
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 1.0, 0)
	body.Parent = model
	model.PrimaryPart = body
	animalPart("Head", Vector3.new(0.9, 0.8, 0.9), skin, Vector3.new(0, 1.3, 1.5), model)
	for _, sx in ipairs({ -1, 1 }) do
		animalPart("Eye", Vector3.new(0.2, 0.2, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.25, 1.45, 1.92), model)
		animalPart("Flipper", Vector3.new(0.7, 0.35, 1.0), skin, Vector3.new(sx * 1.1, 0.4, 0.9), model)
		animalPart("Flipper", Vector3.new(0.7, 0.35, 1.0), skin, Vector3.new(sx * 1.1, 0.4, -0.9), model)
	end
	animalPart("Tail", Vector3.new(0.25, 0.25, 0.6), skin, Vector3.new(0, 0.8, -1.4), model)
	return model, 1.0
end

local function buildCrab()
	local model = Instance.new("Model")
	model.Name = "Crab"
	local red = Color3.fromRGB(220, 90, 60)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.0, 0.9, 1.4)
	body.Color = red
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 0.7, 0)
	body.Parent = model
	model.PrimaryPart = body
	for _, sx in ipairs({ -1, 1 }) do
		local claw = Instance.new("Part")
		claw.Name = "Claw"
		claw.Shape = Enum.PartType.Ball
		claw.Size = Vector3.new(0.9, 0.9, 0.9)
		claw.Color = red
		claw.Anchored = true
		claw.CanCollide = false
		claw.Position = Vector3.new(sx * 1.3, 0.7, 0.7)
		claw.Parent = model
		local stalk = animalPart("EyeStalk", Vector3.new(0.15, 0.7, 0.15), red, Vector3.new(sx * 0.4, 1.3, 0.5), model)
		stalk.CFrame = CFrame.new(stalk.Position) * CFrame.Angles(0, 0, sx * -0.2)
		animalPart("Eye", Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.45, 1.65, 0.5), model)
		for _, lz in ipairs({ -0.4, 0, 0.4 }) do
			animalCylinder("Leg", 0.18, 0.9, red, Vector3.new(sx * 1.0, 0.45, lz), model)
		end
	end
	return model, 0.7
end

-- A fish that swims in the sea bands (and the park pond): flattened ball
-- body, tail fin that wiggles, dorsal fin, eyes. Returns the model, the
-- pivot Y (0 — body centre is the origin) and the tail flap data, in the
-- same shape as buildBird's wings, so the swim loop can wiggle it.
local function buildFish(color)
	local model = Instance.new("Model")
	model.Name = "Fish"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(1.1, 0.9, 2.2)
	body.Color = color
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 0, 0)
	body.Parent = model
	model.PrimaryPart = body
	local tail = animalPart("Tail", Vector3.new(0.15, 1.0, 0.9), color, Vector3.new(0, 0, -1.4), model)
	-- Low dorsal ridge (not a tall fin) so the fish can swim just under
	-- the surface without a fin sticking way out of the water.
	animalPart("Dorsal", Vector3.new(0.12, 0.35, 0.9), Color3.fromRGB(60, 90, 120), Vector3.new(0, 0.35, -0.2), model)
	for _, sx in ipairs({ -1, 1 }) do
		animalPart("Eye", Vector3.new(0.2, 0.2, 0.12), Color3.fromRGB(20, 20, 20), Vector3.new(sx * 0.3, 0.15, 0.95), model)
		animalPart("Fin", Vector3.new(0.12, 0.5, 0.7), color, Vector3.new(sx * 0.55, -0.2, 0.1), model)
	end
	return model, 0, {
		part = tail,
		attach = Vector3.new(0, 0, -1.0),
		centre = Vector3.new(0, 0, -1.4),
	}
end

function WorldBuilder.build()
	local world = Instance.new("Folder")
	world.Name = "World"
	world.Parent = Workspace

	-- Warm afternoon sun, Future lighting, a soft hazy sky.
	-- (Lighting.Technology is NOT written here: it needs the RobloxScript
	-- capability, which a game Script lacks, so writing it killed build()
	-- on its first Lighting line. Future is already baked into the place
	-- by default.project.json's Lighting properties.)
	-- v5: warm late-afternoon sun (ClockTime 14.5), warm ambient, peach haze,
	-- plus Bloom + SunRays + a whisper of ColorCorrection for a sunny glow.
	-- (Lighting.Technology stays in default.project.json only — never here.)
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(115, 95, 75)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 140, 120)
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(255, 225, 190)
	atmosphere.Decay = Color3.fromRGB(180, 160, 130)
	atmosphere.Glare = 0.5
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.25
	bloom.Size = 20
	bloom.Threshold = 0.95
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.12
	rays.Spread = 0.8
	rays.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Brightness = 0.02
	grade.Contrast = 0.05
	grade.Saturation = 0.08
	grade.TintColor = Color3.fromRGB(255, 245, 230)
	grade.Parent = Lighting

	-- v4 GROUND — the whole point of the rebuild. v3.6's beach was a
	-- single 460x400 plate, so 26-stud strips of grey studded baseplate
	-- showed on every side — and in the player's screenshot the ground
	-- read as grey baseplate everywhere. Here the ENTIRE 512x512 map is
	-- covered, in layers, all above the baseplate top (Y=0):
	--   1. sand: one 512x512 Sand plate, top Y=0.2, covers everything.
	--   2. grass: two town lawns (top Y=0.35) under the houses/shops.
	--   3. water: turquoise sea bands along the north/south shores
	--      (top Y=0.5), full width, where the pier and boats sit.
	-- Nothing grey can show: every (x, z) in [-256, 256]^2 is sand at
	-- worst. checkGroundCoverage() below PROVES it in code (a 32x32
	-- grid over the whole map; build() errors if any cell is bare).
	local groundTiles = {}
	local function groundTile(name, sizeX, sizeZ, cx, cz, topY, color, material, collide)
		local tile = part(name, Vector3.new(sizeX, topY * 2, sizeZ), color, Vector3.new(cx, 0, cz), world, material, collide)
		-- part() centres the part at (cx, 0, cz) with height topY*2, so
		-- its top is exactly topY; fix the centre Y the part() call set.
		tile.Position = Vector3.new(cx, topY - tile.Size.Y / 2, cz)
		table.insert(groundTiles, { x0 = cx - sizeX / 2, x1 = cx + sizeX / 2, z0 = cz - sizeZ / 2, z1 = cz + sizeZ / 2, top = topY })
		return tile
	end
	-- Sand and grass MUST collide (they are the floor players walk on);
	-- the sea must NOT collide (players wade to the shore, boats float).
	groundTile("Sand", 512, 512, 0, 0, 0.2, Color3.fromRGB(238, 214, 150), Enum.Material.Sand, true)
	groundTile("GrassWest", 160, 340, -150, 0, 0.35, Color3.fromRGB(125, 195, 95), Enum.Material.Grass, true)
	groundTile("GrassEast", 160, 340, 150, 0, 0.35, Color3.fromRGB(125, 195, 95), Enum.Material.Grass, true)
	groundTile("SeaNorth", 512, 51, 0, -230.5, 0.5, Color3.fromRGB(55, 185, 205), Enum.Material.SmoothPlastic, false)
	groundTile("SeaSouth", 512, 51, 0, 230.5, 0.5, Color3.fromRGB(55, 185, 205), Enum.Material.SmoothPlastic, false)
	-- Coverage proof: every cell of a 32x32 grid over the map must be
	-- inside at least one ground tile. (Sand alone covers all 1024
	-- cells; the check guards against a future edit shrinking it.)
	local function checkGroundCoverage()
		local covered, total = 0, 0
		for gx = 0, 31 do
			for gz = 0, 31 do
				local x = -256 + (gx + 0.5) * 16
				local z = -256 + (gz + 0.5) * 16
				total += 1
				for _, t in ipairs(groundTiles) do
					if x >= t.x0 and x <= t.x1 and z >= t.z0 and z <= t.z1 then
						covered += 1
						break
					end
				end
			end
		end
		print("v4 ground coverage: " .. covered .. "/" .. total .. " cells covered")
		assert(covered == total, "v4 ground coverage FAILED: " .. (total - covered) .. " bare cells — grey baseplate would show")
	end
	checkGroundCoverage()
	-- v5: shore foam where the sea meets the sand, sand dunes along the
	-- beach, grass tufts on the lawns, and stone paths — plaza to arch and
	-- from the conveyor to each base front — so the ground reads varied.
	for _, fz in ipairs({ -206.5, 206.5 }) do
		part("SeaFoam", Vector3.new(512, 0.15, 3), Color3.fromRGB(255, 250, 240), Vector3.new(0, 0.55, fz), world, Enum.Material.SmoothPlastic, false)
	end
	for _, spot in ipairs({
		Vector3.new(-180, 0, -195), Vector3.new(-60, 0, -195),
		Vector3.new(60, 0, -195), Vector3.new(180, 0, -195),
		Vector3.new(-180, 0, 195), Vector3.new(-60, 0, 195),
		Vector3.new(60, 0, 195), Vector3.new(180, 0, 195),
	}) do
		local dune = Instance.new("Part")
		dune.Name = "Dune"
		dune.Shape = Enum.PartType.Ball
		dune.Size = Vector3.new(10, 3, 7)
		dune.Color = Color3.fromRGB(228, 200, 135)
		dune.Material = Enum.Material.Sand
		dune.Anchored = true
		dune.CanCollide = false
		dune.Position = spot + Vector3.new(0, BEACH_TOP_Y + 0.8, 0)
		dune.Parent = world
	end
	for _, spot in ipairs({
		Vector3.new(-90, 0, -100), Vector3.new(90, 0, -100),
		Vector3.new(-90, 0, 100), Vector3.new(90, 0, 100),
		Vector3.new(-150, 0, -60), Vector3.new(150, 0, -60),
		Vector3.new(-150, 0, 60), Vector3.new(150, 0, 60),
	}) do
		for i = 1, 3 do
			local tuft = Instance.new("Part")
			tuft.Name = "GrassTuft"
			tuft.Shape = Enum.PartType.Ball
			tuft.Size = Vector3.new(1.2, 1.2, 1.2)
			tuft.Color = Color3.fromRGB(110, 190, 85)
			tuft.Anchored = true
			tuft.CanCollide = false
			tuft.Position = spot + Vector3.new((i - 2) * 1.1, BEACH_TOP_Y + 0.6, (i % 2) * 0.9)
			tuft.Parent = world
		end
	end
	for _, pz in ipairs({ -120, -60, 0, 60, 120 }) do
		for _, side in ipairs({ -1, 1 }) do
			part("StonePath", Vector3.new(5, 0.2, 5), Color3.fromRGB(215, 205, 185), Vector3.new(side * 16, BEACH_TOP_Y + 0.1, pz), world, Enum.Material.Slate, false)
		end
	end
	for _, px in ipairs({ -3, 3 }) do
		part("StonePath", Vector3.new(4, 0.15, 4), Color3.fromRGB(215, 205, 185), Vector3.new(px, BEACH_TOP_Y + 0.08, -152), world, Enum.Material.Slate, false)
	end

	-- Animated water shimmer: the two sea bands bob gently around their
	-- base height (absolute Y each tick — never accumulated, or the sea
	-- would drift away over minutes).
	local water = Instance.new("Folder")
	water.Name = "Water"
	water.Parent = world
	local waterParts = {}
	for _, sea in ipairs(world:GetChildren()) do
		if sea.Name == "SeaNorth" or sea.Name == "SeaSouth" then
			sea.Transparency = 0.25
			table.insert(waterParts, { part = sea, baseY = sea.Position.Y })
		end
	end
	task.spawn(function()
		local t = 0
		while world.Parent do
			t += 0.15
			for _, entry in ipairs(waterParts) do
				local sea = entry.part
				sea.Position = Vector3.new(sea.Position.X, entry.baseY + math.sin(t) * 0.1, sea.Position.Z)
			end
			task.wait(0.15)
		end
	end)

	-- The conveyor: a 300-stud runway down the middle, Z -145 to 155.
	local conveyor = Instance.new("Folder")
	conveyor.Name = "Conveyor"
	conveyor.Parent = world
	part("Strip", Vector3.new(14, 1, 300), Color3.fromRGB(122, 82, 52), Vector3.new(0, 0.5, 5), conveyor, Enum.Material.Wood)
	for _, side in ipairs({ -1, 1 }) do
		part("Rail", Vector3.new(0.6, 1.6, 300), Color3.fromRGB(255, 200, 60), Vector3.new(side * 7.2, 1.3, 5), conveyor, Enum.Material.Neon)
	end
	-- v5: boardwalk plank seams across the belt.
	for z = -140, 140, 20 do
		part("PlankSeam", Vector3.new(13.6, 0.12, 0.5), Color3.fromRGB(90, 60, 35), Vector3.new(0, 1.02, z), conveyor, Enum.Material.SmoothPlastic, false)
	end
	local chevrons = {}
	for z = -135, 145, 20 do
		local chevron = part("Chevron", Vector3.new(6, 0.2, 3), Color3.fromRGB(255, 220, 90), Vector3.new(0, 1.05, z), conveyor, Enum.Material.Neon, false)
		chevron.CFrame = CFrame.new(chevron.Position) * CFrame.Angles(0, math.rad(45), 0)
		table.insert(chevrons, chevron)
	end
	-- The belt scrolls: chevrons drift toward +Z and wrap back to the start.
	task.spawn(function()
		while world.Parent do
			task.wait(0.12)
			for _, chevron in ipairs(chevrons) do
				local z = chevron.Position.Z + 1.2
				if z > 150 then
					z = -140
				end
				chevron.CFrame = CFrame.new(0, 1.05, z) * CFrame.Angles(0, math.rad(45), 0)
			end
		end
	end)

	-- Welcome arch over the conveyor entrance, with the island's name.
	local arch = Instance.new("Folder")
	arch.Name = "Arch"
	arch.Parent = world
	for _, side in ipairs({ -1, 1 }) do
		part("ArchPost", Vector3.new(1.5, 13, 1.5), Color3.fromRGB(250, 235, 205), Vector3.new(side * 8, BEACH_TOP_Y + 6.5, -148), arch)
		part("ArchCap", Vector3.new(2.2, 0.8, 2.2), Color3.fromRGB(198, 102, 62), Vector3.new(side * 8, BEACH_TOP_Y + 13.4, -148), arch, Enum.Material.SmoothPlastic, false)
	end
	signBoard(arch, Vector3.new(0, BEACH_TOP_Y + 14, -148), "BRAINROT BAY", Color3.fromRGB(255, 220, 80), Vector3.new(16, 2.5, 0.6))
	-- v5: palms framing the arch — the first thing past the gatehouse.
	palmTree(world, Vector3.new(-14, 0, -148), 101)
	palmTree(world, Vector3.new(14, 0, -148), 102)

	-- Spawn plaza: checker tiles where newcomers first land.
	local plaza = Instance.new("Folder")
	plaza.Name = "Plaza"
	plaza.Parent = world
	for row = 0, 3 do
		for col = 0, 7 do
			local color = ((row + col) % 2 == 0) and Color3.fromRGB(255, 242, 214) or Color3.fromRGB(235, 175, 140)
			part("PlazaTile", Vector3.new(4.8, 0.2, 4.8), color, Vector3.new(-17.5 + col * 5, BEACH_TOP_Y + 0.1, -172 + row * 5), plaza, Enum.Material.SmoothPlastic, false)
		end
	end
	-- v5: plaza fountain — the centrepiece of the spawn view: stone basin,
	-- turquoise water, centre pedestal and spout.
	local fountain = Instance.new("Folder")
	fountain.Name = "Fountain"
	fountain.Parent = world
	local basin = Instance.new("Part")
	basin.Name = "FountainBasin"
	basin.Shape = Enum.PartType.Cylinder
	basin.Size = Vector3.new(1.4, 8.5, 8.5)
	basin.Color = Color3.fromRGB(200, 188, 165)
	basin.Material = Enum.Material.Slate
	basin.Anchored = true
	basin.CanCollide = true
	basin.CFrame = CFrame.new(Vector3.new(0, BEACH_TOP_Y + 0.7, -164.5))
	basin.Parent = fountain
	local fwater = Instance.new("Part")
	fwater.Name = "FountainWater"
	fwater.Shape = Enum.PartType.Cylinder
	fwater.Size = Vector3.new(0.7, 7, 7)
	fwater.Color = Color3.fromRGB(70, 200, 220)
	fwater.Transparency = 0.3
	fwater.Anchored = true
	fwater.CanCollide = false
	fwater.CFrame = CFrame.new(Vector3.new(0, BEACH_TOP_Y + 1.1, -164.5))
	fwater.Parent = fountain
	local pedestal = Instance.new("Part")
	pedestal.Name = "FountainPedestal"
	pedestal.Shape = Enum.PartType.Cylinder
	pedestal.Size = Vector3.new(2.6, 1.3, 1.3)
	pedestal.Color = Color3.fromRGB(200, 188, 165)
	pedestal.Material = Enum.Material.Slate
	pedestal.Anchored = true
	pedestal.CanCollide = true
	pedestal.CFrame = CFrame.new(Vector3.new(0, BEACH_TOP_Y + 2.7, -164.5))
	pedestal.Parent = fountain
	local bowl = Instance.new("Part")
	bowl.Name = "FountainBowl"
	bowl.Shape = Enum.PartType.Cylinder
	bowl.Size = Vector3.new(0.6, 3, 3)
	bowl.Color = Color3.fromRGB(200, 188, 165)
	bowl.Material = Enum.Material.Slate
	bowl.Anchored = true
	bowl.CanCollide = false
	bowl.CFrame = CFrame.new(Vector3.new(0, BEACH_TOP_Y + 4.2, -164.5))
	bowl.Parent = fountain
	local spout = Instance.new("Part")
	spout.Name = "FountainSpout"
	spout.Shape = Enum.PartType.Ball
	spout.Size = Vector3.new(0.9, 0.9, 0.9)
	spout.Color = Color3.fromRGB(120, 220, 240)
	spout.Transparency = 0.2
	spout.Anchored = true
	spout.CanCollide = false
	spout.Position = Vector3.new(0, BEACH_TOP_Y + 4.9, -164.5)
	spout.Parent = fountain
	-- v5: flower clusters at the plaza corners.
	for _, spot in ipairs({ Vector3.new(-13, 0, -170), Vector3.new(13, 0, -170), Vector3.new(-13, 0, -159), Vector3.new(13, 0, -159) }) do
		for i, fc in ipairs({ Color3.fromRGB(235, 120, 150), Color3.fromRGB(240, 200, 90), Color3.fromRGB(255, 255, 255) }) do
			local fl = Instance.new("Part")
			fl.Name = "PlazaFlower"
			fl.Shape = Enum.PartType.Ball
			fl.Size = Vector3.new(0.8, 0.8, 0.8)
			fl.Color = fc
			fl.Anchored = true
			fl.CanCollide = false
			fl.Position = spot + Vector3.new((i - 2) * 1.0, BEACH_TOP_Y + 0.5, (i % 2) * 0.8)
			fl.Parent = world
		end
	end
	-- v4: no WELCOME sign — the arch title above is the only greeting;
	-- a second big sign 30 studs behind it was half the spawn-view jumble.

	-- Ten bases: two rows of five flanking the conveyor.
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = world
	local bases = {}
	local index = 0
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs(BASE_Z) do
			index += 1
			-- v6: real raised platform — the deck top is now Y=2 (was 1),
			-- so the platform reads as a raised deck, not a thin slab.
			-- Everything on the base (pads, walls, sign, lock field) is
			-- positioned relative to `center`, so it all rises together;
			-- services read State.bases, so gameplay follows automatically.
			local center = Vector3.new(side * 48, 2, z)
			local color = BASE_COLORS[index]
			local baseFolder = Instance.new("Folder")
			baseFolder.Name = "Base" .. index
			baseFolder.Parent = basesFolder

			part("Platform", Vector3.new(30, 2, 30), color, center + Vector3.new(0, -1, 0), baseFolder)
			-- v5: warm cream trim framing the platform edge.
			for _, sx in ipairs({ -1, 1 }) do
				part("PlatformTrim", Vector3.new(1, 0.2, 30), Color3.fromRGB(250, 235, 205), center + Vector3.new(sx * 14.5, 0.05, 0), baseFolder, Enum.Material.SmoothPlastic, false)
			end
			for _, sz in ipairs({ -1, 1 }) do
				part("PlatformTrim", Vector3.new(30, 0.2, 1), Color3.fromRGB(250, 235, 205), center + Vector3.new(0, 0.05, sz * 14.5), baseFolder, Enum.Material.SmoothPlastic, false)
			end
			-- v6: stone foundation skirt at the deck foot + an entrance
			-- step on the conveyor-facing edge (conveyor top Y=1, deck
			-- top Y=2, so one step at Y=1.5 makes the climb two easy
			-- half-stud rises instead of one full-stud wall).
			part("PlatformSkirt", Vector3.new(31, 0.6, 31), Color3.fromRGB(140, 130, 115), center + Vector3.new(0, -1.7, 0), baseFolder, Enum.Material.Slate, false)
			part("BaseStep", Vector3.new(4, 1, 8), Color3.fromRGB(200, 188, 165), center + Vector3.new(side * -15, -1, 0), baseFolder, Enum.Material.Slate)
			part("BackWall", Vector3.new(1, 6, 30), Color3.fromRGB(80, 58, 42), center + Vector3.new(side * 14.5, 3, 0), baseFolder, Enum.Material.Wood)
			-- 18 slot pads (3 rows x 6): 12 unlocked at start, +2 per
			-- capacity level up to 20. Pads past the current cap are just
			-- decoration until an upgrade unlocks them.
			local slots = {}
			for _, rz in ipairs(SLOT_ROWS) do
				for _, cx in ipairs(SLOT_COLS) do
					local slotPos = center + Vector3.new(cx, 0.6, rz)
					part("SlotPad", Vector3.new(3.4, 0.2, 3.4), Color3.fromRGB(255, 242, 205), slotPos, baseFolder, Enum.Material.Neon, false)
					table.insert(slots, slotPos + Vector3.new(0, 0.1, 0))
				end
			end
			-- Green spawn pad on the conveyor-facing edge.
			local spawnPos = center + Vector3.new(side * -18, 1, 0)
			part("SpawnPad", Vector3.new(4, 0.2, 4), Color3.fromRGB(140, 230, 150), spawnPos, baseFolder, Enum.Material.Neon, false)
			local _, signLabel = signBoard(baseFolder, center + Vector3.new(0, 7.5, 0), "BASE " .. index, color, Vector3.new(6, 1.5, 0.4))
			-- Lock force-field: invisible until the base is locked.
			local lockField = part("LockField", Vector3.new(30, 8, 30), Color3.fromRGB(90, 160, 255), center + Vector3.new(0, 4, 0), baseFolder, Enum.Material.Neon, false)
			lockField.Transparency = 1

			table.insert(bases, {
				index = index,
				center = center,
				spawnPos = spawnPos,
				slots = slots,
				ownerUserId = nil,
				color = color,
				folder = baseFolder,
				signLabel = signLabel,
				lockField = lockField,
			})
		end
	end

	-- Decor: palms around the edges, stalls near the plaza, lamps and
	-- bunting along the conveyor so the bay reads as a night market.
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = world
	local treeSpots = {
		Vector3.new(-75, 0, -120), Vector3.new(75, 0, -120),
		Vector3.new(-75, 0, -60), Vector3.new(75, 0, -60),
		Vector3.new(-75, 0, 0), Vector3.new(75, 0, 0),
		Vector3.new(-75, 0, 60), Vector3.new(75, 0, 60),
		Vector3.new(-75, 0, 120), Vector3.new(75, 0, 120),
		Vector3.new(-30, 0, -165), Vector3.new(30, 0, -165),
		Vector3.new(-30, 0, 175), Vector3.new(30, 0, 175),
	}
	for i, spot in ipairs(treeSpots) do
		palmTree(decor, spot, i)
	end

	marketStall(decor, Vector3.new(-26, 0, -160), Color3.fromRGB(205, 110, 70), Color3.fromRGB(250, 235, 205), 1)
	marketStall(decor, Vector3.new(26, 0, -160), Color3.fromRGB(130, 165, 200), Color3.fromRGB(250, 235, 205), 2)
	marketStall(decor, Vector3.new(-26, 0, 172), Color3.fromRGB(230, 185, 95), Color3.fromRGB(250, 235, 205), 3)
	marketStall(decor, Vector3.new(26, 0, 172), Color3.fromRGB(140, 185, 120), Color3.fromRGB(250, 235, 205), 4)
	-- v3.5: two more stalls mid-map (X ±26, Z 0 — 3 studs clear of the
	-- base platforms at X 33, clear of the fences, houses and lamps).
	marketStall(decor, Vector3.new(-26, 0, 0), Color3.fromRGB(215, 140, 155), Color3.fromRGB(250, 235, 205), 5)
	marketStall(decor, Vector3.new(26, 0, 0), Color3.fromRGB(110, 180, 170), Color3.fromRGB(250, 235, 205), 6)

	for _, z in ipairs({ -100, -40, 20, 80, 140 }) do
		for _, side in ipairs({ -1, 1 }) do
			part("LampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(70, 55, 40), Vector3.new(side * 10, BEACH_TOP_Y + 3.5, z), decor)
			part("LampHead", Vector3.new(1.6, 1, 1.6), Color3.fromRGB(255, 240, 160), Vector3.new(side * 10, BEACH_TOP_Y + 7.4, z), decor, Enum.Material.Neon, false)
		end
	end
	-- Bunting: little coloured flags strung between the lamp tops.
	local flagColors = {
		-- v5: muted warm bunting — terracotta, gold, sage, dusty blue, cream.
		Color3.fromRGB(205, 110, 70), Color3.fromRGB(230, 185, 95),
		Color3.fromRGB(140, 185, 120), Color3.fromRGB(130, 165, 200),
		Color3.fromRGB(250, 235, 205),
	}
	for _, side in ipairs({ -1, 1 }) do
		for i = 1, 4 do
			local zA = ({ -100, -40, 20, 80 })[i]
			local zB = ({ -40, 20, 80, 140 })[i]
			for f = 1, 5 do
				local z = zA + (zB - zA) * (f / 6)
				local flag = part("Flag", Vector3.new(1.4, 1.6, 0.15), flagColors[(f % #flagColors) + 1], Vector3.new(side * 10, 6.6, z), decor, Enum.Material.Fabric, false)
				flag.CFrame = CFrame.new(flag.Position) * CFrame.Angles(math.rad(20), 0, 0)
			end
		end
	end

	-- v3.1 town: barns, shops and houses with pitched roofs, a gatehouse,
	-- fences, trees and props — the bay reads as a busy little town now.
	local buildings = Instance.new("Folder")
	buildings.Name = "Buildings"
	buildings.Parent = world
	-- Town centre by the spawn plaza: a barn and a shop facing the plaza.
	barn(buildings, Vector3.new(-45, 0, -178), Color3.fromRGB(185, 75, 60), Color3.fromRGB(120, 80, 50), 1)
	shop(buildings, Vector3.new(45, 0, -178), Color3.fromRGB(250, 225, 170), Color3.fromRGB(198, 102, 62), 1)
	-- Houses flanking the conveyor, fronts facing the conveyor. At HS 2.5
	-- they sit at X ±27 so the shallower porches stop a stud short of the
	-- fences at X ±9; their Z span stays inside the gap between base rows.
	house(buildings, Vector3.new(-27, 0, -30), Color3.fromRGB(250, 235, 205), Color3.fromRGB(198, 102, 62), 1, 1)
	house(buildings, Vector3.new(27, 0, -30), Color3.fromRGB(200, 220, 180), Color3.fromRGB(175, 80, 55), -1, 2)
	house(buildings, Vector3.new(-27, 0, 30), Color3.fromRGB(185, 210, 225), Color3.fromRGB(150, 100, 60), 1, 3)
	house(buildings, Vector3.new(27, 0, 30), Color3.fromRGB(250, 225, 170), Color3.fromRGB(95, 145, 135), -1, 4)
	-- Smaller huts further down the conveyor.
	hut(buildings, Vector3.new(-20, 0, -90), Color3.fromRGB(250, 210, 180), Color3.fromRGB(150, 100, 60), 1, 1)
	hut(buildings, Vector3.new(20, 0, 90), Color3.fromRGB(200, 220, 180), Color3.fromRGB(198, 102, 62), -1, 2)
	-- v3.5: the town is denser still — two more two-storey houses by the
	-- plaza's north end, two more shops and two more huts down the sides,
	-- so the bay reads as a busy town. New houses at X ±85, Z -170 (their
	-- X span -97.5..-72.5 clears the barn at -57.6..-32.4 and the tall
	-- tree at -110); new shops at X ±80, Z -150 (fronts face +Z, toward
	-- the town; X span 70.1..89.9 clears the tall tree at ±110 and the
	-- palms at ±75, Z -120); new huts at X ±80, Z 150 (X span 72.8..87.2
	-- clears the tall tree at ±110, the palms at ±75, Z 120, and the
	-- stalls at ±26, Z 172). All clear of the conveyor, fences, bases
	-- and the existing buildings.
	house(buildings, Vector3.new(-85, 0, -170), Color3.fromRGB(250, 235, 205), Color3.fromRGB(198, 102, 62), 1, 5)
	house(buildings, Vector3.new(85, 0, -170), Color3.fromRGB(250, 210, 180), Color3.fromRGB(165, 70, 55), -1, 6)
	shop(buildings, Vector3.new(-80, 0, -150), Color3.fromRGB(185, 210, 225), Color3.fromRGB(95, 145, 135), 2, "FISH SHOP")
	shop(buildings, Vector3.new(80, 0, -150), Color3.fromRGB(250, 235, 205), Color3.fromRGB(198, 102, 62), 3, "SNACK SHOP")
	hut(buildings, Vector3.new(-80, 0, 150), Color3.fromRGB(200, 220, 180), Color3.fromRGB(150, 100, 60), 1, 3)
	hut(buildings, Vector3.new(80, 0, 150), Color3.fromRGB(250, 225, 170), Color3.fromRGB(175, 80, 55), -1, 4)
	-- Gatehouse over the plaza walkway.
	gatehouse(buildings, Vector3.new(0, 0, -160))

	-- Wooden fences along both sides of the conveyor, with gaps at each
	-- base front so players can walk from the conveyor to their base.
	local fences = Instance.new("Folder")
	fences.Name = "Fences"
	fences.Parent = world
	local fenceIndex = 0
	for _, side in ipairs({ -1, 1 }) do
		for _, seg in ipairs({ { -105, -75 }, { -45, -15 }, { 15, 45 }, { 75, 105 } }) do
			fenceIndex += 1
			fenceRun(fences, side * 9, seg[1], seg[2], fenceIndex)
		end
	end

	-- Greenery: round trees and bushes scattered in the free ground.
	local greenery = Instance.new("Folder")
	greenery.Name = "Greenery"
	greenery.Parent = world
	for i, spot in ipairs({
		Vector3.new(-70, 0, -90), Vector3.new(70, 0, -90),
		Vector3.new(-70, 0, -30), Vector3.new(70, 0, -30),
		Vector3.new(-70, 0, 30), Vector3.new(70, 0, 30),
		-- v5: two layered trees framing the plaza's north side.
		Vector3.new(-55, 0, -140), Vector3.new(55, 0, -140),
	}) do
		roundTree(greenery, spot, i)
	end
	for _, spot in ipairs({
		Vector3.new(14, 0, -110), Vector3.new(-14, 0, 50),
		Vector3.new(14, 0, 10), Vector3.new(-14, 0, -10),
		Vector3.new(26, 0, -75), Vector3.new(-26, 0, 75),
		Vector3.new(26, 0, 140), Vector3.new(-26, 0, -140),
	}) do
		local bush = Instance.new("Part")
		bush.Name = "Bush"
		bush.Shape = Enum.PartType.Ball
		bush.Size = Vector3.new(3, 3, 3)
		bush.Color = Color3.fromRGB(60, 200, 90)
		bush.Anchored = true
		bush.CanCollide = false
		bush.Position = spot + Vector3.new(0, BEACH_TOP_Y + 1.5, 0)
		bush.Parent = greenery
	end

	-- Props: crates, barrels, hay bales, goods on the stall counters,
	-- lamps by the plaza and big readable signs on posts.
	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = world
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(-24, BEACH_TOP_Y + 1.25, -156), props, Enum.Material.Wood)
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(-24, BEACH_TOP_Y + 3.75, -156), props, Enum.Material.Wood)
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(24, BEACH_TOP_Y + 1.25, 170), props, Enum.Material.Wood)
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(24, BEACH_TOP_Y + 3.75, 170), props, Enum.Material.Wood)
	-- Props moved out of the barn/shop footprints when the buildings grew
	-- to BS 1.8 (barn spans X -57.6..-32.4, shop X 35.1..54.9, Z -187..-169).
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(-62, BEACH_TOP_Y + 1.25, -156), props, Enum.Material.Wood)
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(62, BEACH_TOP_Y + 1.25, -156), props, Enum.Material.Wood)
	for _, spot in ipairs({ Vector3.new(24, 0, -156), Vector3.new(-24, 0, 168), Vector3.new(-60, 0, -160), Vector3.new(60, 0, -160) }) do
		local barrel = Instance.new("Part")
		barrel.Name = "Barrel"
		barrel.Shape = Enum.PartType.Cylinder
		barrel.Size = Vector3.new(2.5, 2, 2)
		barrel.Color = Color3.fromRGB(120, 80, 40)
		barrel.Anchored = true
		barrel.CanCollide = true
		barrel.CFrame = CFrame.new(spot + Vector3.new(0, BEACH_TOP_Y + 1.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
		barrel.Parent = props
	end
	for _, spot in ipairs({ Vector3.new(-63, 0, -186), Vector3.new(-60, 0, -186), Vector3.new(60, 0, -186), Vector3.new(63, 0, -186) }) do
		local bale = Instance.new("Part")
		bale.Name = "HayBale"
		bale.Shape = Enum.PartType.Cylinder
		bale.Size = Vector3.new(3, 2.2, 2.2)
		bale.Color = Color3.fromRGB(230, 200, 80)
		bale.Anchored = true
		bale.CanCollide = true
		bale.Position = spot + Vector3.new(0, BEACH_TOP_Y + 1.1, 0)
		bale.Parent = props
	end
	-- v5: stall goods now live inside marketStall() (fruit + bread per stall).
	for _, spot in ipairs({ Vector3.new(-14, 0, -168), Vector3.new(14, 0, -168) }) do
		part("LampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(70, 55, 40), spot + Vector3.new(0, BEACH_TOP_Y + 3.5, 0), props)
		part("LampHead", Vector3.new(1.6, 1, 1.6), Color3.fromRGB(255, 240, 160), spot + Vector3.new(0, BEACH_TOP_Y + 7.4, 0), props, Enum.Material.Neon, false)
	end
	-- v4: the two free-standing MARKET / FRESH BRAINROTS sign posts are
	-- GONE — they stood in the middle of the spawn sightline and their
	-- AlwaysOnTop boards were the centre of the v3.6 jumble.

	-- v3.4: tall swaying trees at the map edges, clear of the conveyor,
	-- bases, buildings and spawn pads (the water bands hug Z ±173..243 and
	-- Z -233..-163, so the trees stay inside Z ±150).
	local tallTrees = {}
	local tallTreeSpots = {
		Vector3.new(-110, 0, -150), Vector3.new(110, 0, -150),
		Vector3.new(-110, 0, 150), Vector3.new(110, 0, 150),
		Vector3.new(-150, 0, 0), Vector3.new(150, 0, 0),
	}
	local treesFolder = Instance.new("Folder")
	treesFolder.Name = "TallTrees"
	treesFolder.Parent = world
	for i, spot in ipairs(tallTreeSpots) do
		table.insert(tallTrees, tallTree(treesFolder, spot, i))
	end

	-- v3.4: ambient animals, purely decorative — no prompt, no gameplay.
	-- v3.5: they are BIG now (2x, ScaleTo around the PrimaryPart, so the
	-- feet drop to -2*pivotY below the pivot and the loop's Y uses the
	-- doubled pivotY). Ground animals wander a small patch of open beach;
	-- two birds orbit high above the map. All clear of the conveyor and
	-- the bases.
	local animalsFolder = Instance.new("Folder")
	animalsFolder.Name = "Animals"
	animalsFolder.Parent = world
	local wanderers = {}
	for _, spec in ipairs({
		{ buildCow, Vector3.new(45, 0, 145), 6, 0.12, 0 },
		{ buildPig, Vector3.new(-45, 0, 145), 6, 0.12, 2.1 },
		{ buildChicken, Vector3.new(55, 0, -145), 6, 0.16, 4.2 },
	}) do
		local model, pivotY = spec[1]()
		model:ScaleTo(2)
		pivotY = pivotY * 2
		model.Parent = animalsFolder
		table.insert(wanderers, {
			model = model,
			home = spec[2],
			radius = spec[3],
			speed = spec[4],
			phase = spec[5],
			pivotY = pivotY,
		})
	end
	local orbiters = {}
	for _, spec in ipairs({
		{ Color3.fromRGB(90, 160, 255), 0 },
		{ Color3.fromRGB(245, 245, 245), math.pi },
	}) do
		local model, wings = buildBird(spec[1])
		model:ScaleTo(2)
		-- The loop overwrites the wing CFrames every tick from attach /
		-- centre, so those must be doubled too (ScaleTo already scaled
		-- the wing parts themselves).
		for _, wing in ipairs(wings) do
			wing.attach = wing.attach * 2
			wing.centre = wing.centre * 2
		end
		model.Parent = animalsFolder
		table.insert(orbiters, {
			model = model,
			wings = wings,
			centre = Vector3.new(0, 55, 5),
			radius = 90,
			speed = 0.15,
			phase = spec[2],
		})
	end

	-- v3.6: five more big animals (dog, horse, duck, sheep, goat) — same
	-- wander pattern as the v3.4 animals, 2x like the v3.5 ones. The
	-- horse's circle is tighter (r4) so its long body clears the shop at
	-- (80, -150) and the tall tree at (110, -150); the sheep's circle is
	-- r4 at (140, 166) so it stays off the pier and out of the water.
	for _, spec in ipairs({
		{ buildDog, Vector3.new(-100, 0, -135), 5, 0.16, 0.7 },
		{ buildHorse, Vector3.new(105, 0, -135), 4, 0.10, 1.9 },
		{ buildDuck, Vector3.new(-120, 0, 165), 5, 0.18, 3.1 },
		{ buildSheep, Vector3.new(140, 0, 166), 4, 0.10, 4.4 },
		{ buildGoat, Vector3.new(-140, 0, -100), 5, 0.14, 5.6 },
	}) do
		local model, pivotY = spec[1]()
		model:ScaleTo(2)
		pivotY = pivotY * 2
		model.Parent = animalsFolder
		table.insert(wanderers, {
			model = model,
			home = spec[2],
			radius = spec[3],
			speed = spec[4],
			phase = spec[5],
			pivotY = pivotY,
		})
	end

	-- v3.6: three butterflies over the flower beds below.
	local butterflies = {}
	for _, spec in ipairs({
		{ Color3.fromRGB(255, 140, 40), Vector3.new(-40, 5.5, -140), 6, 0.5, 0 },
		{ Color3.fromRGB(255, 90, 200), Vector3.new(40, 5.5, 165), 6, 0.5, 2.1 },
		{ Color3.fromRGB(200, 120, 255), Vector3.new(-40, 5.5, 165), 6, 0.5, 4.2 },
	}) do
		local model, wings = buildButterfly(spec[1])
		model.Parent = animalsFolder
		table.insert(butterflies, {
			model = model,
			wings = wings,
			centre = spec[2],
			radius = spec[3],
			speed = spec[4],
			phase = spec[5],
		})
	end

	-- v3.6: as busy as possible — a second market row on each outer band.
	-- East side: three stalls, a taco shop and a hut at X 110 (clear of
	-- the palms at X 75, the tall trees at X 110/Z ±150 and the bases at
	-- X ≤ 63). West side: two more two-storey houses and two stalls at
	-- X -110 (houses at Z ±60, stalls at Z ±40 — clear of each other,
	-- the palms and the tall trees). Two more stalls by the south water
	-- at (±55, 165), clear of the huts at (±80, 150) and the palms at
	-- (±30, 175). Goods on every new stall counter.
	local town2 = Instance.new("Folder")
	town2.Name = "Town2"
	town2.Parent = world
	house(town2, Vector3.new(-110, 0, -60), Color3.fromRGB(200, 220, 180), Color3.fromRGB(198, 102, 62), 1, 7)
	house(town2, Vector3.new(-110, 0, 60), Color3.fromRGB(185, 210, 225), Color3.fromRGB(150, 100, 60), 1, 8)
	marketStall(town2, Vector3.new(110, 0, -40), Color3.fromRGB(205, 110, 70), Color3.fromRGB(250, 235, 205), 10)
	marketStall(town2, Vector3.new(110, 0, 0), Color3.fromRGB(140, 185, 120), Color3.fromRGB(250, 235, 205), 11)
	marketStall(town2, Vector3.new(110, 0, 40), Color3.fromRGB(215, 140, 155), Color3.fromRGB(250, 235, 205), 12)
	shop(town2, Vector3.new(110, 0, -80), Color3.fromRGB(250, 210, 180), Color3.fromRGB(198, 102, 62), 5, "TACO STAND")
	hut(town2, Vector3.new(110, 0, 80), Color3.fromRGB(250, 235, 205), Color3.fromRGB(175, 80, 55), -1, 6)
	marketStall(town2, Vector3.new(-110, 0, -40), Color3.fromRGB(130, 165, 200), Color3.fromRGB(250, 235, 205), 13)
	marketStall(town2, Vector3.new(-110, 0, 40), Color3.fromRGB(230, 185, 95), Color3.fromRGB(250, 235, 205), 14)
	marketStall(town2, Vector3.new(-55, 0, 165), Color3.fromRGB(215, 140, 155), Color3.fromRGB(250, 235, 205), 15)
	marketStall(town2, Vector3.new(55, 0, 165), Color3.fromRGB(110, 180, 170), Color3.fromRGB(250, 235, 205), 16)

	-- v3.6 landmark: a lighthouse on the north-east shore at (200, -155)
	-- — on the beach just south of the north water band (Z -163..), clear
	-- of the house at (85, -170). White tower with red stripes, a glass
	-- lamp room with a glowing bulb, a red dome, and two rotating beams.
	-- v6: rebuilt as a TAPERED BOX tower — plain Positions, no cylinder
	-- rotations at all, so the tower stands perfectly straight up (the
	-- old cylinder tower read as leaning ~30 degrees in the live game).
	-- Stacked boxes narrow toward the top, like a real lighthouse.
	local lhBase = Vector3.new(200, BEACH_TOP_Y, -155)
	part("LighthouseBase", Vector3.new(14, 2, 14), Color3.fromRGB(120, 120, 130), lhBase + Vector3.new(0, 1, 0), world, Enum.Material.Cobblestone)
	-- Tower sections: (size, centre-Y above lhBase, colour). Each box is
	-- placed by plain Position — no CFrame rotation, so no lean is possible.
	for _, sec in ipairs({
		{ Vector3.new(9, 12, 9), 8.2, Color3.fromRGB(255, 255, 255) },
		{ Vector3.new(8.4, 4, 8.4), 16.2, Color3.fromRGB(220, 60, 60) },
		{ Vector3.new(7.8, 10, 7.8), 23.2, Color3.fromRGB(255, 255, 255) },
		{ Vector3.new(7.2, 4, 7.2), 30.2, Color3.fromRGB(220, 60, 60) },
	}) do
		part("LighthouseTower", sec[1], sec[3], lhBase + Vector3.new(0, sec[2], 0), world, Enum.Material.SmoothPlastic)
	end
	-- Door at the tower foot (faces the town, -X) + small windows up the
	-- white sections so the tower reads as a real building, not a pole.
	part("LighthouseDoor", Vector3.new(0.4, 5, 2.4), Color3.fromRGB(90, 60, 35), lhBase + Vector3.new(-4.6, 4.5, 0), world, Enum.Material.Wood)
	for _, wy in ipairs({ 11, 20, 26 }) do
		part("LighthouseWindow", Vector3.new(0.3, 1.6, 1.6), Color3.fromRGB(150, 210, 255), lhBase + Vector3.new(-4.3, wy, 0), world, Enum.Material.Glass, false)
	end
	part("LighthouseGallery", Vector3.new(10, 1, 10), Color3.fromRGB(60, 60, 70), lhBase + Vector3.new(0, 32.7, 0), world)
	-- Glass lamp room as a plain box (no cylinder rotation), glowing bulb,
	-- and a red dome cap — all plain Positions, all straight up.
	part("LampRoom", Vector3.new(6, 5, 6), Color3.fromRGB(180, 220, 255), lhBase + Vector3.new(0, 35.7, 0), world, Enum.Material.Glass, false)
	local lampBulb = Instance.new("Part")
	lampBulb.Name = "LampBulb"
	lampBulb.Shape = Enum.PartType.Ball
	lampBulb.Size = Vector3.new(3.5, 3.5, 3.5)
	lampBulb.Material = Enum.Material.Neon
	lampBulb.Color = Color3.fromRGB(255, 240, 160)
	lampBulb.Anchored = true
	lampBulb.CanCollide = false
	lampBulb.Position = lhBase + Vector3.new(0, 35.7, 0)
	lampBulb.Parent = world
	local dome = Instance.new("Part")
	dome.Name = "LighthouseDome"
	dome.Shape = Enum.PartType.Ball
	dome.Size = Vector3.new(7, 4, 7)
	dome.Color = Color3.fromRGB(220, 60, 60)
	dome.Anchored = true
	dome.CanCollide = false
	dome.Position = lhBase + Vector3.new(0, 39.7, 0)
	dome.Parent = world
	-- Two rotating light beams, spun by the animation loop below.
	local beamPivot = lhBase + Vector3.new(0, 35.7, 0)
	local beams = {}
	for _, dir in ipairs({ 1, -1 }) do
		local beam = part("LightBeam", Vector3.new(26, 1, 1), Color3.fromRGB(255, 240, 160), beamPivot + Vector3.new(dir * 13, 0, 0), world, Enum.Material.Neon, false)
		beam.Transparency = 0.45
		table.insert(beams, { part = beam, pivot = beamPivot, dir = dir })
	end

	-- v3.6: a wooden pier reaching into the south water at X 120, from
	-- the beach (Z 168) out to Z 215 — clear of the hut at (80, 150),
	-- the tall tree at (110, 150) and the sheep's patch at (140, 166).
	-- Planks, posts and side rails, plus two sailboats bobbing nearby.
	local pier = Instance.new("Folder")
	pier.Name = "Pier"
	pier.Parent = world
	for z = 169, 214, 3 do
		part("PierPlank", Vector3.new(6, 0.4, 2.6), Color3.fromRGB(150, 100, 55), Vector3.new(120, 1.0, z), pier, Enum.Material.Wood)
	end
	for _, px in ipairs({ 117.5, 122.5 }) do
		for z = 170, 214, 8 do
			part("PierPost", Vector3.new(0.6, 3, 0.6), Color3.fromRGB(90, 60, 35), Vector3.new(px, 0, z), pier, Enum.Material.Wood)
		end
		part("PierRail", Vector3.new(0.3, 0.3, 46), Color3.fromRGB(150, 100, 55), Vector3.new(px, 2.2, 191.5), pier, Enum.Material.Wood, false)
	end
	local boats = {}
	for _, spec in ipairs({
		{ Vector3.new(120, 0, 220), 0, 0 },
		{ Vector3.new(-150, 0, -210), math.rad(35), 2.3 },
	}) do
		local model, pivotY = buildBoat()
		model.Parent = world
		table.insert(boats, {
			model = model,
			home = spec[1],
			heading = spec[2],
			phase = spec[3],
			pivotY = pivotY,
		})
	end

	-- v3.6 decor: benches, flower beds, extra lamps, waving flag poles
	-- and two more big readable signs.
	local decor2 = Instance.new("Folder")
	decor2.Name = "Decor2"
	decor2.Parent = world
	for _, spot in ipairs({ Vector3.new(-20, 0, -140), Vector3.new(20, 0, -140), Vector3.new(-20, 0, 165), Vector3.new(20, 0, 165) }) do
		part("BenchSeat", Vector3.new(4, 0.5, 1.5), Color3.fromRGB(150, 100, 55), spot + Vector3.new(0, BEACH_TOP_Y + 1.2, 0), decor2, Enum.Material.Wood)
		part("BenchBack", Vector3.new(4, 1.5, 0.3), Color3.fromRGB(150, 100, 55), spot + Vector3.new(0, BEACH_TOP_Y + 2, -0.7), decor2, Enum.Material.Wood)
		for _, sx in ipairs({ -1, 1 }) do
			part("BenchLeg", Vector3.new(0.4, 1.2, 1.2), Color3.fromRGB(90, 60, 35), spot + Vector3.new(sx * 1.7, BEACH_TOP_Y + 0.6, 0), decor2, Enum.Material.Wood)
		end
	end
	local flowerColors = {
		Color3.fromRGB(235, 120, 150), Color3.fromRGB(235, 200, 100),
		Color3.fromRGB(190, 150, 215), Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(240, 140, 80),
	}
	for bi, spot in ipairs({ Vector3.new(-40, 0, -140), Vector3.new(40, 0, -140), Vector3.new(-40, 0, 165), Vector3.new(40, 0, 165) }) do
		local soil = Instance.new("Part")
		soil.Name = "FlowerBed"
		soil.Shape = Enum.PartType.Cylinder
		soil.Size = Vector3.new(0.8, 6, 6)
		soil.Color = Color3.fromRGB(90, 60, 35)
		soil.Anchored = true
		soil.CanCollide = false
		soil.CFrame = CFrame.new(spot + Vector3.new(0, BEACH_TOP_Y + 0.4, 0))
		soil.Parent = decor2
		for fi = 1, 5 do
			local a = (fi / 5) * math.pi * 2 + bi
			local flower = Instance.new("Part")
			flower.Name = "Flower"
			flower.Shape = Enum.PartType.Ball
			flower.Size = Vector3.new(0.9, 0.9, 0.9)
			flower.Color = flowerColors[((fi + bi) % #flowerColors) + 1]
			flower.Anchored = true
			flower.CanCollide = false
			flower.Position = spot + Vector3.new(math.cos(a) * 1.8, BEACH_TOP_Y + 1.1, math.sin(a) * 1.8)
			flower.Parent = decor2
		end
	end
	for _, spot in ipairs({ Vector3.new(-100, 0, -100), Vector3.new(100, 0, -100), Vector3.new(-100, 0, 0), Vector3.new(100, 0, 0), Vector3.new(-100, 0, 100), Vector3.new(100, 0, 100) }) do
		part("LampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(70, 55, 40), spot + Vector3.new(0, BEACH_TOP_Y + 3.5, 0), decor2)
		part("LampHead", Vector3.new(1.6, 1, 1.6), Color3.fromRGB(255, 240, 160), spot + Vector3.new(0, BEACH_TOP_Y + 7.4, 0), decor2, Enum.Material.Neon, false)
	end
	local waveFlags = {}
	for fi, spot in ipairs({ Vector3.new(-70, 0, -165), Vector3.new(70, 0, -165), Vector3.new(-70, 0, 175), Vector3.new(70, 0, 175) }) do
		local pole = Instance.new("Part")
		pole.Name = "FlagPole"
		pole.Shape = Enum.PartType.Cylinder
		pole.Size = Vector3.new(12, 0.5, 0.5)
		pole.Color = Color3.fromRGB(90, 90, 100)
		pole.Anchored = true
		pole.CanCollide = true
		pole.CFrame = CFrame.new(spot + Vector3.new(0, BEACH_TOP_Y + 6, 0)) * CFrame.Angles(0, 0, math.rad(90))
		pole.Parent = decor2
		local flag = part("Flag", Vector3.new(3, 2, 0.15), flagColors[((fi - 1) % #flagColors) + 1], spot + Vector3.new(1.6, BEACH_TOP_Y + 11, 0), decor2, Enum.Material.Fabric, false)
		table.insert(waveFlags, { part = flag, base = flag.CFrame, phase = fi * 1.7 })
	end
	-- v4: the SOUTH MARKET / LIGHTHOUSE POINT free-standing signs are
	-- GONE too — same reason: big AlwaysOnTop boards in the sightline.

	-- v6: FILL THE MAP — dense real-world districts. The v5 world had
	-- the town, conveyor and bases clustered in the middle-back and most
	-- of the 512x512 map was empty brown ground. These districts spread
	-- buildings, trees, props, paths and animals across the WHOLE map so
	-- no big empty area remains: east residential, west farm, south beach
	-- resort, north promenade, and three forest groves. Every placement
	-- uses BEACH_TOP_Y as its ground reference (no more sunk props) and
	-- stays clear of the conveyor, the bases, the town and the water.
	local districts = Instance.new("Folder")
	districts.Name = "Districts"
	districts.Parent = world

	-- v6 structure helpers, local to this section.
	local function cropField(parent, center, rows, cols, cropColor, fruitColor)
		-- A tilled soil bed with rows of crop plants and fruit.
		part("CropSoil", Vector3.new(cols * 2.5 + 2, 0.6, rows * 3 + 2), Color3.fromRGB(95, 65, 40), center + Vector3.new(0, BEACH_TOP_Y + 0.3, 0), parent, Enum.Material.Ground)
		for r = 1, rows do
			local rz = center.Z - (rows - 1) * 1.5 + (r - 1) * 3
			for c = 1, cols do
				local cx = center.X - (cols - 1) * 1.25 + (c - 1) * 2.5
				part("CropPlant", Vector3.new(0.8, 1.6, 0.8), cropColor, Vector3.new(cx, BEACH_TOP_Y + 1.4, rz), parent, Enum.Material.Grass, false)
				part("CropFruit", Vector3.new(0.5, 0.5, 0.5), fruitColor, Vector3.new(cx, BEACH_TOP_Y + 2.2, rz), parent, Enum.Material.SmoothPlastic, false)
			end
		end
	end

	local function windmill(parent, pos)
		-- Tapered stone-and-timber tower (plain boxes, no rotation) plus
		-- a 4-blade rotor built as a model around the origin, so the
		-- animation loop can spin it with a single PivotTo. Returns the
		-- rotor {model, hub} for the loop.
		local tower = Instance.new("Folder")
		tower.Name = "Windmill"
		tower.Parent = parent
		part("WindmillBase", Vector3.new(12, 2, 12), Color3.fromRGB(140, 130, 115), pos + Vector3.new(0, BEACH_TOP_Y + 1, 0), tower, Enum.Material.Slate)
		part("WindmillTower", Vector3.new(8, 14, 8), Color3.fromRGB(210, 190, 160), pos + Vector3.new(0, BEACH_TOP_Y + 9, 0), tower, Enum.Material.Brick)
		part("WindmillTowerTop", Vector3.new(6.5, 6, 6.5), Color3.fromRGB(190, 165, 130), pos + Vector3.new(0, BEACH_TOP_Y + 19, 0), tower, Enum.Material.Brick)
		part("WindmillRoof", Vector3.new(8, 2, 8), Color3.fromRGB(160, 70, 60), pos + Vector3.new(0, BEACH_TOP_Y + 23, 0), tower, Enum.Material.SmoothPlastic)
		part("WindmillDoor", Vector3.new(2, 3.5, 0.4), Color3.fromRGB(90, 60, 35), pos + Vector3.new(0, BEACH_TOP_Y + 3.7, 4.1), tower, Enum.Material.Wood)
		local rotor = Instance.new("Model")
		rotor.Name = "WindmillRotor"
		local hub = Instance.new("Part")
		hub.Name = "RotorHub"
		hub.Shape = Enum.PartType.Ball
		hub.Size = Vector3.new(2, 2, 2)
		hub.Color = Color3.fromRGB(90, 60, 35)
		hub.Anchored = true
		hub.CanCollide = false
		hub.Position = Vector3.new(0, 0, 0)
		hub.Parent = rotor
		rotor.PrimaryPart = hub
		for i = 0, 3 do
			local ang = i * math.pi / 2
			local blade = Instance.new("Part")
			blade.Name = "RotorBlade"
			blade.Size = Vector3.new(1.2, 8, 0.3)
			blade.Color = Color3.fromRGB(250, 240, 220)
			blade.Material = Enum.Material.Fabric
			blade.Anchored = true
			blade.CanCollide = false
			blade.Position = Vector3.new(math.cos(ang) * 5, math.sin(ang) * 5, 0.5)
			-- Long axis (Y) must point radially: rotate by ang - 90 deg.
			blade.CFrame = CFrame.new(blade.Position) * CFrame.Angles(0, 0, ang - math.pi / 2)
			blade.Parent = rotor
		end
		rotor.Parent = tower
		local hubPos = pos + Vector3.new(0, BEACH_TOP_Y + 20, 4.5)
		rotor:PivotTo(CFrame.new(hubPos))
		return { model = rotor, hub = hubPos }
	end

	local function beachUmbrella(parent, pos, canopyColor)
		-- Pole + a wide fabric canopy (flattened ball) + a deck chair.
		part("UmbrellaPole", Vector3.new(0.4, 4, 0.4), Color3.fromRGB(120, 100, 80), pos + Vector3.new(0, BEACH_TOP_Y + 2, 0), parent, Enum.Material.Wood)
		local canopy = Instance.new("Part")
		canopy.Name = "UmbrellaCanopy"
		canopy.Shape = Enum.PartType.Ball
		canopy.Size = Vector3.new(7, 2.5, 7)
		canopy.Color = canopyColor
		canopy.Material = Enum.Material.Fabric
		canopy.Anchored = true
		canopy.CanCollide = false
		canopy.Position = pos + Vector3.new(0, BEACH_TOP_Y + 4.2, 0)
		canopy.Parent = parent
		part("DeckChair", Vector3.new(2, 0.4, 4), Color3.fromRGB(200, 170, 120), pos + Vector3.new(3.5, BEACH_TOP_Y + 0.4, 1), parent, Enum.Material.Wood)
		part("DeckChairBack", Vector3.new(2, 1.2, 0.3), Color3.fromRGB(200, 170, 120), pos + Vector3.new(3.5, BEACH_TOP_Y + 0.9, 2.8), parent, Enum.Material.Wood)
	end

	local function well(parent, pos)
		-- A stone well: low wall, water inside, posts, a roof, a bucket.
		part("WellWall", Vector3.new(4, 2, 4), Color3.fromRGB(140, 130, 115), pos + Vector3.new(0, BEACH_TOP_Y + 1, 0), parent, Enum.Material.Brick)
		part("WellWater", Vector3.new(3, 0.4, 3), Color3.fromRGB(70, 140, 200), pos + Vector3.new(0, BEACH_TOP_Y + 1.8, 0), parent, Enum.Material.Water, false)
		for _, sx in ipairs({ -1, 1 }) do
			part("WellPost", Vector3.new(0.5, 3.5, 0.5), Color3.fromRGB(120, 85, 50), pos + Vector3.new(sx * 1.7, BEACH_TOP_Y + 3.7, 0), parent, Enum.Material.Wood)
		end
		part("WellRoof", Vector3.new(5.5, 0.6, 5.5), Color3.fromRGB(160, 70, 60), pos + Vector3.new(0, BEACH_TOP_Y + 5.6, 0), parent, Enum.Material.Wood)
		part("WellBucket", Vector3.new(1, 1, 1), Color3.fromRGB(90, 60, 35), pos + Vector3.new(0, BEACH_TOP_Y + 3, 0), parent, Enum.Material.Wood)
	end

	local function pond(parent, center, radius)
		-- A round pond: a flat water ellipsoid, a stone rim, lily pads.
		local water = Instance.new("Part")
		water.Name = "PondWater"
		water.Shape = Enum.PartType.Ball
		water.Size = Vector3.new(radius * 2, 0.8, radius * 2)
		water.Color = Color3.fromRGB(70, 140, 200)
		water.Material = Enum.Material.Water
		water.Transparency = 0.15
		water.Anchored = true
		water.CanCollide = false
		water.Position = center + Vector3.new(0, BEACH_TOP_Y + 0.2, 0)
		water.Parent = parent
		for i = 0, 7 do
			local ang = i * math.pi / 4
			part("PondStone", Vector3.new(1.5, 0.8, 1.5), Color3.fromRGB(150, 145, 135), Vector3.new(center.X + math.cos(ang) * (radius + 0.5), BEACH_TOP_Y + 0.4, center.Z + math.sin(ang) * (radius + 0.5)), parent, Enum.Material.Slate)
		end
		for _, lp in ipairs({ { -3, -2 }, { 2, 3 }, { 4, -1 } }) do
			local pad = Instance.new("Part")
			pad.Name = "LilyPad"
			pad.Shape = Enum.PartType.Ball
			pad.Size = Vector3.new(2, 0.3, 2)
			pad.Color = Color3.fromRGB(60, 160, 80)
			pad.Material = Enum.Material.Grass
			pad.Anchored = true
			pad.CanCollide = false
			pad.Position = center + Vector3.new(lp[1], BEACH_TOP_Y + 0.65, lp[2])
			pad.Parent = parent
		end
	end

	local function lookoutTower(parent, pos)
		-- A wooden lifeguard / lookout tower: legs, platform, railing,
		-- roof. Players can climb it (legs are CanCollide, platform solid).
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				part("LookoutLeg", Vector3.new(0.6, 8, 0.6), Color3.fromRGB(120, 85, 50), pos + Vector3.new(sx * 2.5, BEACH_TOP_Y + 4, sz * 2.5), parent, Enum.Material.Wood)
			end
		end
		part("LookoutPlatform", Vector3.new(7, 0.6, 7), Color3.fromRGB(180, 140, 90), pos + Vector3.new(0, BEACH_TOP_Y + 8.3, 0), parent, Enum.Material.Wood)
		for _, sz in ipairs({ -1, 1 }) do
			part("LookoutRail", Vector3.new(7, 1, 0.3), Color3.fromRGB(150, 110, 70), pos + Vector3.new(0, BEACH_TOP_Y + 9.3, sz * 3.3), parent, Enum.Material.Wood)
		end
		for _, sx in ipairs({ -1, 1 }) do
			part("LookoutRail", Vector3.new(0.3, 1, 7), Color3.fromRGB(150, 110, 70), pos + Vector3.new(sx * 3.3, BEACH_TOP_Y + 9.3, 0), parent, Enum.Material.Wood)
		end
		for _, sx in ipairs({ -1, 1 }) do
			part("LookoutRoofPost", Vector3.new(0.4, 2, 0.4), Color3.fromRGB(120, 85, 50), pos + Vector3.new(sx * 3, BEACH_TOP_Y + 10.5, 0), parent, Enum.Material.Wood)
		end
		part("LookoutRoof", Vector3.new(8, 0.5, 8), Color3.fromRGB(160, 70, 60), pos + Vector3.new(0, BEACH_TOP_Y + 11.5, 0), parent, Enum.Material.Wood)
	end

	local function boardwalk(parent, x0, x1, z)
		-- A wooden boardwalk along Z=z from X=x0 to X=x1.
		local x = x0
		while x <= x1 do
			part("BoardwalkPlank", Vector3.new(1.8, 0.3, 6), Color3.fromRGB(170, 130, 85), Vector3.new(x, BEACH_TOP_Y + 0.35, z), parent, Enum.Material.WoodPlanks)
			x += 2
		end
	end

	local function stonePath(parent, x0, z0, x1, z1)
		-- A stepping-stone path from (x0,z0) to (x1,z1): flat stones
		-- every 3 studs, weaving slightly for a natural look.
		local dx = x1 - x0
		local dz = z1 - z0
		local len = math.sqrt(dx * dx + dz * dz)
		local steps = math.max(1, math.floor(len / 3))
		for i = 0, steps do
			local f = i / steps
			part("PathStone", Vector3.new(2.5, 0.3, 2.5), Color3.fromRGB(190, 180, 165), Vector3.new(x0 + dx * f + math.sin(i * 2.1) * 0.6, BEACH_TOP_Y + 0.35, z0 + dz * f + math.cos(i * 1.7) * 0.6), parent, Enum.Material.Cobblestone)
		end
	end

	-- EAST RESIDENTIAL (X 120..250, Z -110..110): seven houses on a
	-- quiet street, a park with a pond, paths and lamps.
	for i, h in ipairs({
		{ Vector3.new(130, 0, -70), Color3.fromRGB(250, 220, 180), Color3.fromRGB(180, 80, 60), 1 },
		{ Vector3.new(175, 0, -35), Color3.fromRGB(220, 235, 250), Color3.fromRGB(70, 110, 160), -1 },
		{ Vector3.new(215, 0, 5), Color3.fromRGB(250, 235, 200), Color3.fromRGB(120, 90, 60), 1 },
		{ Vector3.new(145, 0, 45), Color3.fromRGB(235, 215, 190), Color3.fromRGB(90, 140, 90), -1 },
		{ Vector3.new(185, 0, 85), Color3.fromRGB(250, 220, 180), Color3.fromRGB(180, 80, 60), 1 },
		{ Vector3.new(225, 0, -60), Color3.fromRGB(220, 235, 250), Color3.fromRGB(70, 110, 160), -1 },
		{ Vector3.new(160, 0, -105), Color3.fromRGB(235, 215, 190), Color3.fromRGB(120, 90, 60), 1 },
	}) do
		house(districts, h[1], h[2], h[3], h[4], 100 + i)
	end
	-- Park: grass lawn + pond + benches + lamps, frogs and a turtle live
	-- here (registered with the animals below).
	part("ParkLawn", Vector3.new(40, 0.3, 30), Color3.fromRGB(100, 200, 110), Vector3.new(200, BEACH_TOP_Y + 0.3, 120), districts, Enum.Material.Grass)
	pond(districts, Vector3.new(200, 0, 120), 8)
	for _, spot in ipairs({ Vector3.new(185, 0, 110), Vector3.new(215, 0, 130) }) do
		part("ParkBenchSeat", Vector3.new(4, 0.5, 1.5), Color3.fromRGB(150, 100, 55), spot + Vector3.new(0, BEACH_TOP_Y + 1.2, 0), districts, Enum.Material.Wood)
		part("ParkBenchBack", Vector3.new(4, 1.5, 0.3), Color3.fromRGB(150, 100, 55), spot + Vector3.new(0, BEACH_TOP_Y + 2, -0.7), districts, Enum.Material.Wood)
	end
	for _, spot in ipairs({ Vector3.new(185, 0, 130), Vector3.new(215, 0, 110) }) do
		part("ParkLampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(70, 55, 40), spot + Vector3.new(0, BEACH_TOP_Y + 3.5, 0), districts)
		part("ParkLampHead", Vector3.new(1.6, 1, 1.6), Color3.fromRGB(255, 240, 160), spot + Vector3.new(0, BEACH_TOP_Y + 7.4, 0), districts, Enum.Material.Neon, false)
	end
	stonePath(districts, 120, -20, 200, 115)
	stonePath(districts, 150, 40, 200, 115)
	stonePath(districts, 200, 115, 200, 185)

	-- WEST FARM (X -250..-160, Z -120..120): farmhouse, barn, two crop
	-- fields, a spinning windmill, fences and a well.
	house(districts, Vector3.new(-200, 0, -60), Color3.fromRGB(250, 220, 180), Color3.fromRGB(180, 80, 60), 1, 200)
	barn(districts, Vector3.new(-220, 0, 20), Color3.fromRGB(190, 60, 55), Color3.fromRGB(120, 60, 40), 201)
	cropField(districts, Vector3.new(-190, 0, 60), 3, 6, Color3.fromRGB(90, 190, 80), Color3.fromRGB(255, 140, 60))
	cropField(districts, Vector3.new(-200, 0, -110), 3, 6, Color3.fromRGB(70, 170, 90), Color3.fromRGB(255, 80, 120))
	local windmillEntry = windmill(districts, Vector3.new(-170, 0, 110))
	well(districts, Vector3.new(-175, 0, 0))
	fenceRun(districts, -180, 48, 72, 300)
	fenceRun(districts, -200, 48, 72, 301)
	fenceRun(districts, -185, -122, -98, 302)
	fenceRun(districts, -215, -122, -98, 303)
	stonePath(districts, -160, -60, -200, -60)
	stonePath(districts, -160, 60, -190, 60)

	-- SOUTH BEACH RESORT (Z 180..205, X -200..200): umbrellas, deck
	-- chairs, a beach bar, market stalls, a lifeguard tower, a boardwalk.
	for i, ux in ipairs({ -150, -80, 0, 80, 150 }) do
		local colors = {
			Color3.fromRGB(255, 90, 90), Color3.fromRGB(90, 160, 255),
			Color3.fromRGB(255, 220, 80), Color3.fromRGB(120, 220, 130),
			Color3.fromRGB(255, 150, 200),
		}
		beachUmbrella(districts, Vector3.new(ux, 0, 195), colors[i])
	end
	shop(districts, Vector3.new(-40, 0, 190), Color3.fromRGB(250, 235, 200), Color3.fromRGB(70, 140, 200), 202, "BEACH BAR")
	marketStall(districts, Vector3.new(20, 0, 190), Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 255, 255), 203)
	marketStall(districts, Vector3.new(60, 0, 190), Color3.fromRGB(90, 160, 255), Color3.fromRGB(255, 255, 255), 204)
	lookoutTower(districts, Vector3.new(120, 0, 192))
	boardwalk(districts, -80, 80, 185)

	-- NORTH PROMENADE (Z -205..-185, X -200..200): a long boardwalk with
	-- benches, lamps, palms and two lookout towers facing the sea.
	boardwalk(districts, -160, 160, -195)
	for _, bx in ipairs({ -100, 0, 100 }) do
		part("PromBenchSeat", Vector3.new(4, 0.5, 1.5), Color3.fromRGB(150, 100, 55), Vector3.new(bx, BEACH_TOP_Y + 1.2, -193), districts, Enum.Material.Wood)
		part("PromBenchBack", Vector3.new(4, 1.5, 0.3), Color3.fromRGB(150, 100, 55), Vector3.new(bx, BEACH_TOP_Y + 2, -192.3), districts, Enum.Material.Wood)
	end
	for _, lx in ipairs({ -50, 50 }) do
		part("PromLampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(70, 55, 40), Vector3.new(lx, BEACH_TOP_Y + 3.5, -197), districts)
		part("PromLampHead", Vector3.new(1.6, 1, 1.6), Color3.fromRGB(255, 240, 160), Vector3.new(lx, BEACH_TOP_Y + 7.4, -197), districts, Enum.Material.Neon, false)
	end
	lookoutTower(districts, Vector3.new(-170, 0, -192))
	lookoutTower(districts, Vector3.new(170, 0, -192))
	for i, px in ipairs({ -180, -60, 60, 180 }) do
		palmTree(districts, Vector3.new(px, 0, -185), 400 + i)
	end

	-- FOREST GROVES: dense clusters of round and tall trees, a fox and
	-- deer live in them. NE (X 150..240, Z -200..-170), NW (X -240..-150,
	-- Z -200..-170), SE (X 160..240, Z 145..175).
	for i, spot in ipairs({
		Vector3.new(160, 0, -185), Vector3.new(190, 0, -195), Vector3.new(220, 0, -180),
		Vector3.new(175, 0, -170), Vector3.new(205, 0, -195), Vector3.new(235, 0, -185),
		Vector3.new(150, 0, -200), Vector3.new(240, 0, -170),
	}) do
		if i % 3 == 0 then
			table.insert(tallTrees, tallTree(districts, spot, 500 + i))
		else
			roundTree(districts, spot, 500 + i)
		end
	end
	for i, spot in ipairs({
		Vector3.new(-160, 0, -185), Vector3.new(-190, 0, -195), Vector3.new(-220, 0, -180),
		Vector3.new(-175, 0, -170), Vector3.new(-205, 0, -195), Vector3.new(-235, 0, -185),
		Vector3.new(-150, 0, -200), Vector3.new(-240, 0, -170),
	}) do
		if i % 3 == 0 then
			table.insert(tallTrees, tallTree(districts, spot, 520 + i))
		else
			roundTree(districts, spot, 520 + i)
		end
	end
	for i, spot in ipairs({
		Vector3.new(170, 0, 150), Vector3.new(200, 0, 160), Vector3.new(230, 0, 145),
		Vector3.new(185, 0, 170), Vector3.new(215, 0, 175), Vector3.new(240, 0, 160),
		Vector3.new(160, 0, 175),
	}) do
		if i % 3 == 0 then
			table.insert(tallTrees, tallTree(districts, spot, 540 + i))
		else
			roundTree(districts, spot, 540 + i)
		end
	end

	-- v6: NEW LIVE ANIMALS — nine more species, all animated by the one
	-- loop below. Ground wanderers are 2x like the v3.5 ones; the 6th
	-- spec element is the bob amplitude (rabbits and frogs hop, the
	-- turtle barely bobs). Seagulls orbit over the sea; fish swim in the
	-- two sea bands just under the water surface.
	for _, spec in ipairs({
		{ buildCat, Vector3.new(160, 0, 0), 30, 0.20, 0.5, 0.25 },
		{ buildCat, Vector3.new(-200, 0, -60), 15, 0.20, 1.5, 0.25 },
		{ buildRabbit, Vector3.new(-200, 0, 50), 20, 0.25, 2.5, 0.9 },
		{ buildRabbit, Vector3.new(185, 0, 165), 15, 0.25, 3.5, 0.9 },
		{ buildFox, Vector3.new(195, 0, -185), 25, 0.22, 4.5, 0.3 },
		{ buildDeer, Vector3.new(-195, 0, -185), 25, 0.18, 5.5, 0.3 },
		{ buildDeer, Vector3.new(200, 0, 160), 20, 0.18, 0.8, 0.3 },
		{ buildFrog, Vector3.new(200, 0, 120), 12, 0.20, 1.8, 0.7 },
		{ buildTurtle, Vector3.new(200, 0, 120), 10, 0.06, 2.8, 0.1 },
		{ buildCrab, Vector3.new(100, 0, 195), 15, 0.18, 3.8, 0.3 },
		{ buildCrab, Vector3.new(-120, 0, 195), 15, 0.18, 4.8, 0.3 },
		{ buildCow, Vector3.new(-195, 0, 30), 8, 0.10, 5.8, 0.25 },
		{ buildPig, Vector3.new(-210, 0, 80), 8, 0.10, 0.3, 0.25 },
	}) do
		local model, pivotY = spec[1]()
		model:ScaleTo(2)
		pivotY = pivotY * 2
		model.Parent = animalsFolder
		table.insert(wanderers, {
			model = model,
			home = spec[2],
			radius = spec[3],
			speed = spec[4],
			phase = spec[5],
			pivotY = pivotY,
			bobAmp = spec[6],
		})
	end
	for _, spec in ipairs({
		{ Color3.fromRGB(245, 245, 245), 0, Vector3.new(0, 45, -225), 70 },
		{ Color3.fromRGB(200, 210, 220), math.pi, Vector3.new(0, 45, 225), 70 },
	}) do
		local model, wings = buildBird(spec[1])
		model:ScaleTo(2)
		for _, wing in ipairs(wings) do
			wing.attach = wing.attach * 2
			wing.centre = wing.centre * 2
		end
		model.Parent = animalsFolder
		table.insert(orbiters, {
			model = model,
			wings = wings,
			centre = spec[3],
			radius = spec[4],
			speed = 0.15,
			phase = spec[2],
		})
	end
	local swimmers = {}
	for _, spec in ipairs({
		{ Color3.fromRGB(255, 150, 60), Vector3.new(0, -0.4, -230), 50, 0.12, 0 },
		{ Color3.fromRGB(90, 180, 255), Vector3.new(0, -0.4, -230), 40, 0.10, 2.0 },
		{ Color3.fromRGB(255, 220, 80), Vector3.new(0, -0.4, 230), 50, 0.12, 1.0 },
		{ Color3.fromRGB(255, 150, 60), Vector3.new(0, -0.4, 230), 40, 0.10, 3.0 },
		{ Color3.fromRGB(180, 120, 255), Vector3.new(0, -0.4, 230), 30, 0.14, 4.0 },
		{ Color3.fromRGB(90, 180, 255), Vector3.new(0, -0.4, -230), 30, 0.14, 5.0 },
	}) do
		local model, _, tail = buildFish(spec[1])
		model:ScaleTo(2)
		tail.attach = tail.attach * 2
		tail.centre = tail.centre * 2
		model.Parent = animalsFolder
		table.insert(swimmers, {
			model = model,
			tail = tail,
			centre = spec[2],
			radius = spec[3],
			speed = spec[4],
			phase = spec[5],
		})
	end
	local windmills = { windmillEntry }

	-- v6: TEXTURE / GROUND DETAIL — the last layer that makes the world
	-- feel real: a marble statue on the village green, beach towels and
	-- a sandcastle on the south beach, boulders and bushes filling the
	-- map corners, and flower clusters along the residential street.
	-- Materials are varied on purpose: Marble, Sand, Cobblestone, Brick,
	-- Fabric, Grass, Slate — no more flat SmoothPlastic everywhere.
	part("StatuePedestal", Vector3.new(4, 2, 4), Color3.fromRGB(180, 175, 165), Vector3.new(160, BEACH_TOP_Y + 1, -20), districts, Enum.Material.Marble)
	part("StatueBody", Vector3.new(2, 3, 2), Color3.fromRGB(200, 195, 185), Vector3.new(160, BEACH_TOP_Y + 3.5, -20), districts, Enum.Material.Marble)
	local statueHead = Instance.new("Part")
	statueHead.Name = "StatueHead"
	statueHead.Shape = Enum.PartType.Ball
	statueHead.Size = Vector3.new(2, 2, 2)
	statueHead.Color = Color3.fromRGB(200, 195, 185)
	statueHead.Material = Enum.Material.Marble
	statueHead.Anchored = true
	statueHead.CanCollide = false
	statueHead.Position = Vector3.new(160, BEACH_TOP_Y + 6, -20)
	statueHead.Parent = districts
	for i, tx in ipairs({ -140, -70, 10 }) do
		local towelColors = {
			Color3.fromRGB(255, 120, 120), Color3.fromRGB(120, 180, 255), Color3.fromRGB(255, 220, 100),
		}
		part("BeachTowel", Vector3.new(3, 0.15, 5), towelColors[i], Vector3.new(tx, BEACH_TOP_Y + 0.3, 200), districts, Enum.Material.Fabric, false)
	end
	part("SandcastleBase", Vector3.new(6, 3, 6), Color3.fromRGB(235, 210, 160), Vector3.new(60, BEACH_TOP_Y + 1.5, 200), districts, Enum.Material.Sand)
	part("SandcastleTop", Vector3.new(4, 2.5, 4), Color3.fromRGB(235, 210, 160), Vector3.new(60, BEACH_TOP_Y + 4.2, 200), districts, Enum.Material.Sand)
	local scTower = Instance.new("Part")
	scTower.Name = "SandcastleTower"
	scTower.Shape = Enum.PartType.Ball
	scTower.Size = Vector3.new(2.5, 2.5, 2.5)
	scTower.Color = Color3.fromRGB(235, 210, 160)
	scTower.Material = Enum.Material.Sand
	scTower.Anchored = true
	scTower.CanCollide = false
	scTower.Position = Vector3.new(60, BEACH_TOP_Y + 6.5, 200)
	scTower.Parent = districts
	part("SandcastleFlagPole", Vector3.new(0.2, 2, 0.2), Color3.fromRGB(120, 85, 50), Vector3.new(60, BEACH_TOP_Y + 8, 200), districts, Enum.Material.Wood)
	part("SandcastleFlag", Vector3.new(1.5, 1, 0.1), Color3.fromRGB(255, 90, 90), Vector3.new(60.8, BEACH_TOP_Y + 8.5, 200), districts, Enum.Material.Fabric, false)
	for i, spot in ipairs({
		Vector3.new(240, 0, -120), Vector3.new(-240, 0, -120), Vector3.new(240, 0, 100),
		Vector3.new(-240, 0, 100), Vector3.new(100, 0, -200), Vector3.new(-100, 0, 200),
	}) do
		local rock = Instance.new("Part")
		rock.Name = "Boulder"
		rock.Shape = Enum.PartType.Ball
		rock.Size = Vector3.new(3 + (i % 3), 2 + (i % 2), 3 + (i % 3))
		rock.Color = Color3.fromRGB(140, 140, 145)
		rock.Material = Enum.Material.Slate
		rock.Anchored = true
		rock.CanCollide = true
		rock.Position = spot + Vector3.new(0, BEACH_TOP_Y + 0.8, 0)
		rock.Parent = districts
	end
	for _, spot in ipairs({
		Vector3.new(120, 0, -120), Vector3.new(240, 0, -30), Vector3.new(120, 0, 120),
		Vector3.new(-120, 0, -120), Vector3.new(-240, 0, 30), Vector3.new(-120, 0, 120),
		Vector3.new(240, 0, 170), Vector3.new(-240, 0, 170),
	}) do
		local bush = Instance.new("Part")
		bush.Name = "Bush"
		bush.Shape = Enum.PartType.Ball
		bush.Size = Vector3.new(3, 2.5, 3)
		bush.Color = Color3.fromRGB(60, 170, 80)
		bush.Material = Enum.Material.Grass
		bush.Anchored = true
		bush.CanCollide = false
		bush.Position = spot + Vector3.new(0, BEACH_TOP_Y + 1.2, 0)
		bush.Parent = districts
	end
	for _, spot in ipairs({
		Vector3.new(190, 0, 108), Vector3.new(210, 0, 132), Vector3.new(135, 0, -55),
		Vector3.new(180, 0, -20), Vector3.new(220, 0, 20), Vector3.new(150, 0, 60),
	}) do
		for _, off in ipairs({ Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1) }) do
			part("FlowerStem", Vector3.new(0.2, 0.8, 0.2), Color3.fromRGB(60, 160, 80), spot + off + Vector3.new(0, BEACH_TOP_Y + 0.4, 0), districts, Enum.Material.Grass, false)
			local flower = Instance.new("Part")
			flower.Name = "Flower"
			flower.Shape = Enum.PartType.Ball
			flower.Size = Vector3.new(0.7, 0.7, 0.7)
			flower.Color = Color3.fromRGB(255, 120, 180)
			flower.Anchored = true
			flower.CanCollide = false
			flower.Position = spot + off + Vector3.new(0, BEACH_TOP_Y + 1, 0)
			flower.Parent = districts
		end
	end

	-- ONE animation loop for the whole bay (v3.4): tall trees lean and
	-- sway, ground animals wander in small circles with a gentle bob, and
	-- the birds orbit overhead banking and flapping. A single task.spawn
	-- loop at 10 Hz, ~30 CFrame writes per tick — cheap, no per-part
	-- connections. Same pattern as the water/chevron loops above.
	task.spawn(function()
		local t = 0
		while world.Parent do
			t += 0.1
			for _, tree in ipairs(tallTrees) do
				local lean = math.rad(1.5) * math.sin(t * 1.1 + tree.phase)
				local sway = math.rad(3) * math.sin(t * 1.1 + tree.phase + 0.6)
				tree.trunk.CFrame = CFrame.new(tree.base) * CFrame.Angles(0, 0, lean)
					* CFrame.new(0, tree.trunkLen / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
				local top = tree.base + Vector3.new(
					-tree.trunkLen * math.sin(lean),
					tree.trunkLen * math.cos(lean),
					0
				)
				for _, leaf in ipairs(tree.leaves) do
					leaf.part.CFrame = CFrame.new(top) * CFrame.Angles(0, 0, sway) * CFrame.new(leaf.offset)
				end
			end
			for _, w in ipairs(wanderers) do
				local a = t * w.speed + w.phase
				local x = w.home.X + math.cos(a) * w.radius
				local z = w.home.Z + math.sin(a) * w.radius
				local heading = math.atan2(-math.sin(a), math.cos(a))
				-- v6: per-animal bob amplitude — rabbits and frogs hop,
				-- the turtle barely bobs. Defaults to the v3.4 0.25.
				local bob = math.abs(math.sin(t * 2 + w.phase)) * (w.bobAmp or 0.25)
				w.model:PivotTo(CFrame.new(x, BEACH_TOP_Y + w.pivotY + bob, z) * CFrame.Angles(0, heading, 0))
			end
			for _, b in ipairs(orbiters) do
				local a = t * b.speed + b.phase
				local x = b.centre.X + math.cos(a) * b.radius
				local z = b.centre.Z + math.sin(a) * b.radius
				local y = b.centre.Y + math.sin(t * 0.7 + b.phase) * 1.5
				local heading = math.atan2(-math.sin(a), math.cos(a))
				local roll = math.rad(20) * math.sin(t * 2 + b.phase)
				local pivot = CFrame.new(x, y, z) * CFrame.Angles(0, heading, 0) * CFrame.Angles(roll, 0, 0)
				b.model:PivotTo(pivot)
				local flap = math.rad(25) * math.sin(t * 6 + b.phase)
				for _, wing in ipairs(b.wings) do
					wing.part.CFrame = pivot * CFrame.new(wing.attach)
						* CFrame.Angles(0, 0, wing.side * flap) * CFrame.new(wing.centre - wing.attach)
				end
			end
			-- v3.6: the lighthouse beams sweep slowly, the flag poles wave,
			-- butterflies flutter over the flower beds, and the boats bob.
			for _, beam in ipairs(beams) do
				local angle = t * 0.5
				beam.part.CFrame = CFrame.new(beam.pivot) * CFrame.Angles(0, angle, 0) * CFrame.new(beam.dir * 13, 0, 0)
			end
			for _, f in ipairs(waveFlags) do
				local w = math.sin(t * 2 + f.phase)
				f.part.CFrame = f.base * CFrame.Angles(0, w * 0.1, w * 0.12)
			end
			for _, b in ipairs(butterflies) do
				local a = t * b.speed + b.phase
				local x = b.centre.X + math.cos(a) * b.radius
				local z = b.centre.Z + math.sin(a) * b.radius
				local y = b.centre.Y + math.sin(t * 1.3 + b.phase) * 0.8
				local heading = math.atan2(-math.sin(a), math.cos(a))
				local pivot = CFrame.new(x, y, z) * CFrame.Angles(0, heading, 0)
				b.model:PivotTo(pivot)
				local flap = math.rad(40) * math.sin(t * 10 + b.phase)
				for _, wing in ipairs(b.wings) do
					wing.part.CFrame = pivot * CFrame.new(wing.attach)
						* CFrame.Angles(0, 0, wing.side * flap) * CFrame.new(wing.centre - wing.attach)
				end
			end
			for _, boat in ipairs(boats) do
				local bob = math.sin(t * 0.8 + boat.phase) * 0.3
				local roll = math.rad(3) * math.sin(t * 0.8 + boat.phase + 1)
				boat.model:PivotTo(CFrame.new(boat.home.X, 0.5 + boat.pivotY + bob, boat.home.Z)
					* CFrame.Angles(0, boat.heading, roll))
			end
			-- v6: fish swim in circles just under the sea surface, tails
			-- wagging side to side; the farm windmill's rotor turns.
			for _, s in ipairs(swimmers) do
				local a = t * s.speed + s.phase
				local x = s.centre.X + math.cos(a) * s.radius
				local z = s.centre.Z + math.sin(a) * s.radius
				local heading = math.atan2(-math.sin(a), math.cos(a))
				local pivot = CFrame.new(x, s.centre.Y, z) * CFrame.Angles(0, heading, 0)
				s.model:PivotTo(pivot)
				local wiggle = math.rad(20) * math.sin(t * 5 + s.phase)
				s.tail.part.CFrame = pivot * CFrame.new(s.tail.attach)
					* CFrame.Angles(0, wiggle, 0) * CFrame.new(s.tail.centre - s.tail.attach)
			end
			for _, wm in ipairs(windmills) do
				wm.model:PivotTo(CFrame.new(wm.hub) * CFrame.Angles(0, 0, t * 0.6))
			end
			task.wait(0.1)
		end
	end)

	return bases
end

return WorldBuilder
