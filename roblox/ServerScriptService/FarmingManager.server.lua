-- FarmingManager.server.lua
-- Item spawning, pickup authority, contest system, and inventory stealing.
-- Resolves: Issue #16, #17, #19, #36, #39, #64

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local CollectionService   = game:GetService("CollectionService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage       = game:GetService("ServerStorage")

local Constants    = require(ReplicatedStorage.Shared.Constants)
local RemoteEvents = require(ReplicatedStorage.RemoteEvents)
local ItemConfig   = require(ServerScriptService.Modules.ItemConfig)
local GameManager  = require(ServerScriptService.GameManager)
local SessionManager = require(ServerScriptService.SessionManager)

-- ─── State ────────────────────────────────────────────────────────────────────

local _items      = {}   -- { [itemId] = { part, itemName, rarity, taken=false } }
local _contests   = {}   -- { [itemId] = { players={}, presses={}, endTick } }
local _phaseTimer = nil
local _active     = false

-- ─── Weighted spawn pool ──────────────────────────────────────────────────────

local function _buildSpawnPool()
	local pool = {}
	for rarity, names in pairs(ItemConfig._byRarity) do
		local count = Constants.RARITY_SPAWN_DIST[rarity] or 0
		for _ = 1, count do
			local name = names[math.random(#names)]
			table.insert(pool, { name = name, rarity = rarity })
		end
	end
	-- Shuffle
	for i = #pool, 2, -1 do
		local j = math.random(i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	return pool
end

-- ─── Spawn items ──────────────────────────────────────────────────────────────

local function _spawnItems(biome)
	_items = {}
	local pool = _buildSpawnPool()
	local mapCfg = require(ServerScriptService.Modules.BiomeConfig).get(biome)
	local mapModel = game.Workspace:FindFirstChild("Maps")
		and game.Workspace.Maps:FindFirstChild(biome .. "Map")

	if not mapModel then
		warn("[FarmingManager] Map not found for biome:", biome)
		return
	end

	-- Determine scatter area from map bounding box
	local cf, size = mapModel:GetBoundingBox()
	local halfX = math.min(size.X * 0.4, 150)
	local halfZ = math.min(size.Z * 0.4, 150)
	local baseY = cf.Position.Y + 2

	local usedPositions = {}
	local MIN_SEPARATION = 6  -- studs

	for i, entry in ipairs(pool) do
		if i > Constants.ITEM_SPAWN_COUNT then break end

		local cfg = ItemConfig[entry.name]
		if not cfg then continue end

		-- Find non-overlapping position (max 20 attempts)
		local pos
		for _ = 1, 20 do
			local candidate = Vector3.new(
				cf.Position.X + (math.random() * 2 - 1) * halfX,
				baseY,
				cf.Position.Z + (math.random() * 2 - 1) * halfZ
			)
			local ok = true
			for _, used in ipairs(usedPositions) do
				if (candidate - used).Magnitude < MIN_SEPARATION then
					ok = false
					break
				end
			end
			if ok then
				pos = candidate
				break
			end
		end
		if not pos then continue end

		table.insert(usedPositions, pos)

		-- Create world part
		local part = Instance.new("Part")
		part.Name  = "Item_" .. i
		part.Size  = Vector3.new(1.5, 1.5, 1.5)
		part.CFrame = CFrame.new(pos)
		part.Anchored = true
		part.CanCollide = false

		-- Tag with rarity colour as a visual hint
		local rarityColours = {
			Common   = Color3.fromRGB(200, 200, 200),
			Uncommon = Color3.fromRGB(80,  200, 80),
			Rare     = Color3.fromRGB(50,  100, 220),
			Epic     = Color3.fromRGB(150, 60,  220),
		}
		part.Color = rarityColours[entry.rarity] or part.Color

		-- Metadata
		local nameVal = Instance.new("StringValue")
		nameVal.Name  = "ItemName"
		nameVal.Value = entry.name
		nameVal.Parent = part

		local rarityVal = Instance.new("StringValue")
		rarityVal.Name  = "Rarity"
		rarityVal.Value = entry.rarity
		rarityVal.Parent = part

		part.Parent = mapModel

		local itemId = tostring(part)
		_items[itemId] = {
			part     = part,
			itemName = entry.name,
			rarity   = entry.rarity,
			taken    = false,
		}
	end

	print(string.format("[FarmingManager] Spawned %d items in %s", #usedPositions, biome))
end

-- ─── Give item to player ──────────────────────────────────────────────────────

local function _giveItem(player, itemId)
	local data = SessionManager.getData(player)
	local item = _items[itemId]
	if not data or not item or item.taken then return false end
	if #data.inventory >= Constants.INVENTORY_SIZE then return false end

	item.taken = true
	table.insert(data.inventory, item.itemName)
	item.part:Destroy()

	RemoteEvents.ItemPickedUp:FireAllClients(itemId, player.UserId)
	RemoteEvents.InventoryUpdated:FireClient(player, data.inventory)
	return true
end

-- ─── RequestPickup handler ────────────────────────────────────────────────────

RemoteEvents.RequestPickup.OnServerInvoke = function(player, itemId)
	if not _active then return "denied: phase not active" end

	local item = _items[itemId]
	if not item            then return "denied: item not found" end
	if item.taken          then return "denied: already taken" end

	local data = SessionManager.getData(player)
	if not data            then return "denied: no player data" end
	if #data.inventory >= Constants.INVENTORY_SIZE then
		return "denied: inventory full"
	end

	-- Distance check
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return "denied: no character" end

	local dist = (root.Position - item.part.Position).Magnitude
	if dist > Constants.PICKUP_RANGE then
		return "denied: too far (" .. math.floor(dist) .. " studs)"
	end

	-- Check if another player is also in range → start contest
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer == player then continue end
		local otherChar = otherPlayer.Character
		local otherRoot = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
		if not otherRoot then continue end
		if (otherRoot.Position - item.part.Position).Magnitude <= Constants.PICKUP_RANGE then
			-- Contest! Both players are competing
			if not _contests[itemId] then
				_contests[itemId] = {
					players = { player, otherPlayer },
					presses = { [player.UserId] = 0, [otherPlayer.UserId] = 0 },
					endTick = tick() + Constants.CONTEST_DURATION,
				}
				-- Notify both clients to start button-mash UI
				RemoteEvents.ContestUpdate:FireClient(player,
					itemId,
					{ userId = player.UserId,      count = 0 },
					{ userId = otherPlayer.UserId, count = 0 }
				)
				RemoteEvents.ContestUpdate:FireClient(otherPlayer,
					itemId,
					{ userId = player.UserId,      count = 0 },
					{ userId = otherPlayer.UserId, count = 0 }
				)
			end
			return "contested"
		end
	end

	-- Solo pickup
	if _giveItem(player, itemId) then
		return "ok"
	end
	return "denied: give failed"
end

-- ─── RequestContest handler (press count updates) ─────────────────────────────

RemoteEvents.RequestContest.OnServerInvoke = function(player, itemId, presses)
	local contest = _contests[itemId]
	if not contest then return end

	contest.presses[player.UserId] = math.min(presses, 999)  -- sanity cap

	-- Broadcast updated counts to both contestants
	local p1, p2 = contest.players[1], contest.players[2]
	local update = {
		{ userId = p1.UserId, count = contest.presses[p1.UserId] or 0 },
		{ userId = p2.UserId, count = contest.presses[p2.UserId] or 0 },
	}
	RemoteEvents.ContestUpdate:FireClient(p1, itemId, update[1], update[2])
	RemoteEvents.ContestUpdate:FireClient(p2, itemId, update[1], update[2])

	-- Check if contest time is up
	if tick() >= contest.endTick then
		local winner, loser
		if (contest.presses[p1.UserId] or 0) >= (contest.presses[p2.UserId] or 0) then
			winner, loser = p1, p2
		else
			winner, loser = p2, p1
		end

		RemoteEvents.ContestResult:FireAllClients(itemId, winner.UserId)
		_giveItem(winner, itemId)
		_contests[itemId] = nil
	end
end

-- ─── RequestSteal handler ─────────────────────────────────────────────────────

RemoteEvents.RequestSteal.OnServerInvoke = function(thief, targetUserId)
	if not _active then return end

	-- Check steal cooldown
	local thiefData = SessionManager.getData(thief)
	if not thiefData then return end
	if tick() < thiefData.stealCooldownEnd then return end

	-- CRAFTING lock-out
	local timeLeft = Constants.PHASE_DURATION.FARMING
		- (tick() - (_farmingStartTick or 0))
	if timeLeft < Constants.STEAL_DISABLE_BEFORE then return end

	local victim = Players:GetPlayerByUserId(targetUserId)
	if not victim then return end

	local victimData = SessionManager.getData(victim)
	if not victimData then return end
	if #victimData.inventory == 0 then return end

	-- Distance check
	local thiefRoot  = thief.Character  and thief.Character:FindFirstChild("HumanoidRootPart")
	local victimRoot = victim.Character and victim.Character:FindFirstChild("HumanoidRootPart")
	if not thiefRoot or not victimRoot then return end
	if (thiefRoot.Position - victimRoot.Position).Magnitude > Constants.STEAL_RANGE then return end

	-- Invincibility check
	if tick() < victimData.stealInvincibleEnd then return end

	-- Notify victim — they have STEAL_DEFEND_WINDOW seconds to defend
	RemoteEvents.StealAttempt:FireClient(victim, thief.Name)

	-- Wait for defence window
	task.wait(Constants.STEAL_DEFEND_WINDOW)

	-- Check if victim successfully defended (DefendSteal sets a flag)
	if victimData._defendingSteal then
		victimData._defendingSteal = false
		-- Stun thief briefly
		thiefData.stealCooldownEnd = tick() + 0.5
		return
	end

	-- Steal succeeds: take random item
	local idx = math.random(#victimData.inventory)
	local stolenItem = table.remove(victimData.inventory, idx)
	table.insert(thiefData.inventory, stolenItem)

	thiefData.stealCooldownEnd   = tick() + Constants.STEAL_COOLDOWN
	victimData.stealInvincibleEnd = tick() + Constants.STEAL_INVINCIBLE

	RemoteEvents.InventoryUpdated:FireClient(thief,  thiefData.inventory)
	RemoteEvents.InventoryUpdated:FireClient(victim, victimData.inventory)
	RemoteEvents.ItemStolen:FireAllClients(thief.Name, victim.Name, stolenItem)
end

RemoteEvents.DefendSteal.OnServerInvoke = function(player)
	local data = SessionManager.getData(player)
	if data then
		data._defendingSteal = true
	end
end

-- ─── Phase listener ───────────────────────────────────────────────────────────

_farmingStartTick = 0

GameManager.onPhaseChanged(function(phase, biome)
	if phase == Constants.PHASES.FARMING then
		_active = true
		_farmingStartTick = tick()
		_spawnItems(biome)

	elseif phase == Constants.PHASES.CRAFTING then
		_active = false
		_contests = {}
		-- Destroy any remaining unclaimed items
		for _, item in pairs(_items) do
			if not item.taken and item.part and item.part.Parent then
				item.part:Destroy()
			end
		end
		_items = {}
	end
end)
