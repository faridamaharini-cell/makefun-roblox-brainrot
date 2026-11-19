-- Brainrot Bay HUD.
-- Builds the whole interface in code as a single ScreenGui: money and
-- income TOP-CENTRE and large (clear of the top-left Roblox menu buttons),
-- the GOALS ladder on the left, the event banner below the money panel,
-- toasts underneath the banner, the Baydex index panel (B key / button),
-- a context line bottom-centre, upgrade buttons bottom-right, and the
-- controls reminder bottom-left. All text is large and TextScaled so it
-- stays readable when the game is shown scaled down in a thumbnail or
-- on a small screen.
-- The module keeps the built instances internally; Game.client.luau calls
-- the setters below as server RemoteEvents arrive.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))

local HUD = {}

local gui = nil
local moneyLabel = nil
local incomeLabel = nil
local rebirthsLabel = nil
local questHeaderLabel = nil
local questTitleLabel = nil
local questBarFill = nil
local questProgressLabel = nil
local eventBanner = nil
local eventLabel = nil
local toastList = nil
local contextLabel = nil
local indexFrame = nil
local indexHeaderLabel = nil
local indexList = nil
local foundSet = {}

HUD.claimButton = nil
HUD.indexButton = nil
HUD.upgradeButtons = {}

-- Level-0 costs from Shared.Economy.upgradeCost(kind, 0): capacity
-- $1,000, income $2,500, lock $800. Game.client.luau overwrites these
-- from Economy right after build; these are only the pre-wiring values.
local upgradeCosts = { capacity = 1000, income = 2500, lock = 800 }
local upgradeButtonLabels = {
	capacity = "Capacity",
	income = "Income",
	lock = "Lock Base",
}

