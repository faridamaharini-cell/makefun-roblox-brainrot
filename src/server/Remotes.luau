-- Remotes: creates the RemoteEvents once, on first require, so init and every
-- service share the same instances. Client waits for these by name.
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

Remotes.BuyNearest = getRemote("BuyNearest")
Remotes.LockBase = getRemote("LockBase")
Remotes.Rebirth = getRemote("Rebirth")
Remotes.Slap = getRemote("Slap")
Remotes.Notify = getRemote("Notify")

function Remotes.notify(player, message, kind)
	-- kind: "info" | "good" | "bad" | "wave"
	if player then
		Remotes.Notify:FireClient(player, message, kind or "info")
	else
		Remotes.Notify:FireAllClients(message, kind or "info")
	end
end

return Remotes
