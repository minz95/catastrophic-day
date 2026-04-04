-- CraftingUI/init.client.lua
-- Crafting phase overlay: countdown timer, collected inventory display,
-- auto-assigned vehicle slots, and a submit button.
-- Resolves: Issue #102

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants    = require(ReplicatedStorage.Shared.Constants)
local RemoteEvents = require(ReplicatedStorage.RemoteEvents)
local ItemConfig   = require(ReplicatedStorage.Shared.ItemConfig)
local LocalPlayer  = Players.LocalPlayer

-- ─── Screen ───────────────────────────────────────────────────────────────────

local screen = Instance.new("ScreenGui")
screen.Name           = "CraftingUI"
screen.ResetOnSpawn   = false
screen.IgnoreGuiInset = true
screen.Enabled        = false
screen.Parent         = LocalPlayer.PlayerGui

-- ─── Panel ────────────────────────────────────────────────────────────────────

local panel = Instance.new("Frame")
panel.Name                  = "Panel"
panel.Size                  = UDim2.new(0, 500, 0, 430)
panel.Position              = UDim2.new(0.5, -250, 0.5, -215)
panel.BackgroundColor3      = Color3.fromRGB(10, 10, 22)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel       = 0
panel.Parent                = screen

local _pc = Instance.new("UICorner"); _pc.CornerRadius = UDim.new(0, 14); _pc.Parent = panel

-- ─── Title ────────────────────────────────────────────────────────────────────

local title = Instance.new("TextLabel")
title.Size                  = UDim2.new(1, 0, 0, 50)
title.Position              = UDim2.new(0, 0, 0, 8)
title.BackgroundTransparency = 1
title.Text                  = "⚙ 크래프팅 페이즈"
title.Font                  = Enum.Font.GothamBold
title.TextScaled            = true
title.TextColor3            = Color3.fromRGB(255, 200, 60)
title.Parent                = panel

-- ─── Timer ────────────────────────────────────────────────────────────────────

local timerLabel = Instance.new("TextLabel")
timerLabel.Name              = "TimerLabel"
timerLabel.Size              = UDim2.new(1, 0, 0, 30)
timerLabel.Position          = UDim2.new(0, 0, 0, 60)
timerLabel.BackgroundTransparency = 1
timerLabel.Text              = "2:00"
timerLabel.Font              = Enum.Font.GothamBold
timerLabel.TextScaled        = true
timerLabel.TextColor3        = Color3.fromRGB(80, 220, 80)
timerLabel.Parent            = panel

-- ─── Section label helper ─────────────────────────────────────────────────────