local function formatMoney(amount)
	amount = math.floor(amount or 0)
	if amount >= 1000000 then
		return string.format("$%.2fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(amount)
	end
end

local function makeLabel(name, parent, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextWrapped = true
	label.Parent = parent
	local sizeGuard = Instance.new("UITextSizeConstraint")
	sizeGuard.MinTextSize = 14
	sizeGuard.MaxTextSize = textSize or 28
	sizeGuard.Parent = label
	return label
end

local function makeButton(name, parent, text, size, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.TextStrokeTransparency = 0
	button.AutoButtonColor = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	local sizeGuard = Instance.new("UITextSizeConstraint")
	sizeGuard.MinTextSize = 14
	sizeGuard.MaxTextSize = 24
	sizeGuard.Parent = button
	return button
end

local function makePanel(name, parent, size, position, color, transparency)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = position
	panel.BackgroundColor3 = color
	panel.BackgroundTransparency = transparency or 0.2
	panel.BorderSizePixel = 0
	panel.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	return panel
end

local function refreshUpgradeButton(kind)
	local button = HUD.upgradeButtons[kind]
	if not button then
		return
	end
	local cost = upgradeCosts[kind] or 0
	if cost <= 0 then
		button.Text = upgradeButtonLabels[kind] .. "  •  MAX"
	else
		button.Text = upgradeButtonLabels[kind] .. "  •  " .. formatMoney(cost)
	end
end

-- Build the interface once for this player. Returns the module so callers
-- can chain HUD.build(player) and then use the setters.
function HUD.build(player)
	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotBayGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Money panel, TOP-CENTRE and large so it reads at thumbnail scale,
	-- clear of the top-left Roblox menu buttons. The event banner sits
	-- below it (see below) so the two never overlap.
	local moneyFrame = makePanel(
		"MoneyFrame",
		gui,
		UDim2.new(0, 460, 0, 180),
		UDim2.new(0.5, 0, 0, 8),
		Color3.fromRGB(18, 24, 40),
		0.15
	)
	moneyFrame.AnchorPoint = Vector2.new(0.5, 0)
	makeLabel("TitleLabel", moneyFrame, "BRAINROT BAY", UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 6), 24, Color3.fromRGB(255, 215, 80))
	moneyLabel = makeLabel("MoneyLabel", moneyFrame, "$100", UDim2.new(1, -16, 0, 56), UDim2.new(0, 8, 0, 34), 56, Color3.fromRGB(120, 255, 140))
	incomeLabel = makeLabel("IncomeLabel", moneyFrame, "+$0/s", UDim2.new(1, -16, 0, 32), UDim2.new(0, 8, 0, 94), 30, Color3.fromRGB(255, 220, 90))
	rebirthsLabel = makeLabel("RebirthsLabel", moneyFrame, "Rebirths: 0  •  x1 income", UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 130), 24, Color3.fromRGB(140, 220, 255))

	-- Baydex button, LEFT side under the quest frame (quest frame is at
	-- (16,148), 340x168, so it ends at y=316; y=324 clears it). Left
	-- side keeps it clear of the centred event banner (y 198-254) at
	-- every viewport width, including narrow ones.
	HUD.indexButton = makeButton("BaydexButton", gui, "Baydex (B)", UDim2.new(0, 160, 0, 44), UDim2.new(0, 16, 0, 324), Color3.fromRGB(40, 90, 160))

	-- Event banner, below the money panel, hidden until an event is live.
	eventBanner = makePanel(
		"EventBanner",
		gui,
		UDim2.new(0, 620, 0, 56),
		UDim2.new(0.5, -310, 0, 198),
		Color3.fromRGB(20, 60, 120),
		0.1
	)
	eventBanner.Visible = false
	eventLabel = makeLabel("EventLabel", eventBanner, "", UDim2.new(1, -16, 1, -8), UDim2.new(0, 8, 0, 4), 30, Color3.fromRGB(255, 255, 255))

	-- Toast stack under the banner; newest toast lands at the bottom.
	toastList = Instance.new("Frame")
	toastList.Name = "ToastList"
	toastList.AnchorPoint = Vector2.new(0.5, 0)
	toastList.Position = UDim2.new(0.5, 0, 0, 262)
	toastList.Size = UDim2.new(0, 660, 0, 190)
	toastList.BackgroundTransparency = 1
	toastList.Parent = gui
	local toastLayout = Instance.new("UIListLayout")
	toastLayout.FillDirection = Enum.FillDirection.Vertical
	toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	toastLayout.Padding = UDim.new(0, 6)
	toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
	toastLayout.Parent = toastList

	-- Quest tracker panel, left side, below the Roblox menu buttons.
	local questFrame = makePanel(
		"QuestFrame",
		gui,
		UDim2.new(0, 340, 0, 168),
		UDim2.new(0, 16, 0, 148),
		Color3.fromRGB(18, 24, 40),
		0.15
	)
	makeLabel("QuestHeader", questFrame, "GOALS", UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 8), 20, Color3.fromRGB(255, 215, 80))
	questHeaderLabel = questFrame:FindFirstChild("QuestHeader")
	questTitleLabel = makeLabel("QuestTitle", questFrame, "No quest yet", UDim2.new(1, -16, 0, 44), UDim2.new(0, 8, 0, 34), 24, Color3.fromRGB(255, 255, 255))
	local barBack = Instance.new("Frame")
	barBack.Name = "QuestBarBack"
	barBack.Size = UDim2.new(1, -16, 0, 22)
	barBack.Position = UDim2.new(0, 8, 0, 84)
	barBack.BackgroundColor3 = Color3.fromRGB(60, 64, 80)
	barBack.BorderSizePixel = 0
	barBack.Parent = questFrame
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 11)
	barCorner.Parent = barBack
	questBarFill = Instance.new("Frame")
	questBarFill.Name = "QuestBarFill"
	questBarFill.Size = UDim2.new(0, 0, 1, 0)
	questBarFill.Position = UDim2.new(0, 0, 0, 0)
	questBarFill.BackgroundColor3 = Color3.fromRGB(120, 255, 140)
	questBarFill.BorderSizePixel = 0
	questBarFill.Parent = barBack
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 11)
	fillCorner.Parent = questBarFill
	questProgressLabel = makeLabel("QuestProgress", questFrame, "0 / 0", UDim2.new(0, 168, 0, 122), UDim2.new(0, 8, 0, 110), 22, Color3.fromRGB(230, 230, 230))
	questProgressLabel.Size = UDim2.new(0, 156, 0, 32)
	HUD.claimButton = makeButton("ClaimButton", questFrame, "Claim (Q)", UDim2.new(0, 150, 0, 44), UDim2.new(0, 8, 0, 116), Color3.fromRGB(70, 70, 85))

	-- Context line: what to do with the nearest brainrot, bottom-centre.
	contextLabel = makeLabel(
		"ContextLabel",
		gui,
		"Walk up to a brainrot on the conveyor — press E to buy it!",
		UDim2.new(0, 720, 0, 38),
		UDim2.new(0.5, -360, 1, -108),
		22,
		Color3.fromRGB(255, 255, 255)
	)
	contextLabel.AnchorPoint = Vector2.new(0.5, 0)

	-- Upgrade buttons, bottom-right, stacked above the bottom edge.
	local upgradeColors = {
		capacity = Color3.fromRGB(50, 140, 90),
		income = Color3.fromRGB(200, 140, 30),
		lock = Color3.fromRGB(60, 110, 220),
	}
	local upgradeOrder = { "capacity", "income", "lock" }
	for i, kind in ipairs(upgradeOrder) do
		local button = makeButton(
			"Upgrade" .. kind:sub(1, 1):upper() .. kind:sub(2) .. "Button",
			gui,
			"",
			UDim2.new(0, 260, 0, 52),
			UDim2.new(1, -276, 1, -64 - (i - 1) * 60),
			upgradeColors[kind]
		)
		HUD.upgradeButtons[kind] = button
		refreshUpgradeButton(kind)
	end

	-- Controls reminder, bottom-left.
	makeLabel(
		"HelpLabel",
		gui,
		"Move: WASD / Arrows  •  E: Buy  •  F: Slap  •  L: Lock  •  R: Rebirth  •  Q: Quest  •  G: Gift  •  B: Baydex",
		UDim2.new(0, 780, 0, 28),
		UDim2.new(0, 16, 1, -40),
		18,
		Color3.fromRGB(230, 230, 230)
	)

	-- Baydex (Brainrot Index) panel, centre screen, hidden until opened
	-- with B or the Baydex button. One row per character in BrainrotData
	-- order; found rows show name, rarity colour, flavor and price/income,
	-- unfound rows show only "???" in grey with the rarity colour.
	indexFrame = makePanel(
		"BaydexFrame",
		gui,
		UDim2.new(0, 560, 0, 520),
		UDim2.new(0.5, -280, 0.5, -260),
		Color3.fromRGB(18, 24, 40),
		0.05
	)
	indexFrame.Visible = false
	indexHeaderLabel = makeLabel("BaydexHeader", indexFrame, "BAYDEX — 0/32 FOUND", UDim2.new(1, -70, 0, 30), UDim2.new(0, 12, 0, 8), 24, Color3.fromRGB(255, 215, 80))
	local closeButton = makeButton("BaydexCloseButton", indexFrame, "X", UDim2.new(0, 44, 0, 36), UDim2.new(1, -56, 0, 6), Color3.fromRGB(180, 60, 60))
	closeButton.MouseButton1Click:Connect(function()
		HUD.toggleIndex()
	end)
	indexList = Instance.new("ScrollingFrame")
	indexList.Name = "BaydexList"
	indexList.Size = UDim2.new(1, -16, 1, -56)
	indexList.Position = UDim2.new(0, 8, 0, 46)
	indexList.BackgroundTransparency = 1
	indexList.BorderSizePixel = 0
	indexList.ScrollBarThickness = 6
	indexList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	indexList.CanvasSize = UDim2.new(0, 0, 0, 0)
	indexList.Parent = indexFrame
	local indexLayout = Instance.new("UIListLayout")
	indexLayout.FillDirection = Enum.FillDirection.Vertical
	indexLayout.Padding = UDim.new(0, 4)
	indexLayout.SortOrder = Enum.SortOrder.LayoutOrder
	indexLayout.Parent = indexList
	HUD.rebuildIndex()

	return HUD
