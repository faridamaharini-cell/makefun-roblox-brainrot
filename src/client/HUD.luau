-- Brainrot Bay HUD.
-- Builds the whole interface in code as a single ScreenGui: money and
-- income top-right (clear of the top-left Roblox menu buttons), the quest
-- tracker on the left, the event banner top-centre, toasts underneath it,
-- a context line bottom-centre, upgrade buttons bottom-right, and the
-- controls reminder bottom-left. All text is large and TextScaled so it
-- stays readable when the game is shown scaled down in a thumbnail or
-- on a small screen.
-- The module keeps the built instances internally; Game.client.luau calls
-- the setters below as server RemoteEvents arrive.

local HUD = {}

local gui = nil
local moneyLabel = nil
local incomeLabel = nil
local rebirthsLabel = nil
local questTitleLabel = nil
local questBarFill = nil
local questProgressLabel = nil
local eventBanner = nil
local eventLabel = nil
local toastList = nil
local contextLabel = nil

HUD.claimButton = nil
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

	-- Money panel, top-right, clear of the top-left menu buttons.
	local moneyFrame = makePanel(
		"MoneyFrame",
		gui,
		UDim2.new(0, 330, 0, 148),
		UDim2.new(1, -346, 0, 12),
		Color3.fromRGB(18, 24, 40),
		0.15
	)
	makeLabel("TitleLabel", moneyFrame, "BRAINROT BAY", UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 6), 22, Color3.fromRGB(255, 215, 80))
	moneyLabel = makeLabel("MoneyLabel", moneyFrame, "$100", UDim2.new(1, -16, 0, 48), UDim2.new(0, 8, 0, 32), 40, Color3.fromRGB(120, 255, 140))
	incomeLabel = makeLabel("IncomeLabel", moneyFrame, "+$0/s", UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 84), 24, Color3.fromRGB(255, 220, 90))
	rebirthsLabel = makeLabel("RebirthsLabel", moneyFrame, "Rebirths: 0  •  x1 income", UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 114), 22, Color3.fromRGB(140, 220, 255))

	-- Event banner, top-centre, hidden until an event is live.
	eventBanner = makePanel(
		"EventBanner",
		gui,
		UDim2.new(0, 620, 0, 56),
		UDim2.new(0.5, -310, 0, 12),
		Color3.fromRGB(20, 60, 120),
		0.1
	)
	eventBanner.Visible = false
	eventLabel = makeLabel("EventLabel", eventBanner, "", UDim2.new(1, -16, 1, -8), UDim2.new(0, 8, 0, 4), 30, Color3.fromRGB(255, 255, 255))

	-- Toast stack under the banner; newest toast lands at the bottom.
	toastList = Instance.new("Frame")
	toastList.Name = "ToastList"
	toastList.AnchorPoint = Vector2.new(0.5, 0)
	toastList.Position = UDim2.new(0.5, 0, 0, 78)
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
	makeLabel("QuestHeader", questFrame, "QUEST", UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 8), 20, Color3.fromRGB(255, 215, 80))
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
		"Move: WASD / Arrows  •  E: Buy  •  F: Slap  •  L: Lock  •  R: Rebirth  •  Q: Quest  •  G: Gift",
		UDim2.new(0, 620, 0, 28),
		UDim2.new(0, 16, 1, -40),
		18,
		Color3.fromRGB(230, 230, 230)
	)

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

-- Rebirth count; the multiplier shown is x2 per rebirth.
function HUD.setRebirths(count)
	if rebirthsLabel then
		local n = math.floor(count or 0)
		rebirthsLabel.Text = "Rebirths: " .. tostring(n) .. "  •  x" .. tostring(2 ^ n) .. " income"
	end
end

-- Quest tracker: title, progress bar, counter, and the claim button state.
function HUD.setQuest(title, progress, target, claimed)
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
