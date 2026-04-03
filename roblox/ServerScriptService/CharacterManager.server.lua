-- CharacterManager.server.lua
-- Applies character skins on spawn and manages 10 farming spawn points.
-- Resolves: Issue #12, #13, #14

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SessionManager   = require(ServerScriptService.SessionManager)
local CharacterConfig  = require(ServerScriptService.Modules.CharacterConfig)
local RemoteEvents     = require(ReplicatedStorage.RemoteEvents)
local Constants        = require(ReplicatedStorage.Shared.Constants)

-- ─── Farming spawn points ─────────────────────────────────────────────────────
-- 10 points arranged in a 2×5 grid around the farm area center.
-- These are fallback positions; Studio map should have Parts tagged "FarmSpawn".

local FARM_SPAWN_CENTER = Vector3.new(0, 3, 200)
local SPAWN_SPACING     = 8

local function _getFarmSpawnPoints()
	local tagged = game:GetService("CollectionService"):GetTagged("FarmSpawn")
	if #tagged >= Constants.MAX_PLAYERS then
		-- Use tagged Parts from the map
		local points = {}
		for i, part in ipairs(tagged) do
			points[i] = part.CFrame + Vector3.new(0, 3, 0)
			if i >= Constants.MAX_PLAYERS then break end
		end
		return points
	end

	-- Fallback: generate a 2×5 grid
	local points = {}
	for row = 0, 1 do
		for col = 0, 4 do
			local idx = row * 5 + col + 1
			points[idx] = CFrame.new(
				FARM_SPAWN_CENTER + Vector3.new(
					(col - 2) * SPAWN_SPACING,
					0,
					row * SPAWN_SPACING
				)
			)
		end
	end
	return points
end

-- ─── Apply skin to character ──────────────────────────────────────────────────

local function _applySkin(character, skinIndex)
	local skin = CharacterConfig.get(skinIndex)
	if not skin then return end

	-- Apply BrickColor to body parts
	local bodyParts = {
		"Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
		"UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm",
		"LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
		"LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
		"LeftFoot", "RightFoot",
	}
	for _, partName in ipairs(bodyParts) do
		local part = character:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			part.BrickColor = skin.bodyColor
		end
	end

	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		head.BrickColor = skin.headColor
	end

	-- Add a simple helmet/colour indicator part on head
	if head then
		local existing = head:FindFirstChild("SkinHelmet")
		if not existing then
			local helmet = Instance.new("Part")
			helmet.Name            = "SkinHelmet"
			helmet.Size            = Vector3.new(1.2, 0.3, 1.2)
			helmet.Color           = skin.helmetColor
			helmet.Material        = Enum.Material.SmoothPlastic
			helmet.CanCollide      = false
			helmet.CastShadow      = false
			helmet.Parent          = character

			local weld = Instance.new("WeldConstraint")
			weld.Part0  = head
			weld.Part1  = helmet
			weld.Parent = helmet

			helmet.CFrame = head.CFrame * CFrame.new(0, 0.55, 0)
		end
	end

	-- Name tag above head with skin icon
	if head then
		local existing = head:FindFirstChild("SkinTag")
		if not existing then
			local billboard = Instance.new("BillboardGui")
			billboard.Name          = "SkinTag"
			billboard.Size          = UDim2.new(0, 80, 0, 30)
			billboard.StudsOffset   = Vector3.new(0, 2.5, 0)
			billboard.AlwaysOnTop   = false
			billboard.Parent        = head

			local label = Instance.new("TextLabel")
			label.Size              = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Text              = skin.icon .. "  " .. character.Name
			label.TextColor3        = Color3.new(1, 1, 1)
			label.TextStrokeTransparency = 0.5
			label.TextScaled        = true
			label.Font              = Enum.Font.GothamBold
			label.Parent            = billboard
		end
	end
end

-- ─── Teleport player to farm spawn point ─────────────────────────────────────

local _spawnIndex = 0

local function _teleportToFarm(player)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local points = _getFarmSpawnPoints()
	_spawnIndex = (_spawnIndex % #points) + 1
	hrp.CFrame = points[_spawnIndex]
end

-- ─── Player added / character spawned ───────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local pdata = SessionManager.getData(player)
		local skinIndex = pdata and pdata.skinIndex or 1
		-- Wait for character to fully load
		character:WaitForChild("HumanoidRootPart", 5)
		_applySkin(character, skinIndex)
	end)
end)

-- Handle players already connected when this script loads
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		local pdata = SessionManager.getData(player)
		_applySkin(player.Character, pdata and pdata.skinIndex or 1)
	end
	player.CharacterAdded:Connect(function(character)
		local pdata = SessionManager.getData(player)
		character:WaitForChild("HumanoidRootPart", 5)
		_applySkin(character, pdata and pdata.skinIndex or 1)
	end)
end

-- ─── Phase listener: teleport all to farm on FARMING start ──────────────────

local GameManager = require(ServerScriptService.GameManager)

GameManager.onPhaseChanged(function(phase)
	if phase == Constants.PHASES.FARMING then
		_spawnIndex = 0
		task.wait(0.5)  -- small grace period after phase change
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				_teleportToFarm(player)
			end
		end
	end
end)