end

-- Money readout from the server (MoneyUpdate remote).
function HUD.setMoney(money, incomePerSecond)
	if moneyLabel then
		moneyLabel.Text = formatMoney(money)
	end
	if incomeLabel then
		incomeLabel.Text = "+" .. formatMoney(incomePerSecond) .. "/s"
	end
end

-- Rebirth count; the multiplier shown is x2 per rebirth. From the first
-- rebirth on, the line reads POSEIDON TIER instead of "Rebirths".
function HUD.setRebirths(count)
	if rebirthsLabel then
		local n = math.floor(count or 0)
		if n >= 1 then
			rebirthsLabel.Text = "POSEIDON TIER  •  x" .. tostring(2 ^ n) .. " income"
		else
			rebirthsLabel.Text = "Rebirths: 0  •  x1 income"
		end
	end
end

-- GOALS ladder: title, progress bar, counter, and the claim button state.
-- boardIndex is the current goal's 1-based position on the 8-goal board
-- (nil when every goal is done); the header shows NEXT GOAL n/8, or
-- GOALS — 8/8 COMPLETE when the ladder is finished.
function HUD.setQuest(title, progress, target, claimed, boardIndex, totalGoals)
	local total = math.max(math.floor(totalGoals or 8), 1)
	if questHeaderLabel then
		if boardIndex == nil then
			questHeaderLabel.Text = "GOALS — " .. total .. "/" .. total .. " COMPLETE"
		else
			questHeaderLabel.Text = "GOALS — NEXT GOAL " .. tostring(boardIndex) .. "/" .. total
		end
	end
	if questTitleLabel then
		questTitleLabel.Text = title or "No quest yet"
	end
	local safeTarget = math.max(tonumber(target) or 0, 1)
	local safeProgress = math.clamp(tonumber(progress) or 0, 0, safeTarget)
	if questBarFill then
		questBarFill.Size = UDim2.new(safeProgress / safeTarget, 0, 1, 0)
	end
	if questProgressLabel then
		questProgressLabel.Text = tostring(math.floor(safeProgress)) .. " / " .. tostring(math.floor(safeTarget))
	end
	if HUD.claimButton then
		if claimed then
			HUD.claimButton.Text = "Claimed"
			HUD.claimButton.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
			HUD.claimButton.Active = false
		elseif safeProgress >= safeTarget then
			HUD.claimButton.Text = "CLAIM! (Q)"
			HUD.claimButton.BackgroundColor3 = Color3.fromRGB(220, 170, 20)
			HUD.claimButton.Active = true
		else
			HUD.claimButton.Text = "Claim (Q)"
			HUD.claimButton.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
			HUD.claimButton.Active = true
		end
	end
