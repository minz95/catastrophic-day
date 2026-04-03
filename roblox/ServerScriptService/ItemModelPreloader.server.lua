-- ItemModelPreloader.server.lua
-- Pre-builds all 37 item 3D models into ServerStorage at game start.
-- FarmingManager clones from here instead of building per-spawn.

local ServerStorage   = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemModelBuilder = require(ServerScriptService.Modules.ItemModelBuilder)

-- Create or clear the item models folder
local folder = ServerStorage:FindFirstChild("ItemModels")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name   = "ItemModels"
folder.Parent = ServerStorage

ItemModelBuilder.preloadAll(folder)
