-- OceanMapBuilder.server.lua
-- Procedurally builds the OCEAN biome map:
--   - Open water plane with islands
--   - Race track as floating docks / bridges
--   - Buoyancy zones, boost pads, obstacles, finish line
-- Resolves: Issue #9

local CollectionService = game:GetService("CollectionService")

local C = {
	WATER      = Color3.fromRGB(30,  90,  180),
	DOCK       = Color3.fromRGB(140, 100, 60),
	SAND       = Color3.fromRGB(220, 190, 120),
	FOAM       = Color3.fromRGB(200, 225, 255),
	BARRIER    = Color3.fromRGB(255, 80,  40),
	BOOST      = Color3.fromRGB(60,  200, 255),
	ISLAND     = Color3.fromRGB(80,  140, 60),
	PALM_TRUNK = Color3.fromRGB(120, 85,  40),
	PALM_LEAF  = Color3.fromRGB(60,  160, 50),
	BUOY_RED   = Color3.fromRGB(220, 50,  50),
	BUOY_WHITE = Color3.fromRGB(240, 240, 240),
}

local MAT = {
	WATER  = Enum.Material.SmoothPlastic,
	WOOD   = Enum.Material.Wood,
	SAND   = Enum.Material.Sand,
	METAL  = Enum.Material.Metal,
	NEON   = Enum.Material.Neon,
	LEAVES = Enum.Material.LeafyGrass,
	ROCK   = Enum.Material.Rock,
}

local WATER_Y = 0  -- matches BiomeConfig waterPlaneY

local function _part(parent, props)
	local p = Instance.new("Part")
	p.Anchored   = true
	p.CanCollide = true
	for k, v in pairs(props) do pcall(function() p[k] = v end) end
	p.Parent = parent
	return p
end

local function _wedge(parent, props)
	local p = Instance.new("WedgePart")
	p.Anchored   = true
	p.CanCollide = true
	for k, v in pairs(props) do pcall(function() p[k] = v end) end
	p.Parent = parent
	return p
end

local function _tag(part, tagName)
	CollectionService:AddTag(part, tagName)
end

local function _getOrCreateMap()
	local maps = workspace:FindFirstChild("Maps") or (function()
		local f = Instance.new("Folder"); f.Name = "Maps"; f.Parent = workspace; return f
	end)()
	local existing = maps:FindFirstChild("OceanMap")
	if existing then existing:Destroy() end
	local model = Instance.new("Model")
	model.Name   = "OceanMap"
	model.Parent = maps
	return model
end

-- ─── Water plane ────────────────────────────────────────────────────────────

local function _buildWater(root)
	local water = _part(root, {
		Name         = "WaterPlane",
		Size         = Vector3.new(600, 4, 1600),
		Position     = Vector3.new(0, WATER_Y - 2, 0),
		Color        = C.WATER,
		Material     = MAT.WATER,
		Transparency = 0.35,
		CanCollide   = false,
	})
	-- Deep zone (darker)
	_part(root, {
		Name         = "DeepWater",
		Size         = Vector3.new(600, 1, 1600),
		Position     = Vector3.new(0, WATER_Y - 6, 0),
		Color        = Color3.fromRGB(15, 50, 120),
		Material     = MAT.WATER,
		CanCollide   = false,
	})
end

-- ─── Farm island (Z = 250 to 500) ────────────────────────────────────────────