end

-- Baydex: rebuild the row list from foundSet. Found rows show the name,
-- rarity colour, flavor line and price/income; unfound rows show "???"
-- in grey with only the rarity colour (no name, no flavor, no price).
function HUD.rebuildIndex()
	if not indexList or not indexHeaderLabel then
		return
	end
	for _, child in ipairs(indexList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local foundCount = 0
	for _, character in ipairs(BrainrotData.Characters) do
		local found = foundSet[character.id] == true
		if found then
			foundCount += 1
		end
		local rarity = BrainrotData.getRarity(character.rarity)
		local row = Instance.new("Frame")
		row.Name = "Row_" .. character.id
		row.Size = UDim2.new(1, -6, 0, 58)
		row.BackgroundColor3 = Color3.fromRGB(30, 36, 56)
		row.BorderSizePixel = 0
		row.Parent = indexList
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row
		local stripe = Instance.new("Frame")
		stripe.Name = "RarityStripe"
		stripe.Size = UDim2.new(0, 8, 1, 0)
		stripe.Position = UDim2.new(0, 0, 0, 0)
		stripe.BackgroundColor3 = rarity.color
		stripe.BorderSizePixel = 0
		stripe.Parent = row
		if found then
			makeLabel("RowName", row, character.name, UDim2.new(1, -170, 0, 24), UDim2.new(0, 18, 0, 2), 20, Color3.fromRGB(255, 255, 255))
			makeLabel("RowRarity", row, character.rarity, UDim2.new(0, 140, 0, 24), UDim2.new(1, -150, 0, 2), 20, rarity.color)
			makeLabel("RowFlavor", row, character.flavor or "", UDim2.new(1, -170, 0, 24), UDim2.new(0, 18, 0, 28), 18, Color3.fromRGB(200, 205, 220))
			makeLabel("RowStats", row, BrainrotData.formatMoney(character.price) .. "  •  " .. BrainrotData.formatMoney(character.income) .. "/s", UDim2.new(0, 140, 0, 24), UDim2.new(1, -150, 0, 28), 18, Color3.fromRGB(120, 255, 140))
		else
			makeLabel("RowName", row, "???", UDim2.new(1, -170, 0, 24), UDim2.new(0, 18, 0, 2), 20, Color3.fromRGB(150, 150, 150))
			makeLabel("RowRarity", row, character.rarity, UDim2.new(0, 140, 0, 24), UDim2.new(1, -150, 0, 2), 20, rarity.color)
		end
	end
	indexHeaderLabel.Text = "BAYDEX — " .. tostring(foundCount) .. "/" .. tostring(#BrainrotData.Characters) .. " FOUND"
end

-- New found set from the server (IndexUpdate remote); rebuilds the panel.
function HUD.setIndex(found)
	if typeof(found) == "table" then
		foundSet = found
	else
		foundSet = {}
	end
	HUD.rebuildIndex()
end

-- Show / hide the Baydex panel.
function HUD.toggleIndex()
	if indexFrame then
		indexFrame.Visible = not indexFrame.Visible
	end
end

-- Event banner. Pass nil or "" to hide it. kind: "wave" | "event" | "info".
function HUD.setEvent(text, kind)
	if not eventBanner or not eventLabel then
		return
	end
	if text == nil or text == "" then
		eventBanner.Visible = false
		return
	end
	eventLabel.Text = text
	if kind == "wave" then
		eventBanner.BackgroundColor3 = Color3.fromRGB(20, 60, 120)
		eventLabel.TextColor3 = Color3.fromRGB(160, 210, 255)
	elseif kind == "event" then
		eventBanner.BackgroundColor3 = Color3.fromRGB(120, 80, 10)
		eventLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
	else
		eventBanner.BackgroundColor3 = Color3.fromRGB(18, 24, 40)
		eventLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	eventBanner.Visible = true
end

-- A toast line in the stack; it removes itself after four seconds.
-- kind: "info" | "good" | "bad" | "wave" | "event".
function HUD.toast(message, kind)
	if not toastList then
		return
	end
	-- Cap the stack at four toasts. Count only the toast labels: the
	-- UIListLayout is a child too, and counting it would evict a toast
	-- while only three are showing.
	local toastCount = 0
	for _, child in ipairs(toastList:GetChildren()) do
		if child:IsA("TextLabel") then
			toastCount += 1
		end
	end
	while toastCount >= 4 do
		for _, child in ipairs(toastList:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
				toastCount -= 1
				break
			end
		end
	end
	local color = Color3.fromRGB(255, 255, 255)
	if kind == "good" then
		color = Color3.fromRGB(120, 255, 140)
	elseif kind == "bad" then
		color = Color3.fromRGB(255, 110, 110)
	elseif kind == "wave" then
		color = Color3.fromRGB(140, 200, 255)
	elseif kind == "event" then
		color = Color3.fromRGB(255, 220, 90)
	end
	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.Size = UDim2.new(1, 0, 0, 34)
	toast.BackgroundTransparency = 1
	toast.Text = message or ""
	toast.TextColor3 = color
	toast.TextScaled = true
	toast.Font = Enum.Font.GothamBold
	toast.TextStrokeTransparency = 0
	toast.TextWrapped = true
	toast.Parent = toastList
	local sizeGuard = Instance.new("UITextSizeConstraint")
	sizeGuard.MinTextSize = 16
	sizeGuard.MaxTextSize = 24
	sizeGuard.Parent = toast
	task.delay(4, function()
		if toast.Parent then
			toast:Destroy()
		end
	end)
end

-- The bottom-centre hint line ("Press E to buy", ...).
function HUD.setContext(text)
	if contextLabel then
		contextLabel.Text = text or ""
	end
end

-- Costs shown on the three upgrade buttons. Accepts a table like
-- { capacity = 1000, income = 2500, lock = 800 }; missing keys keep their
-- current value, and a cost of 0 means that kind is at max level (MAX).
function HUD.setUpgradeCosts(costs)
	if typeof(costs) ~= "table" then
		return
	end
	for kind, value in pairs(costs) do
		if upgradeCosts[kind] ~= nil and typeof(value) == "number" then
			upgradeCosts[kind] = value
			refreshUpgradeButton(kind)
		end
	end
end

return HUD
