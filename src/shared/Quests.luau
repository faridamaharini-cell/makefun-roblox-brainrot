-- Quests: the Brainrot Bay quest board.
-- Each quest is one row: a stable id, a title and description for the UI,
-- a `kind` the server tracks ("buy", "earn", "steal", "survive", "rebirth",
-- "gift"), a numeric `target` for progress, and a cash `reward` paid once
-- when the target is reached. Progress is counted by the server; this module
-- only owns the definitions, so client and server can never disagree on
-- what a quest asks for or pays.

local Quests = {}

Quests.Quests = {
	{
		id = "first-catch",
		title = "First Catch",
		desc = "Buy your first brainrot off the conveyor.",
		kind = "buy",
		target = 1,
		reward = 250,
	},
	{
		id = "collector",
		title = "Bay Collector",
		desc = "Buy 3 brainrots for your base.",
		kind = "buy",
		target = 3,
		reward = 500,
	},
	{
		id = "bay-tycoon",
		title = "Bay Tycoon",
		desc = "Earn $10,000 from your brainrots.",
		kind = "earn",
		target = 10000,
		reward = 1500,
	},
	{
		id = "bay-mogul",
		title = "Bay Mogul",
		desc = "Earn $100,000 from your brainrots.",
		kind = "earn",
		target = 100000,
		reward = 8000,
	},
	{
		id = "sneaky-thief",
		title = "Sneaky Thief",
		desc = "Steal 1 brainrot from another player's base.",
		kind = "steal",
		target = 1,
		reward = 2000,
	},
	{
		id = "wave-survivor",
		title = "Wave Survivor",
		desc = "Survive 1 tsunami wave.",
		kind = "survive",
		target = 1,
		reward = 1000,
	},
	{
		id = "reborn-bay",
		title = "Reborn in the Bay",
		desc = "Rebirth once to double all your income.",
		kind = "rebirth",
		target = 1,
		reward = 10000,
	},
	{
		id = "generous-bay",
		title = "Generous Bay",
		desc = "Gift 1 brainrot to another player.",
		kind = "gift",
		target = 1,
		reward = 1500,
	},
}

local questById = {}
for _, quest in ipairs(Quests.Quests) do
	questById[quest.id] = quest
end

function Quests.getQuest(id)
	return questById[id]
end

-- All quests of one kind, in board order.
function Quests.questsForKind(kind)
	local out = {}
	for _, quest in ipairs(Quests.Quests) do
		if quest.kind == kind then
			table.insert(out, quest)
		end
	end
	return out
end

return Quests
