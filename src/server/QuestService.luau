-- QuestService: tracks quest progress on buy / earn / steal / survive /
-- rebirth / gift events and pays the reward once per quest through the
-- ClaimQuest remote. Definitions live in Shared.Quests; this module only
-- counts progress and pays out, so client and server can never disagree.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Quests = require(Shared:WaitForChild("Quests"))
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)

local QuestService = {}

local questList = Quests.Quests or {}

local function progressEntry(data, questId)
	local entry = data.quests[questId]
	if not entry then
		entry = { progress = 0, claimed = false }
		data.quests[questId] = entry
	end
	return entry
end

-- Add `amount` of progress to every quest of `kind` for this player.
-- QuestUpdate fires when a quest completes, or on any non-"earn" event
-- (buy/steal/survive/rebirth/gift are rare); per-second "earn" progress
-- only fires on completion so the tick stays quiet on the network.
function QuestService.addProgress(player, kind, amount)
	local data = State.getPlayer(player)
	if not data then
		return
	end
	local fireUpdate = kind ~= "earn"
	for _, quest in ipairs(questList) do
		if quest.kind == kind then
			local entry = progressEntry(data, quest.id)
			if not entry.claimed and entry.progress < quest.target then
				entry.progress = math.min(quest.target, entry.progress + amount)
				if entry.progress >= quest.target then
					fireUpdate = true
					Remotes.notify(player, "Quest complete: " .. quest.title .. "! Claim your reward from the quest board.", "good")
				end
			end
		end
	end
	if fireUpdate then
		Remotes.QuestUpdate:FireClient(player, data.quests)
	end
end

function QuestService.claimQuest(player, questId)
	local data = State.getPlayer(player)
	if not data then
		return false
	end
	local quest = Quests.getQuest and Quests.getQuest(questId) or nil
	if not quest then
		for _, q in ipairs(questList) do
			if q.id == questId then
				quest = q
				break
			end
		end
	end
	if not quest then
		Remotes.notify(player, "Unknown quest.", "bad")
		return false
	end
	local entry = progressEntry(data, quest.id)
	if entry.claimed then
		Remotes.notify(player, "You already claimed " .. quest.title .. ".", "bad")
		return false
	end
	if entry.progress < quest.target then
		Remotes.notify(player, quest.title .. ": " .. math.floor(entry.progress) .. "/" .. quest.target .. " — not done yet!", "bad")
		return false
	end
	entry.claimed = true
	data.money += quest.reward
	Remotes.QuestUpdate:FireClient(player, data.quests)
	Remotes.MoneyUpdate:FireClient(player, math.floor(data.money), State.incomePerSecond(player))
	Remotes.notify(player, "Quest reward: +" .. quest.reward .. " for " .. quest.title .. "!", "good")
	return true
end

-- Send the player's whole quest board (used when they join).
function QuestService.sendBoard(player)
	local data = State.getPlayer(player)
	if not data then
		return
	end
	for _, quest in ipairs(questList) do
		progressEntry(data, quest.id)
	end
	Remotes.QuestUpdate:FireClient(player, data.quests)
end

function QuestService.start()
	Remotes.ClaimQuest.OnServerEvent:Connect(function(player, questId)
		QuestService.claimQuest(player, questId)
	end)
end

return QuestService
