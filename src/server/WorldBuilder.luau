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
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local WorldBuilder = {}

local BASE_COLORS = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(90, 160, 255),
	Color3.fromRGB(120, 220, 120),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(200, 120, 255),
	Color3.fromRGB(90, 220, 210),
	Color3.fromRGB(255, 140, 200),
	Color3.fromRGB(255, 160, 80),
	Color3.fromRGB(140, 220, 255),
	Color3.fromRGB(190, 255, 140),
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

-- A dark board with a floating text label that always faces the camera.
local function signBoard(parent, position, text, textColor, boardSize)
	local board = part("Sign", boardSize or Vector3.new(16, 4.5, 0.6), Color3.fromRGB(30, 30, 42), position, parent)
	local gui = Instance.new("BillboardGui")
	gui.Name = "SignLabel"
	gui.Size = UDim2.new(0, 300, 0, 80)
	gui.AlwaysOnTop = true
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
		leaf.Color = Color3.fromRGB(50, 185, 80)
		leaf.Anchored = true
		leaf.CanCollide = false
		leaf.Position = spot + Vector3.new(math.cos(angle) * 2.6, 9.2, math.sin(angle) * 2.6)
		leaf.Parent = parent
	end
	local crown = Instance.new("Part")
	crown.Name = "PalmCrown" .. index
	crown.Shape = Enum.PartType.Ball
	crown.Size = Vector3.new(5, 4, 5)
	crown.Color = Color3.fromRGB(60, 200, 90)
	crown.Anchored = true
	crown.CanCollide = false
	crown.Position = spot + Vector3.new(0, 9.6, 0)
	crown.Parent = parent
end

local function marketStall(parent, position, stripeA, stripeB, index)
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
	local porchZ = faceZ + 1.6 * BS
	part("PorchFloor", Vector3.new(6 * BS, 0.3 * BS, 3 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(pos.X, baseY + 0.15 * BS, porchZ), b, Enum.Material.Wood)
	for _, px in ipairs({ -2.6 * BS, 2.6 * BS }) do
		part("PorchPost", Vector3.new(0.5 * BS, 5.4 * BS, 0.5 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X + px, baseY + 2.9 * BS, porchZ + 1.2 * BS), b, Enum.Material.Wood)
	end
	local awn = part("PorchAwning", Vector3.new(6.2 * BS, 0.25 * BS, 3.2 * BS), roofColor, Vector3.new(pos.X, baseY + 5.4 * BS, porchZ + 0.4 * BS), b, Enum.Material.Fabric, false)
	awn.CFrame = CFrame.new(awn.Position) * CFrame.Angles(math.rad(12), 0, 0)
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
	part("ShopWindowFrame", Vector3.new(4.5 * BS, 2.6 * BS, 0.2 * BS), Color3.fromRGB(255, 255, 255), Vector3.new(pos.X + 2 * BS, baseY + 3.4 * BS, faceZ + 0.1 * BS), s, Enum.Material.SmoothPlastic, false)
	part("ShopWindowGlass", Vector3.new(4.1 * BS, 2.2 * BS, 0.26 * BS), Color3.fromRGB(150, 210, 255), Vector3.new(pos.X + 2 * BS, baseY + 3.4 * BS, faceZ + 0.14 * BS), s, Enum.Material.Glass, false)
	xWindow(s, pos.X + W / 2, baseY + 3.6 * BS, pos.Z, 1)
	xWindow(s, pos.X - W / 2, baseY + 3.6 * BS, pos.Z, -1)
	signBoard(s, Vector3.new(pos.X, baseY + 5.8 * BS, faceZ + 0.4 * BS), name or "TIDE SHOP", Color3.fromRGB(255, 220, 80), Vector3.new(8 * BS, 2.5 * BS, 0.4 * BS))
	local ridgeY = baseY + H + 3 * BS
	pitchedRoof(s, Vector3.new(pos.X, ridgeY, pos.Z), D / 2 + 1 * BS, 3 * BS, W + 1 * BS, roofColor, "X")
	part("Chimney", Vector3.new(1.2 * BS, 3 * BS, 1.2 * BS), Color3.fromRGB(150, 60, 60), Vector3.new(pos.X + 3 * BS, ridgeY - 1 * BS, pos.Z + 2 * BS), s, Enum.Material.SmoothPlastic)
	part("ChimneyCap", Vector3.new(1.8 * BS, 0.5 * BS, 1.8 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X + 3 * BS, ridgeY + 0.7 * BS, pos.Z + 2 * BS), s, Enum.Material.SmoothPlastic, false)
	for i = 0, 2 do
		local color = (i % 2 == 0) and roofColor or Color3.fromRGB(255, 255, 255)
		local panel = part("ShopAwning", Vector3.new(1.6 * BS, 0.25 * BS, 2.2 * BS), color, Vector3.new(pos.X + 0.4 * BS + i * 1.6 * BS, baseY + 5.0 * BS, faceZ + 0.9 * BS), s, Enum.Material.Fabric, false)
		panel.CFrame = CFrame.new(panel.Position) * CFrame.Angles(math.rad(12), 0, 0)
	end
	part("PorchFloor", Vector3.new(4 * BS, 0.3 * BS, 2.5 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(pos.X - 2.5 * BS, baseY + 0.15 * BS, faceZ + 1.4 * BS), s, Enum.Material.Wood)
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
		part("GateTower", Vector3.new(3 * BS, 9 * BS, 3 * BS), Color3.fromRGB(255, 200, 60), Vector3.new(pos.X + sx * 10 * BS, baseY + 4.5 * BS, pos.Z), g, Enum.Material.SmoothPlastic)
		part("TowerCap", Vector3.new(3.8 * BS, 0.6 * BS, 3.8 * BS), Color3.fromRGB(200, 120, 255), Vector3.new(pos.X + sx * 10 * BS, baseY + 9.3 * BS, pos.Z), g, Enum.Material.SmoothPlastic, false)
	end
	part("GateBeam", Vector3.new(23 * BS, 2 * BS, 3 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(pos.X, baseY + 9.5 * BS, pos.Z), g, Enum.Material.Wood)
	pitchedRoof(g, Vector3.new(pos.X, baseY + 11.5 * BS, pos.Z), 2.5 * BS, 1.5 * BS, 24 * BS, Color3.fromRGB(255, 90, 90), "Z")
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
		{ Vector3.new(0, 8.5, 0), 6.5 },
		{ Vector3.new(-2.2, 7, 0), 4.5 },
		{ Vector3.new(2.2, 7, 0), 4.5 },
	}) do
		local ball = Instance.new("Part")
		ball.Name = "TreeLeaves"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(leaf[2], leaf[2], leaf[2])
		ball.Color = Color3.fromRGB(50, 185, 80)
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
		{ Vector3.new(0, 2.5, 0), 9 },
		{ Vector3.new(-2.8, 0, 0), 6.5 },
		{ Vector3.new(2.8, 0, 0), 6.5 },
	}) do
		local ball = Instance.new("Part")
		ball.Name = "TallLeaves"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(leaf[2], leaf[2], leaf[2])
		ball.Color = Color3.fromRGB(50, 185, 80)
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

