-- ItemModelPreloader.server.lua
-- Pre-builds all item 3D models into ServerStorage at game start.
-- Priority: ServerStorage.ItemMeshes (Blender FBX imported in Studio) → procedural Part build.
--
-- To activate a Blender FBX model for an item:
--   1. In Roblox Studio: File → Import 3D → select assets/items/<item>.fbx
--   2. Rename the imported Model to the exact item name (e.g. "Barrel")
--   3. Drag it into ServerStorage.ItemMeshes
--   The preloader will automatically use it on next server start.
-- Resolves: Issue #93

local ServerStorage       = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ItemTypes           = require(game.ReplicatedStorage.Shared.ItemTypes)
local ItemModelBuilder    = require(ServerScriptService.Modules.ItemModelBuilder)

-- ItemMeshes: optional folder populated with Blender-imported Models
local meshesFolder = ServerStorage:FindFirstChild("ItemMeshes")

-- Recreate ItemModels folder
local folder = ServerStorage:FindFirstChild("ItemModels")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name   = "ItemModels"
folder.Parent = ServerStorage

local blenderCount    = 0
local proceduralCount = 0

for _, item in ipairs(ItemTypes.ALL) do
	local name = item.name

	-- 1. Try Blender-imported mesh from ItemMeshes
	if meshesFolder then
		local mesh = meshesFolder:FindFirstChild(name)
		if mesh then
			local clone = mesh:Clone()
			clone.Name   = name
			clone.Parent = folder
			blenderCount = blenderCount + 1
			continue
		end
	end

	-- 2. Fall back to procedural Part model
	local ok, err = pcall(function()
		ItemModelBuilder.build(name, folder)
	end)
	if ok then
		proceduralCount = proceduralCount + 1
	else
		warn("[ItemModelPreloader] Failed to build " .. name .. ": " .. tostring(err))
	end
end

print(string.format("[ItemModelPreloader] Ready: %d Blender mesh, %d procedural",
	blenderCount, proceduralCount))