local function _buildFarmIsland(root)
	-- Main island body
	_part(root, {
		Name     = "FarmIsland",
		Size     = Vector3.new(160, 6, 260),
		Position = Vector3.new(0, WATER_Y - 1, 375),
		Color    = C.SAND,
		Material = MAT.SAND,
	})
	-- Grass top
	_part(root, {
		Name     = "FarmGrass",
		Size     = Vector3.new(140, 1, 230),
		Position = Vector3.new(0, WATER_Y + 2.5, 375),
		Color    = Color3.fromRGB(80, 160, 70),
		Material = Enum.Material.Grass,
	})

	-- Spawn points
	local cols = { -50, -25, 0, 25, 50 }
	local rows = { 290, 330 }
	for _, row in ipairs(rows) do
		for _, col in ipairs(cols) do
			local sp = _part(root, {
				Name      = "FarmSpawnPoint",
				Size      = Vector3.new(4, 0.5, 4),
				Position  = Vector3.new(col, WATER_Y + 3.5, row),
				Color     = Color3.fromRGB(255, 220, 60),
				Material  = MAT.NEON,
				CanCollide = false,
				Transparency = 0.5,
			})
			_tag(sp, "FarmSpawn")
		end
	end

	-- Palm trees on island
	local rng = Random.new(99)
	for _ = 1, 8 do
		local tx = rng:NextNumber(-60, 60)
		local tz = rng:NextNumber(260, 490)
		local h  = rng:NextNumber(8, 14)
		_part(root, {
			Name     = "PalmTrunk",
			Size     = Vector3.new(1.2, h, 1.2),
			Position = Vector3.new(tx, WATER_Y + 2.5 + h / 2, tz),
			Color    = C.PALM_TRUNK,
			Material = MAT.WOOD,
			CanCollide = false,
		})
		for i = 0, 4 do
			local angle = (i / 5) * math.pi * 2
			local leafX = math.cos(angle) * 4
			local leafZ = math.sin(angle) * 4
			_part(root, {
				Name     = "PalmLeaf",
				Size     = Vector3.new(0.6, 0.3, 8),
				Position = Vector3.new(tx + leafX / 2, WATER_Y + 2.5 + h + 0.5, tz + leafZ / 2),
				Color    = C.PALM_LEAF,
				Material = MAT.LEAVES,
				CFrame   = CFrame.new(tx + leafX / 2, WATER_Y + 2.5 + h + 0.5, tz + leafZ / 2)
					* CFrame.Angles(0, angle, math.rad(-20)),
				CanCollide = false,
			})
		end
	end
end

-- ─── Floating dock track ─────────────────────────────────────────────────────

local DOCK_Y = WATER_Y + 1.5

local function _buildDocks(root)
	-- Main dock sections along Z axis
	local sections = {
		{ 0,   DOCK_Y, 150,  60, 220 },   -- x, y, z, width, length
		{ 0,   DOCK_Y, 0,    50, 200 },
		{ 0,   DOCK_Y, -150, 50, 200 },
		{ 0,   DOCK_Y, -340, 50, 200 },
		{ 0,   DOCK_Y, -530, 50, 140 },
	}

	for i, s in ipairs(sections) do
		_part(root, {
			Name     = "Dock_" .. i,
			Size     = Vector3.new(s[4], 1.5, s[5]),
			Position = Vector3.new(s[1], s[2], s[3]),
			Color    = C.DOCK,
			Material = MAT.WOOD,
		})

		-- Wood plank texture strips
		for plank = -math.floor(s[5] / 2), math.floor(s[5] / 2), 4 do
			_part(root, {
				Name     = "Plank",
				Size     = Vector3.new(s[4], 0.2, 2),
				Position = Vector3.new(s[1], s[2] + 0.85, s[3] + plank),
				Color    = Color3.fromRGB(160, 115, 70),
				Material = MAT.WOOD,
				CanCollide = false,
			})
		end

		-- Rope railings
		for side = -1, 1, 2 do
			_part(root, {
				Name     = "Railing_" .. i,
				Size     = Vector3.new(0.4, 2, s[5]),
				Position = Vector3.new(s[1] + side * (s[4] / 2 - 0.5), s[2] + 1.5, s[3]),
				Color    = C.DOCK,
				Material = MAT.WOOD,
				CanCollide = false,
			})
		end
	end
end

-- ─── Buoyancy zones ──────────────────────────────────────────────────────────