function WorldBuilder.build()
	local world = Instance.new("Folder")
	world.Name = "World"
	world.Parent = Workspace

	-- Warm afternoon sun, Future lighting, a soft hazy sky.
	-- (Lighting.Technology is NOT written here: it needs the RobloxScript
	-- capability, which a game Script lacks, so writing it killed build()
	-- on its first Lighting line. Future is already baked into the place
	-- by default.project.json's Lighting properties.)
	Lighting.ClockTime = 15
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(90, 80, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 130, 150)
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(200, 220, 255)
	atmosphere.Decay = Color3.fromRGB(120, 140, 180)
	atmosphere.Glare = 0.4
	atmosphere.Haze = 1.5
	atmosphere.Parent = Lighting

	-- The beach itself: a wide sand plate whose top sits clearly above the
	-- project baseplate (top Y=0), so the sand wins the depth fight and the
	-- ground reads as a beach, not a grey baseplate.
	part("Beach", Vector3.new(460, 1, 400), Color3.fromRGB(238, 214, 150), Vector3.new(0, BEACH_TOP_Y - 0.5, 5), world, Enum.Material.Sand)

	-- Animated water hugging the far edges of the island.
	local water = Instance.new("Folder")
	water.Name = "Water"
	water.Parent = world
	local waterParts = {}
	for _, z in ipairs({ 208, -198 }) do
		local sea = part("Sea", Vector3.new(460, 1, 70), Color3.fromRGB(40, 140, 230), Vector3.new(0, 0, z), water, Enum.Material.Neon, false)
		sea.Transparency = 0.3
		table.insert(waterParts, sea)
	end
	task.spawn(function()
		local t = 0
		while world.Parent do
			t += 0.15
			for _, sea in ipairs(waterParts) do
				sea.Position = Vector3.new(0, math.sin(t) * 0.25, sea.Position.Z)
			end
			task.wait(0.15)
		end
	end)

	-- The conveyor: a 300-stud runway down the middle, Z -145 to 155.
	local conveyor = Instance.new("Folder")
	conveyor.Name = "Conveyor"
	conveyor.Parent = world
	part("Strip", Vector3.new(14, 1, 300), Color3.fromRGB(55, 55, 70), Vector3.new(0, 0.5, 5), conveyor)
	for _, side in ipairs({ -1, 1 }) do
		part("Rail", Vector3.new(0.6, 1.6, 300), Color3.fromRGB(255, 200, 60), Vector3.new(side * 7.2, 1.3, 5), conveyor, Enum.Material.Neon)
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
		part("ArchPost", Vector3.new(1.5, 13, 1.5), Color3.fromRGB(255, 90, 140), Vector3.new(side * 8, 6.5, -148), arch)
	end
	signBoard(arch, Vector3.new(0, 14, -148), "BRAINROT BAY", Color3.fromRGB(255, 220, 80), Vector3.new(30, 5, 0.6))

	-- Spawn plaza: checker tiles where newcomers first land.
	local plaza = Instance.new("Folder")
	plaza.Name = "Plaza"
	plaza.Parent = world
	for row = 0, 3 do
		for col = 0, 7 do
			local color = ((row + col) % 2 == 0) and Color3.fromRGB(255, 240, 200) or Color3.fromRGB(90, 200, 230)
			part("PlazaTile", Vector3.new(4.8, 0.2, 4.8), color, Vector3.new(-17.5 + col * 5, BEACH_TOP_Y + 0.1, -172 + row * 5), plaza, Enum.Material.SmoothPlastic, false)
		end
	end
	signBoard(plaza, Vector3.new(0, 9, -178), "WELCOME TO THE BAY", Color3.fromRGB(120, 255, 140), Vector3.new(24, 4, 0.6))

	-- Ten bases: two rows of five flanking the conveyor.
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = world
	local bases = {}
	local index = 0
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs(BASE_Z) do
			index += 1
			local center = Vector3.new(side * 48, 1, z)
			local color = BASE_COLORS[index]
			local baseFolder = Instance.new("Folder")
			baseFolder.Name = "Base" .. index
			baseFolder.Parent = basesFolder

			part("Platform", Vector3.new(30, 1, 30), color, center + Vector3.new(0, -0.5, 0), baseFolder)
			part("BackWall", Vector3.new(1, 6, 30), Color3.fromRGB(40, 40, 55), center + Vector3.new(side * 14.5, 3, 0), baseFolder)
			-- 18 slot pads (3 rows x 6): 12 unlocked at start, +2 per
			-- capacity level up to 20. Pads past the current cap are just
			-- decoration until an upgrade unlocks them.
			local slots = {}
			for _, rz in ipairs(SLOT_ROWS) do
				for _, cx in ipairs(SLOT_COLS) do
					local slotPos = center + Vector3.new(cx, 0.6, rz)
					part("SlotPad", Vector3.new(3.4, 0.2, 3.4), Color3.fromRGB(255, 255, 255), slotPos, baseFolder, Enum.Material.Neon, false)
					table.insert(slots, slotPos + Vector3.new(0, 0.1, 0))
				end
			end
			-- Green spawn pad on the conveyor-facing edge.
			local spawnPos = center + Vector3.new(side * -18, 1, 0)
			part("SpawnPad", Vector3.new(4, 0.2, 4), Color3.fromRGB(120, 255, 140), spawnPos, baseFolder, Enum.Material.Neon, false)
			local _, signLabel = signBoard(baseFolder, center + Vector3.new(0, 9, 0), "BASE " .. index, color)
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

	marketStall(decor, Vector3.new(-26, 0, -160), Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 255, 255), 1)
	marketStall(decor, Vector3.new(26, 0, -160), Color3.fromRGB(90, 160, 255), Color3.fromRGB(255, 255, 255), 2)
	marketStall(decor, Vector3.new(-26, 0, 172), Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 255, 255), 3)
	marketStall(decor, Vector3.new(26, 0, 172), Color3.fromRGB(120, 220, 120), Color3.fromRGB(255, 255, 255), 4)
	-- v3.5: two more stalls mid-map (X ±26, Z 0 — 3 studs clear of the
	-- base platforms at X 33, clear of the fences, houses and lamps).
	marketStall(decor, Vector3.new(-26, 0, 0), Color3.fromRGB(200, 120, 255), Color3.fromRGB(255, 255, 255), 5)
	marketStall(decor, Vector3.new(26, 0, 0), Color3.fromRGB(90, 220, 210), Color3.fromRGB(255, 255, 255), 6)

	for _, z in ipairs({ -100, -40, 20, 80, 140 }) do
		for _, side in ipairs({ -1, 1 }) do
			part("LampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(50, 50, 60), Vector3.new(side * 10, 3.5, z), decor)
			part("LampHead", Vector3.new(1.6, 1, 1.6), Color3.fromRGB(255, 240, 160), Vector3.new(side * 10, 7.4, z), decor, Enum.Material.Neon, false)
		end
	end
	-- Bunting: little coloured flags strung between the lamp tops.
	local flagColors = {
		Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 60),
		Color3.fromRGB(120, 220, 120), Color3.fromRGB(90, 160, 255),
		Color3.fromRGB(200, 120, 255),
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
	barn(buildings, Vector3.new(-45, 0, -178), Color3.fromRGB(200, 60, 60), Color3.fromRGB(90, 60, 35), 1)
	shop(buildings, Vector3.new(45, 0, -178), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 160, 255), 1)
	-- Houses flanking the conveyor, fronts facing the conveyor. At HS 2.5
	-- they sit at X ±27 so the shallower porches stop a stud short of the
	-- fences at X ±9; their Z span stays inside the gap between base rows.
	house(buildings, Vector3.new(-27, 0, -30), Color3.fromRGB(120, 220, 120), Color3.fromRGB(200, 60, 60), 1, 1)
	house(buildings, Vector3.new(27, 0, -30), Color3.fromRGB(90, 160, 255), Color3.fromRGB(255, 200, 60), -1, 2)
	house(buildings, Vector3.new(-27, 0, 30), Color3.fromRGB(200, 120, 255), Color3.fromRGB(90, 220, 210), 1, 3)
	house(buildings, Vector3.new(27, 0, 30), Color3.fromRGB(255, 140, 200), Color3.fromRGB(120, 220, 120), -1, 4)
	-- Smaller huts further down the conveyor.
	hut(buildings, Vector3.new(-20, 0, -90), Color3.fromRGB(255, 160, 80), Color3.fromRGB(90, 160, 255), 1, 1)
	hut(buildings, Vector3.new(20, 0, 90), Color3.fromRGB(140, 220, 255), Color3.fromRGB(200, 60, 60), -1, 2)
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
	house(buildings, Vector3.new(-85, 0, -170), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 160, 255), 1, 5)
	house(buildings, Vector3.new(85, 0, -170), Color3.fromRGB(120, 220, 120), Color3.fromRGB(200, 60, 60), -1, 6)
	shop(buildings, Vector3.new(-80, 0, -150), Color3.fromRGB(255, 140, 200), Color3.fromRGB(120, 220, 120), 2, "FISH SHOP")
	shop(buildings, Vector3.new(80, 0, -150), Color3.fromRGB(90, 220, 210), Color3.fromRGB(255, 200, 60), 3, "SNACK SHOP")
	hut(buildings, Vector3.new(-80, 0, 150), Color3.fromRGB(200, 120, 255), Color3.fromRGB(90, 220, 210), 1, 3)
	hut(buildings, Vector3.new(80, 0, 150), Color3.fromRGB(255, 200, 60), Color3.fromRGB(200, 60, 60), -1, 4)
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
	for _, g in ipairs({
		{ Vector3.new(-26, 0, -160), Color3.fromRGB(255, 90, 90) },
		{ Vector3.new(26, 0, -160), Color3.fromRGB(90, 160, 255) },
		{ Vector3.new(-26, 0, 172), Color3.fromRGB(255, 200, 60) },
		{ Vector3.new(26, 0, 172), Color3.fromRGB(120, 220, 120) },
		{ Vector3.new(-26, 0, 0), Color3.fromRGB(200, 120, 255) },
		{ Vector3.new(26, 0, 0), Color3.fromRGB(90, 220, 210) },
	}) do
		part("Goods", Vector3.new(1.5, 1.5, 1.5), g[2], g[1] + Vector3.new(0, 3.1, 0), props, Enum.Material.SmoothPlastic, false)
	end
	for _, spot in ipairs({ Vector3.new(-14, 0, -168), Vector3.new(14, 0, -168) }) do
		part("LampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(50, 50, 60), spot + Vector3.new(0, BEACH_TOP_Y + 3.5, 0), props)
		part("LampHead", Vector3.new(1.6, 1, 1.6), Color3.fromRGB(255, 240, 160), spot + Vector3.new(0, BEACH_TOP_Y + 7.4, 0), props, Enum.Material.Neon, false)
	end
	for _, s in ipairs({
		{ Vector3.new(-14, 0, -152), "MARKET" },
		{ Vector3.new(14, 0, 152), "FRESH BRAINROTS" },
	}) do
		local sp = s[1]
		for _, sx in ipairs({ -1, 1 }) do
			part("SignPost", Vector3.new(0.5, 6, 0.5), Color3.fromRGB(90, 60, 35), sp + Vector3.new(sx * 7, BEACH_TOP_Y + 3, 0), props, Enum.Material.Wood)
		end
		signBoard(props, sp + Vector3.new(0, BEACH_TOP_Y + 7, 0), s[2], Color3.fromRGB(255, 220, 80), Vector3.new(16, 4, 0.6))
	end

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
				local bob = math.abs(math.sin(t * 2 + w.phase)) * 0.25
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
			task.wait(0.1)
		end
	end)

	return bases
end

return WorldBuilder
