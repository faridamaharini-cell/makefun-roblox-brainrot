-- Remotes: creates every RemoteEvent once, on first require, so init and
-- all services share the same instances. The client waits for these by name
-- under ReplicatedStorage/Remotes, so a name change here breaks the HUD.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

local Remotes = {}

local function getRemote(name)
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	return remote
end

-- Client -> server actions.
Remotes.BuyNearest = getRemote("BuyNearest")
Remotes.LockBase = getRemote("LockBase")
Remotes.Rebirth = getRemote("Rebirth")
Remotes.Slap = getRemote("Slap")
Remotes.ClaimQuest = getRemote("ClaimQuest")
Remotes.UpgradeBase = getRemote("UpgradeBase")
Remotes.GiftBrainrot = getRemote("GiftBrainrot")

-- Server -> client updates.
Remotes.Notify = getRemote("Notify")
Remotes.MoneyUpdate = getRemote("MoneyUpdate")
Remotes.QuestUpdate = getRemote("QuestUpdate")
Remotes.UpgradeUpdate = getRemote("UpgradeUpdate")
Remotes.EventUpdate = getRemote("EventUpdate")
Remotes.IndexUpdate = getRemote("IndexUpdate")

-- kind: "info" | "good" | "bad" | "wave" | "event". A nil player broadcasts.
function Remotes.notify(player, message, kind)
	if player then
		Remotes.Notify:FireClient(player, message, kind or "info")
	else
		Remotes.Notify:FireAllClients(message, kind or "info")
	end
end

return Remotes
