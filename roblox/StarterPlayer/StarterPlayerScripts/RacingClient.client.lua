-- RacingClient.client.lua
-- Vehicle controls, drift, boost, screen effects, and ability input.
-- Resolves: Issue #30, #31, #66

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants    = require(ReplicatedStorage.Shared.Constants)
local RemoteEvents = require(ReplicatedStorage.RemoteEvents)

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local RacingClient = {}

-- ─── State ────────────────────────────────────────────────────────────────────

local _active        = false
local _vehicle       = nil   -- Model
local _seat          = nil   -- VehicleSeat
local _stats         = nil   -- vehicleStats table
local _biome         = nil
local _drifting      = false
local _boostActive   = false
local _boostGauge    = 1.0   -- 0–1, refills over BOOST_COOLDOWN
local _heartbeatConn = nil
local _baseFOV       = 70
local _abilitySlots  = {}    -- { slotName → itemName } from crafting

-- ─── Input tracking ───────────────────────────────────────────────────────────

local _keys = {
	W = false, A = false, S = false, D = false,
	Up = false, Down = false, Left = false, Right = false,
	Shift = false, Space = false,
	E = false,   -- ability key
}

local KEY_MAP = {
	[Enum.KeyCode.W]     = "W",
	[Enum.KeyCode.A]     = "A",
	[Enum.KeyCode.S]     = "S",
	[Enum.KeyCode.D]     = "D",
	[Enum.KeyCode.Up]    = "Up",
	[Enum.KeyCode.Down]  = "Down",
	[Enum.KeyCode.Left]  = "Left",
	[Enum.KeyCode.Right] = "Right",
	[Enum.KeyCode.LeftShift]  = "Shift",
	[Enum.KeyCode.RightShift] = "Shift",
	[Enum.KeyCode.Space] = "Space",
	[Enum.KeyCode.E]     = "E",
}

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	local k = KEY_MAP[input.KeyCode]
	if k then _keys[k] = true end

	if not _active then return end

	-- Boost
	if k == "Shift" and not _boostActive and _boostGauge >= 1 then
		_triggerBoost()
	end

	-- Ability
	if k == "E" then
		_triggerAbility()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	local k = KEY_MAP[input.KeyCode]
	if k then _keys[k] = false end

	-- End drift when Shift released
	if k == "Shift" and _drifting then
		_exitDrift()
	end
end)

-- ─── Boost ────────────────────────────────────────────────────────────────────

function _triggerBoost()
	local result = RemoteEvents.RequestBoost:InvokeServer()
	if result ~= "ok" then return end

	_boostActive = true
	_boostGauge  = 0

	-- FOV punch
	TweenService:Create(Camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = _baseFOV + 20
	}):Play()

	-- Screen effect
	RemoteEvents.ScreenEffect:FireServer("boostStart", {})   -- not real; just local
	_applyScreenTint(Color3.fromRGB(100, 200, 255), 0.35, 0.2)

	local stats = _stats
	local dur   = (stats and stats.boostDuration) or Constants.BOOST_DURATION

	task.delay(dur, function()
		_boostActive = false
		TweenService:Create(Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			FieldOfView = _baseFOV
		}):Play()
		-- Cooldown refill
		task.spawn(_refillBoost)
	end)
end

function _refillBoost()
	local step = 1 / Constants.BOOST_COOLDOWN
	while _boostGauge < 1 do
		task.wait(0.05)
		_boostGauge = math.min(1, _boostGauge + step * 0.05)
		_updateBoostHUD()
	end
end

-- ─── Drift ────────────────────────────────────────────────────────────────────

local _driftGripBackup = nil

local function _isTurning()
	return (_keys.A or _keys.Left) or (_keys.D or _keys.Right)
end

local function _enterDrift()
	if not _seat or _drifting then return end
	_drifting       = true
	_driftGripBackup = _seat.TurnSpeed
	-- Reduce TurnSpeed cap → vehicle slides wide
	_seat.TurnSpeed  = math.max(_seat.TurnSpeed * 0.35, 0.3)
	_applyScreenTint(Color3.fromRGB(220, 160, 40), 0.2, 0.1)
	RemoteEvents.ScreenEffect:FireServer("driftStart", {})
end

