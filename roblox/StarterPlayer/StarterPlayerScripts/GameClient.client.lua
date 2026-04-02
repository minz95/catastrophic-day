-- GameClient.client.lua
-- Central client orchestrator. Listens to PhaseChanged and routes
-- show/hide + enable/disable to all sub-modules.
-- Resolves: Issue #35, #38

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants    = require(ReplicatedStorage.Shared.Constants)
local RemoteEvents = require(ReplicatedStorage.RemoteEvents)

local LocalPlayer = Players.LocalPlayer

-- Lazy-load sub-modules (they may not all exist yet during dev)
local function safeRequire(path)
	local ok, mod = pcall(require, path)
	return ok and mod or nil
end

local Scripts = LocalPlayer:WaitForChild("PlayerScripts")

local FarmingClient  = safeRequire(Scripts:WaitForChild("FarmingClient",  5))
local CraftingClient = safeRequire(Scripts:WaitForChild("CraftingClient", 5))
local RacingClient   = safeRequire(Scripts:WaitForChild("RacingClient",   5))
local UIManager      = safeRequire(Scripts:WaitForChild("Modules", 5)
	and Scripts.Modules:WaitForChild("UIManager", 5))
local CameraController = safeRequire(Scripts:WaitForChild("Modules", 5)
	and Scripts.Modules:WaitForChild("CameraController", 5))

-- ─── Phase routing table ──────────────────────────────────────────────────────

local phaseHandlers = {
	[Constants.PHASES.LOBBY] = function()
		if UIManager       then UIManager.showOnly("LobbyUI")     end
		if FarmingClient   then FarmingClient.disable()           end
		if CraftingClient  then CraftingClient.disable()          end
		if RacingClient    then RacingClient.disable()            end
		if CameraController then CameraController.setMode("lobby") end
	end,

	[Constants.PHASES.FARMING] = function()
		if UIManager       then UIManager.showOnly("FarmingUI")   end
		if FarmingClient   then FarmingClient.enable()            end
		if CraftingClient  then CraftingClient.disable()          end
		if RacingClient    then RacingClient.disable()            end
		if CameraController then CameraController.setMode("farming") end
	end,

	[Constants.PHASES.CRAFTING] = function()
		if UIManager       then UIManager.showOnly("CraftingUI")  end
		if FarmingClient   then FarmingClient.disable()           end
		if CraftingClient  then CraftingClient.enable()           end
		if RacingClient    then RacingClient.disable()            end
		if CameraController then CameraController.setMode("crafting") end
	end,

	[Constants.PHASES.RACING] = function()
		if UIManager       then UIManager.showOnly("HUD", "AbilityUI") end
		if FarmingClient   then FarmingClient.disable()           end
		if CraftingClient  then CraftingClient.disable()          end
		if RacingClient    then RacingClient.enable()             end
		if CameraController then CameraController.setMode("racing") end
	end,

	[Constants.PHASES.RESULTS] = function()
		if UIManager       then UIManager.showOnly("ResultsUI")   end
		if RacingClient    then RacingClient.disable()            end
		if CameraController then CameraController.setMode("results") end
	end,
}

-- ─── Wire up ──────────────────────────────────────────────────────────────────

RemoteEvents.PhaseChanged.OnClientEvent:Connect(function(phase)
	local handler = phaseHandlers[phase]
	if handler then
		handler()
	else
		warn("[GameClient] Unknown phase:", phase)
	end
end)

RemoteEvents.BiomeSelected.OnClientEvent:Connect(function(biome)
	if UIManager then UIManager.applyBiomeTheme(biome) end
end)

-- ─── Boot into LOBBY by default ───────────────────────────────────────────────

local handler = phaseHandlers[Constants.PHASES.LOBBY]
if handler then handler() end
