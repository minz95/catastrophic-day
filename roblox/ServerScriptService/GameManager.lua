-- GameManager.server.lua
-- Master phase state machine. Single authority over all phase transitions.
-- All other server managers listen to _phaseChanged BindableEvent
-- or subscribe via GameManager.onPhaseChanged().
-- Resolves: Issue #3

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants     = require(ReplicatedStorage.Shared.Constants)
local RemoteEvents  = require(ReplicatedStorage.RemoteEvents)
local BiomeConfig   = require(ServerScriptService.Modules.BiomeConfig)

local GameManager = {}

-- ─── Internal state ───────────────────────────────────────────────────────────

local _currentPhase  = Constants.PHASES.LOBBY
local _currentBiome  = nil
local _phaseTimer    = nil   -- active task.delay handle
local _callbacks     = {}    -- registered via onPhaseChanged()

-- ─── Public API ───────────────────────────────────────────────────────────────

function GameManager.getPhase()
	return _currentPhase
end

function GameManager.getBiome()
	return _currentBiome
end

function GameManager.onPhaseChanged(callback)
	table.insert(_callbacks, callback)
end

-- ─── Phase transition ─────────────────────────────────────────────────────────

local function _transition(newPhase)
	_currentPhase = newPhase
	print("[GameManager] Phase →", newPhase)

	-- Notify all registered server managers
	for _, cb in ipairs(_callbacks) do
		task.spawn(cb, newPhase, _currentBiome)
	end

	-- Notify all clients
	RemoteEvents.PhaseChanged:FireAllClients(newPhase)
end

-- ─── Phase entry logic ────────────────────────────────────────────────────────

local function _startLobby()
	_transition(Constants.PHASES.LOBBY)

	if Constants.SOLO_TEST_MODE then
		-- In test mode: start immediately once at least 1 player is in.
		-- Wait 5s (up from 2s) so the client's character has time to load and
		-- StarterGui scripts can connect their PhaseChanged listeners before we fire.
		repeat task.wait(0.5) until #Players:GetPlayers() >= 1
		task.wait(5)
		_startFarming()
		return
	end

	-- Production: wait for MIN_TO_START or 30s timeout
	local waited = 0
	repeat
		task.wait(1)
		waited = waited + 1
	until #Players:GetPlayers() >= Constants.MIN_TO_START or waited >= 30
	_startFarming()
end

function _startFarming()
	-- Pick biome once per session
	_currentBiome = BiomeConfig.random()
	RemoteEvents.BiomeSelected:FireAllClients(_currentBiome)

	_transition(Constants.PHASES.FARMING)

	-- Countdown and auto-advance
	_phaseTimer = task.delay(Constants.PHASE_DURATION.FARMING, function()
		_startCrafting()
	end)
end

function _startCrafting()
	if _phaseTimer then pcall(task.cancel, _phaseTimer) end
	_transition(Constants.PHASES.CRAFTING)

	_phaseTimer = task.delay(Constants.PHASE_DURATION.CRAFTING, function()
		_startRacing()
	end)
end

function _startRacing()
	if _phaseTimer then pcall(task.cancel, _phaseTimer) end
	_transition(Constants.PHASES.RACING)

	-- Failsafe timeout
	_phaseTimer = task.delay(Constants.RACING_TIMEOUT, function()
		_startResults({})
	end)
end

function _startResults(finishOrder)
	if _phaseTimer then pcall(task.cancel, _phaseTimer) end
	_transition(Constants.PHASES.RESULTS)
	RemoteEvents.RaceFinished:FireAllClients(finishOrder)

	-- Wait for Play Again votes or 30s, then restart
	task.delay(30, function()
		_startLobby()
	end)
end

-- ─── External triggers ───────────────────────────────────────────────────────
-- Called by CraftingManager when all players submit early

function GameManager.allPlayersSubmittedCraft()
	if _currentPhase == Constants.PHASES.CRAFTING then
		task.cancel(_phaseTimer)
		_startRacing()
	end
end

-- Called by RacingManager when all players finish

function GameManager.raceComplete(finishOrder)
	if _currentPhase == Constants.PHASES.RACING then
		_startResults(finishOrder)
	end
end

-- ─── Boot ─────────────────────────────────────────────────────────────────────

task.spawn(_startLobby)

return GameManager