function _exitDrift()
	if not _seat or not _drifting then return end
	_drifting = false
	if _driftGripBackup then
		_seat.TurnSpeed = _driftGripBackup
		_driftGripBackup = nil
	end
	-- Slingshot: brief speed bonus
	if _seat then
		local old = _seat.MaxSpeed
		_seat.MaxSpeed = old * 1.15
		task.delay(1.5, function()
			if _seat and _seat.Parent then _seat.MaxSpeed = old end
		end)
	end
end

-- ─── Vehicle drive loop ───────────────────────────────────────────────────────

local function _driveLoop()
	if not _seat then return end

	-- Forward / backward
	local throttle = 0
	if _keys.W or _keys.Up   then throttle =  1 end
	if _keys.S or _keys.Down  then throttle = -1 end

	-- Steer
	local steer = 0
	if _keys.A or _keys.Left  then steer = -1 end
	if _keys.D or _keys.Right then steer =  1 end

	-- Drift entry: Shift + turning at speed
	if _keys.Shift and _isTurning() and not _drifting then
		local vel = _vehicle and _vehicle.PrimaryPart and
			_vehicle.PrimaryPart.AssemblyLinearVelocity.Magnitude or 0
		if vel > (_seat.MaxSpeed * 0.5) then
			_enterDrift()
		end
	end

	_seat.ThrottleFloat = throttle
	_seat.SteerFloat    = steer
end

-- ─── Ability activation ───────────────────────────────────────────────────────

-- Cycle through SPECIAL → ENGINE → BODY slots on each E press
local _abilityOrder  = { "SPECIAL", "ENGINE", "BODY" }
local _abilityIndex  = 1

