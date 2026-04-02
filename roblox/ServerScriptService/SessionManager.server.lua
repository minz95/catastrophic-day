-- SessionManager.server.lua
-- Handles player join/leave, skin assignment, and per-player state.
-- Resolves: Issue #4

local Players             = game:GetService("Players")
local ServerStorage       = game:GetService("ServerStorage")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants    = require(ReplicatedStorage.Shared.Constants)
local RemoteEvents = require(ReplicatedStorage.RemoteEvents)
local GameManager  = require(ServerScriptService.GameManager)

-- ─── PlayerData store ─────────────────────────────────────────────────────────
-- PlayerData[userId] = {
--   skinIndex    : number,
--   inventory    : { itemName: string }[],
--   vehicleStats : table | nil,
--   vehicleModel : Model | nil,
--   raceProgress : number,     -- 0–1200 along track axis
--   raceRank     : number,
--   finishTime   : number | nil,
--   stealCooldownEnd     : number,  -- tick()
--   stealInvincibleEnd   : number,  -- tick()
-- }

local PlayerData = {}
SessionManager = {}

-- ─── Skin slot tracker ────────────────────────────────────────────────────────

local _takenSkins = {}   -- { [skinIndex] = userId }

local function _assignSkin(userId)
	for i = 1, Constants.SKIN_COUNT do
		if not _takenSkins[i] then
			_takenSkins[i] = userId
			return i
		end
	end
	return 1  -- fallback (shouldn't happen with MAX_PLAYERS ≤ SKIN_COUNT)
end

local function _freeSkin(userId)
	for i, uid in pairs(_takenSkins) do
		if uid == userId then
			_takenSkins[i] = nil
			return
		end
	end
end

-- ─── Public API ───────────────────────────────────────────────────────────────

function SessionManager.getData(player)
	return PlayerData[player.UserId]
end

function SessionManager.getAllData()
	return PlayerData
end

function SessionManager.setVehicle(player, model, stats)
	local d = PlayerData[player.UserId]
	if d then
		d.vehicleModel = model
		d.vehicleStats = stats
	end
end

function SessionManager.setRaceProgress(player, progress, rank)
	local d = PlayerData[player.UserId]
	if d then
		d.raceProgress = progress
		d.raceRank     = rank
	end
end

function SessionManager.setFinished(player, time)
	local d = PlayerData[player.UserId]
	if d then
		d.finishTime = time
	end
end

-- ─── Join handler ─────────────────────────────────────────────────────────────

local function _onPlayerAdded(player)
	local skinIndex = _assignSkin(player.UserId)

	PlayerData[player.UserId] = {
		skinIndex          = skinIndex,
		inventory          = {},
		vehicleStats       = nil,
		vehicleModel       = nil,
		raceProgress       = 0,
		raceRank           = 0,
		finishTime         = nil,
		stealCooldownEnd   = 0,
		stealInvincibleEnd = 0,
	}

	print(string.format("[SessionManager] %s joined → skin #%d", player.Name, skinIndex))

	-- If mid-game, send current phase immediately
	local phase = GameManager.getPhase()
	if phase ~= Constants.PHASES.LOBBY then
		RemoteEvents.PhaseChanged:FireClient(player, phase)
		local biome = GameManager.getBiome()
		if biome then
			RemoteEvents.BiomeSelected:FireClient(player, biome)
		end
	end
end

-- ─── Leave handler ────────────────────────────────────────────────────────────

local function _onPlayerRemoving(player)
	local data = PlayerData[player.UserId]
	if not data then return end

	-- Clean up vehicle model if racing
	if data.vehicleModel and data.vehicleModel.Parent then
		data.vehicleModel:Destroy()
		data.vehicleModel = nil
	end

	_freeSkin(player.UserId)
	PlayerData[player.UserId] = nil

	print(string.format("[SessionManager] %s left — data cleaned up", player.Name))
end

-- ─── Wire up ──────────────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(_onPlayerAdded)
Players.PlayerRemoving:Connect(_onPlayerRemoving)

-- Handle players already in game when script loads (Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(_onPlayerAdded, player)
end

return SessionManager