local function _sectionLabel(text, yPos)
	local lbl = Instance.new("TextLabel")
	lbl.Size                  = UDim2.new(1, -20, 0, 22)
	lbl.Position              = UDim2.new(0, 10, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.Text                  = text
	lbl.Font                  = Enum.Font.GothamBold
	lbl.TextScaled            = true
	lbl.TextColor3            = Color3.fromRGB(180, 180, 180)
	lbl.TextXAlignment        = Enum.TextXAlignment.Left
	lbl.Parent                = panel
	return lbl
end

_sectionLabel("수집한 아이템", 96)

-- ─── Inventory row ────────────────────────────────────────────────────────────

local invFrame = Instance.new("Frame")
invFrame.Name                = "Inventory"
invFrame.Size                = UDim2.new(1, -20, 0, 66)
invFrame.Position            = UDim2.new(0, 10, 0, 122)
invFrame.BackgroundTransparency = 1
invFrame.Parent              = panel

local _il = Instance.new("UIListLayout")
_il.FillDirection            = Enum.FillDirection.Horizontal
_il.VerticalAlignment        = Enum.VerticalAlignment.Center
_il.Padding                  = UDim.new(0, 4)
_il.Parent                   = invFrame

_sectionLabel("비히클 슬롯 (자동 배정)", 198)

-- ─── Slots row ────────────────────────────────────────────────────────────────

local slotsFrame = Instance.new("Frame")
slotsFrame.Name              = "Slots"
slotsFrame.Size              = UDim2.new(1, -20, 0, 84)
slotsFrame.Position          = UDim2.new(0, 10, 0, 226)
slotsFrame.BackgroundTransparency = 1
slotsFrame.Parent            = panel

local _sl = Instance.new("UIListLayout")
_sl.FillDirection            = Enum.FillDirection.Horizontal
_sl.VerticalAlignment        = Enum.VerticalAlignment.Center
_sl.Padding                  = UDim.new(0, 4)
_sl.Parent                   = slotsFrame

local SLOT_ORDER  = { "BODY", "ENGINE", "SPECIAL", "MOBILITY", "HEAD", "TAIL" }
local SLOT_KR     = { BODY="몸체", ENGINE="엔진", SPECIAL="특수", MOBILITY="이동", HEAD="앞", TAIL="뒤" }
local slotItemLbls = {}  -- { [slotName] = TextLabel }

for _, slotName in ipairs(SLOT_ORDER) do
	local sf = Instance.new("Frame")
	sf.Size              = UDim2.new(0, 76, 1, 0)
	sf.BackgroundColor3  = Color3.fromRGB(28, 28, 48)
	sf.BorderSizePixel   = 0
	sf.Parent            = slotsFrame
	local _sfc = Instance.new("UICorner"); _sfc.CornerRadius = UDim.new(0, 6); _sfc.Parent = sf

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size             = UDim2.new(1, 0, 0.32, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text             = SLOT_KR[slotName]
	nameLbl.Font             = Enum.Font.Gotham
	nameLbl.TextScaled       = true
	nameLbl.TextColor3       = Color3.fromRGB(140, 140, 160)
	nameLbl.Parent           = sf

	local itemLbl = Instance.new("TextLabel")
	itemLbl.Name             = "Item"
	itemLbl.Size             = UDim2.new(1, 0, 0.68, 0)
	itemLbl.Position         = UDim2.new(0, 0, 0.32, 0)
	itemLbl.BackgroundTransparency = 1
	itemLbl.Text             = "—"
	itemLbl.Font             = Enum.Font.GothamBold
	itemLbl.TextScaled       = true
	itemLbl.TextColor3       = Color3.fromRGB(100, 100, 120)
	itemLbl.Parent           = sf

	slotItemLbls[slotName] = itemLbl
end

-- ─── Submit button ────────────────────────────────────────────────────────────

local submitBtn = Instance.new("TextButton")
submitBtn.Size              = UDim2.new(0, 220, 0, 50)
submitBtn.Position          = UDim2.new(0.5, -110, 1, -68)
submitBtn.BackgroundColor3  = Color3.fromRGB(60, 200, 80)
submitBtn.BorderSizePixel   = 0
submitBtn.Text              = "제출하기"
submitBtn.Font              = Enum.Font.GothamBold
submitBtn.TextScaled        = true
submitBtn.TextColor3        = Color3.new(1, 1, 1)
submitBtn.Parent            = panel
local _btc = Instance.new("UICorner"); _btc.CornerRadius = UDim.new(0, 10); _btc.Parent = submitBtn

-- ─── State ────────────────────────────────────────────────────────────────────

local _submitted       = false
local _currentInventory = {}

-- ─── Slot auto-assignment ─────────────────────────────────────────────────────

local RARITY_COLOUR = {
	Common   = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(80,  200, 80),
	Rare     = Color3.fromRGB(100, 160, 255),
	Epic     = Color3.fromRGB(200, 100, 255),
}

local function _buildSlotAssignments(inventory)
	local assignments = {}
	local remaining   = { table.unpack(inventory) }
	for _, slotName in ipairs(SLOT_ORDER) do
		if #remaining > 0 then
			assignments[slotName] = table.remove(remaining, 1)
		end
	end
	return assignments
end

local function _refreshDisplay()
	-- Inventory row
	for _, child in ipairs(invFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end
	for _, itemName in ipairs(_currentInventory) do
		local cfg = ItemConfig[itemName]
		local sf  = Instance.new("Frame")
		sf.Size              = UDim2.new(0, 56, 1, 0)
		sf.BackgroundColor3  = Color3.fromRGB(35, 35, 58)
		sf.BorderSizePixel   = 0
		sf.Parent            = invFrame
		local _sfc = Instance.new("UICorner"); _sfc.CornerRadius = UDim.new(0, 6); _sfc.Parent = sf

		local icon = Instance.new("TextLabel")
		icon.Size            = UDim2.new(1, 0, 0.52, 0)
		icon.BackgroundTransparency = 1
		icon.Text            = (cfg and cfg.icon) or "?"
		icon.TextScaled      = true
		icon.Font            = Enum.Font.GothamBold
		icon.TextColor3      = Color3.new(1, 1, 1)
		icon.Parent          = sf

		local lbl = Instance.new("TextLabel")
		lbl.Size             = UDim2.new(1, 0, 0.48, 0)
		lbl.Position         = UDim2.new(0, 0, 0.52, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text             = itemName
		lbl.TextScaled       = true
		lbl.Font             = Enum.Font.Gotham
		lbl.TextColor3       = RARITY_COLOUR[(cfg and cfg.rarity) or "Common"]
		lbl.Parent           = sf
	end

	-- Slot display
	local assignments = _buildSlotAssignments(_currentInventory)
	for slotName, lbl in pairs(slotItemLbls) do
		local name = assignments[slotName]
		if name then
			local cfg = ItemConfig[name]
			lbl.Text       = ((cfg and cfg.icon) or "") .. " " .. name
			lbl.TextColor3 = RARITY_COLOUR[(cfg and cfg.rarity) or "Common"]
		else
			lbl.Text       = "—"
			lbl.TextColor3 = Color3.fromRGB(100, 100, 120)
		end
	end
end

-- ─── Submit ───────────────────────────────────────────────────────────────────

submitBtn.MouseButton1Click:Connect(function()
	if _submitted then return end
	local assignments = _buildSlotAssignments(_currentInventory)
	local ok, result  = pcall(function()
		return RemoteEvents.SubmitCraft:InvokeServer(assignments)
	end)
	if ok and (result == "ok" or (type(result) == "string" and result:sub(1,2) == "ok")) then
		_submitted              = true
		submitBtn.Text          = "✓ 제출 완료"
		submitBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	end
end)

-- ─── Inventory sync (also during farming so data is ready at crafting start) ──

RemoteEvents.InventoryUpdated.OnClientEvent:Connect(function(inventory)
	_currentInventory = inventory
	if screen.Enabled then
		_refreshDisplay()
	end
end)

-- ─── Timer ────────────────────────────────────────────────────────────────────

local _startTick = 0
local _runConn   = nil
local _totalTime = Constants.PHASE_DURATION.CRAFTING

local function _startTimer()
	_startTick = tick()
	if _runConn then _runConn:Disconnect() end
	_runConn = RunService.Heartbeat:Connect(function()
		if not screen.Enabled then return end
		local remaining = math.max(0, _totalTime - (tick() - _startTick))
		local mins = math.floor(remaining / 60)
		local secs = math.floor(remaining % 60)
		timerLabel.Text = string.format("%d:%02d", mins, secs)
		if remaining <= 15 then
			timerLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		else
			timerLabel.TextColor3 = Color3.fromRGB(80, 220, 80)
		end
	end)
end

-- ─── Phase gate ───────────────────────────────────────────────────────────────

RemoteEvents.PhaseChanged.OnClientEvent:Connect(function(phase)
	if phase == Constants.PHASES.CRAFTING then
		_submitted              = false
		submitBtn.Text          = "제출하기"
		submitBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
		_refreshDisplay()
		screen.Enabled = true
		_startTimer()
	else
		screen.Enabled = false
		if _runConn then _runConn:Disconnect(); _runConn = nil end
	end
end)