function _triggerAbility()
	local slotName = _abilityOrder[_abilityIndex]
	local itemName = _abilitySlots[slotName]
	if not itemName then
		-- Try next slot
		_abilityIndex = (_abilityIndex % #_abilityOrder) + 1
		slotName  = _abilityOrder[_abilityIndex]
		itemName  = _abilitySlots[slotName]
		if not itemName then return end
	end

	local result = RemoteEvents.RequestAbility:InvokeServer(itemName)
	if result == "ok" then
		_abilityIndex = (_abilityIndex % #_abilityOrder) + 1
	end
end

-- ─── Screen effects ───────────────────────────────────────────────────────────

local _overlayGui = nil

local function _getOverlay()
	if _overlayGui then return _overlayGui end
	_overlayGui = Instance.new("ScreenGui")
	_overlayGui.Name           = "RaceOverlay"
	_overlayGui.ResetOnSpawn   = false
	_overlayGui.IgnoreGuiInset = true
	_overlayGui.Parent         = LocalPlayer.PlayerGui

	local frame = Instance.new("Frame")
	frame.Name = "Tint"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = _overlayGui
	return _overlayGui
end

function _applyScreenTint(colour, alpha, duration)
	local gui   = _getOverlay()
	local tint  = gui:FindFirstChild("Tint")
	if not tint then return end
	tint.BackgroundColor3 = colour
	TweenService:Create(tint, TweenInfo.new(0.1), {
		BackgroundTransparency = 1 - alpha
	}):Play()
	task.delay(duration, function()
		TweenService:Create(tint, TweenInfo.new(0.3), {
			BackgroundTransparency = 1
		}):Play()
	end)
end

local function _cameraShake(intensity, duration)
	local steps = math.floor(duration / 0.05)
	task.spawn(function()
		for _ = 1, steps do
			local rx = (math.random() - 0.5) * intensity
			local ry = (math.random() - 0.5) * intensity
			Camera.CFrame = Camera.CFrame * CFrame.Angles(rx, ry, 0)
			task.wait(0.05)
		end
	end)
end

-- ─── ScreenEffect listener ───────────────────────────────────────────────────

RemoteEvents.ScreenEffect.OnClientEvent:Connect(function(effectName, params)
	if effectName == "collision" then
		_applyScreenTint(Color3.fromRGB(255, 100, 50), 0.4, 0.3)
		_cameraShake(0.04, 0.4)

	elseif effectName == "mudWarning" then
		_applyScreenTint(Color3.fromRGB(100, 70, 30), 0.25, 0.5)

	elseif effectName == "updraftWarning" then
		_applyScreenTint(Color3.fromRGB(100, 200, 255), 0.2, 0.4)

	elseif effectName == "boostPad" then
		_applyScreenTint(Color3.fromRGB(255, 220, 60), 0.3, 0.25)
		TweenService:Create(Camera, TweenInfo.new(0.2), { FieldOfView = _baseFOV + 10 }):Play()
		task.delay(0.4, function()
			TweenService:Create(Camera, TweenInfo.new(0.3), { FieldOfView = _baseFOV }):Play()
		end)

	elseif effectName == "respawn" then
		_applyScreenTint(Color3.fromRGB(255, 255, 255), 0.9, 0.5)

	elseif effectName == "bubblePop" then
		_applyScreenTint(Color3.fromRGB(150, 220, 255), 0.5, 0.3)
		_cameraShake(0.03, 0.2)

	elseif effectName == "hackControls" then
		-- Visual feedback that you're being hacked
		_applyScreenTint(Color3.fromRGB(50, 200, 50), 0.4, (params and params.duration) or 5)
	end
end)

-- ─── Boost HUD ───────────────────────────────────────────────────────────────

local _boostBar = nil

local function _ensureBoostHUD()
	if _boostBar then return end
	local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
	if not hud then return end
	local frame = hud:FindFirstChild("BoostBar")
	if frame then _boostBar = frame:FindFirstChild("Fill") end
end

function _updateBoostHUD()
	if not _boostBar then _ensureBoostHUD() end
	if not _boostBar then return end
	TweenService:Create(_boostBar, TweenInfo.new(0.1), {
		Size = UDim2.new(_boostGauge, 0, 1, 0)
	}):Play()
end

-- ─── Camera follow ────────────────────────────────────────────────────────────

local function _updateCamera()
	if not _vehicle or not _vehicle.PrimaryPart then return end
	local primary = _vehicle.PrimaryPart
	local lookDir = primary.CFrame.LookVector
	local offset  = Vector3.new(0, 5, 12)
	local camPos  = primary.Position - lookDir * offset.Z + Vector3.new(0, offset.Y, 0)
	local camCF   = CFrame.new(camPos, primary.Position + Vector3.new(0, 1.5, 0))
	Camera.CFrame = Camera.CFrame:Lerp(camCF, 0.12)
end

-- ─── VehicleSpawned listener ─────────────────────────────────────────────────

RemoteEvents.VehicleSpawned.OnClientEvent:Connect(function(userId, vehicleModel)
	if userId ~= LocalPlayer.UserId then return end
	_vehicle = vehicleModel
	_seat    = vehicleModel:FindFirstChildWhichIsA("VehicleSeat", true)
	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.FieldOfView = _baseFOV
end)

-- ─── Enable / Disable ─────────────────────────────────────────────────────────

function RacingClient.enable()
	_active      = true
	_boostActive = false
	_boostGauge  = 1
	_drifting    = false
	_abilityIndex = 1

	-- Get slot assignments from CraftingClient state (via a shared binding or
	-- stored value in PlayerGui tag — set when SubmitCraft fires)
	local tag = LocalPlayer.PlayerGui:FindFirstChild("CraftSlots")
	if tag then
		for _, v in ipairs(tag:GetChildren()) do
			if v:IsA("StringValue") then
				_abilitySlots[v.Name] = v.Value ~= "" and v.Value or nil
			end
		end
	end

	if _heartbeatConn then _heartbeatConn:Disconnect() end
	_heartbeatConn = RunService.Heartbeat:Connect(function()
		if not _active then return end
		_driveLoop()
		_updateCamera()
	end)
end

function RacingClient.disable()
	_active = false
	if _heartbeatConn then
		_heartbeatConn:Disconnect()
		_heartbeatConn = nil
	end
	Camera.CameraType  = Enum.CameraType.Custom
	Camera.FieldOfView = _baseFOV
	_vehicle = nil
	_seat    = nil
end

-- ─── Biome listener ──────────────────────────────────────────────────────────

RemoteEvents.BiomeSelected.OnClientEvent:Connect(function(biome)
	_biome = biome
end)

-- ─── Self-manage via PhaseChanged ────────────────────────────────────────────

RemoteEvents.PhaseChanged.OnClientEvent:Connect(function(phase)
	if phase == Constants.PHASES.RACING then
		RacingClient.enable()
	else
		RacingClient.disable()
	end
end)

return RacingClient