local function _buildBuoyancyZones(root)
	-- Large underwater trigger zones where buoyancy kicks in
	local zones = {
		{ 0, -2, 100,  80, 200 },
		{ 0, -2, -80,  80, 200 },
		{ 0, -2, -280, 80, 200 },
	}
	for i, bz in ipairs(zones) do
		local zone = _part(root, {
			Name         = "BuoyancyZone_" .. i,
			Size         = Vector3.new(bz[4], 8, bz[5]),
			Position     = Vector3.new(bz[1], bz[2], bz[3]),
			CanCollide   = false,
			Transparency = 1,
		})
		_tag(zone, "BuoyancyZone")
	end
end

-- ─── Buoys (navigation markers + obstacles) ───────────────────────────────────

local function _buildBuoys(root)
	local buoys = {
		{ -20, 0,  -50 }, { 20, 0, -50 },
		{ -20, 0, -200 }, { 20, 0, -200 },
		{ -20, 0, -380 }, { 20, 0, -380 },
	}
	for i, b in ipairs(buoys) do
		local buoy = _part(root, {
			Name     = "Buoy_" .. i,
			Size     = Vector3.new(3, 5, 3),
			Position = Vector3.new(b[1], WATER_Y + 2, b[3]),
			Color    = i % 2 == 0 and C.BUOY_RED or C.BUOY_WHITE,
			Material = MAT.NEON,
		})
		_tag(buoy, "Obstacle")
	end
end

-- ─── Boost pads ──────────────────────────────────────────────────────────────

local function _buildBoostPads(root)
	local pads = { -20, -140, -310, -490 }
	for i, z in ipairs(pads) do
		local pad = _part(root, {
			Name     = "BoostPad_" .. i,
			Size     = Vector3.new(10, 0.3, 6),
			Position = Vector3.new(0, DOCK_Y + 0.9, z),
			Color    = C.BOOST,
			Material = MAT.NEON,
			CanCollide = false,
		})
		_tag(pad, "BoostPad")
	end
end

-- ─── Finish line ─────────────────────────────────────────────────────────────

local function _buildFinishLine(root)
	for col = -12, 12, 4 do
		for row = 0, 1 do
			_part(root, {
				Name     = "FinishTile",
				Size     = Vector3.new(4, 0.3, 4),
				Position = Vector3.new(col, DOCK_Y + 0.9, -598 + row * 4),
				Color    = (math.floor(col / 4) + row) % 2 == 0
					and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),
				Material = MAT.METAL,
				CanCollide = false,
			})
		end
	end

	local finish = _part(root, {
		Name       = "FinishLine",
		Size       = Vector3.new(30, 8, 2),
		Position   = Vector3.new(0, DOCK_Y + 4, -599),
		CanCollide = false,
		Transparency = 1,
	})
	_tag(finish, "FinishLine")

	for side = -1, 1, 2 do
		_part(root, {
			Name     = "FinishPole",
			Size     = Vector3.new(1.5, 14, 1.5),
			Position = Vector3.new(side * 16, DOCK_Y + 7, -599),
			Color    = C.BUOY_WHITE,
			Material = MAT.METAL,
		})
	end
	_part(root, {
		Name     = "FinishArch",
		Size     = Vector3.new(34, 2, 1.5),
		Position = Vector3.new(0, DOCK_Y + 14, -599),
		Color    = Color3.fromRGB(40, 160, 255),
		Material = MAT.NEON,
		CanCollide = false,
	})
end

-- ─── Main build ──────────────────────────────────────────────────────────────

local function buildOcean()
	local root = _getOrCreateMap()
	_buildWater(root)
	_buildFarmIsland(root)
	_buildDocks(root)
	_buildBuoyancyZones(root)
	_buildBuoys(root)
	_buildBoostPads(root)
	_buildFinishLine(root)

	CollectionService:AddTag(root, "BiomeMap")
	root:SetAttribute("Biome", "OCEAN")

	print("[OceanMapBuilder] Built OCEAN map (" .. #root:GetChildren() .. " objects)")
	return root
end

local ok, err = pcall(buildOcean)
if not ok then warn("[OceanMapBuilder] Build failed: " .. tostring(err)) end
