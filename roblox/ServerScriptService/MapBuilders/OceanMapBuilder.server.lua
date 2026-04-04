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

-- ─── Open-water race course ──────────────────────────────────────────────────
-- Boats race directly on the water surface (WATER_Y = 0).
-- No solid dock platforms — course is marked by buoy lines on left and right.
-- Course width: 50 studs. Z goes from +200 (farm exit) to -600 (finish).

local COURSE_HALF_W = 25   -- half-width of race lane (50 studs total)
local BUOY_INTERVAL = 60   -- studs between buoy pairs along the course

-- ─── Buoyancy zone covering the full race lane ───────────────────────────────

local function _buildBuoyancyZones(root)
	-- One large zone covering the entire race course so boats float throughout
	local zone = _part(root, {
		Name         = "BuoyancyZone_Main",
		Size         = Vector3.new(COURSE_HALF_W * 2 + 20, 6, 900),
		Position     = Vector3.new(0, WATER_Y - 1, -200),
		CanCollide   = false,
		Transparency = 1,
	})
	_tag(zone, "BuoyancyZone")

	-- Additional wide zone near farm island start (boats enter from Z=200)
	local startZone = _part(root, {
		Name         = "BuoyancyZone_Start",
		Size         = Vector3.new(COURSE_HALF_W * 2 + 20, 6, 200),
		Position     = Vector3.new(0, WATER_Y - 1, 130),
		CanCollide   = false,
		Transparency = 1,
	})
	_tag(startZone, "BuoyancyZone")
end

-- ─── Course boundary buoys ────────────────────────────────────────────────────

local function _buildCourseBuoys(root)
	local buoyIdx = 0

	-- Pairs of buoys every BUOY_INTERVAL studs from Z=180 to Z=-580
	for z = 180, -580, -BUOY_INTERVAL do
		buoyIdx = buoyIdx + 1
		local isRedSide = (buoyIdx % 2 == 0)  -- alternate red/white per row

		for _, side in ipairs({ -1, 1 }) do
			local isRed = (side == 1) == isRedSide
			-- Buoy body (sphere-ish cylinder)
			local body = _part(root, {
				Name     = "Buoy_" .. buoyIdx .. (side > 0 and "R" or "L"),
				Size     = Vector3.new(2.5, 4, 2.5),
				Position = Vector3.new(side * COURSE_HALF_W, WATER_Y + 2, z),
				Color    = isRed and C.BUOY_RED or C.BUOY_WHITE,
				Material = MAT.NEON,
			})
			_tag(body, "Obstacle")

			-- Chain/anchor pole below water
			_part(root, {
				Name     = "BuoyChain_" .. buoyIdx .. (side > 0 and "R" or "L"),
				Size     = Vector3.new(0.3, 4, 0.3),
				Position = Vector3.new(side * COURSE_HALF_W, WATER_Y - 2, z),
				Color    = Color3.fromRGB(80, 80, 80),
				Material = MAT.METAL,
				CanCollide = false,
			})
		end
	end
end

-- ─── Corner turn markers ─────────────────────────────────────────────────────

local function _buildTurnMarkers(root)
	-- Large neon arches at key turn points to guide players
	local turns = { 0, -180, -360, -520 }
	for i, z in ipairs(turns) do
		-- Left arch pillar
		_part(root, {
			Name     = "TurnArch_L" .. i,
			Size     = Vector3.new(2, 12, 2),
			Position = Vector3.new(-COURSE_HALF_W - 2, WATER_Y + 6, z),
			Color    = Color3.fromRGB(40, 200, 255),
			Material = MAT.NEON,
			CanCollide = false,
		})
		-- Right arch pillar
		_part(root, {
			Name     = "TurnArch_R" .. i,
			Size     = Vector3.new(2, 12, 2),
			Position = Vector3.new(COURSE_HALF_W + 2, WATER_Y + 6, z),
			Color    = Color3.fromRGB(40, 200, 255),
			Material = MAT.NEON,
			CanCollide = false,
		})
		-- Crossbar
		_part(root, {
			Name     = "TurnArch_Top" .. i,
			Size     = Vector3.new(COURSE_HALF_W * 2 + 8, 2, 2),
			Position = Vector3.new(0, WATER_Y + 12, z),
			Color    = Color3.fromRGB(40, 200, 255),
			Material = MAT.NEON,
			CanCollide = false,
		})
	end
end

-- ─── Boost pads (floating platforms just above water) ────────────────────────

local function _buildBoostPads(root)
	local pads = { 60, -100, -280, -450 }
	for i, z in ipairs(pads) do
		local pad = _part(root, {
			Name     = "BoostPad_" .. i,
			Size     = Vector3.new(12, 0.4, 8),
			Position = Vector3.new(0, WATER_Y + 0.4, z),
			Color    = C.BOOST,
			Material = MAT.NEON,
			CanCollide = false,
		})
		_tag(pad, "BoostPad")
		-- Visual glow ring
		_part(root, {
			Name     = "BoostRing_" .. i,
			Size     = Vector3.new(16, 0.2, 12),
			Position = Vector3.new(0, WATER_Y + 0.3, z),
			Color    = Color3.fromRGB(100, 240, 255),
			Material = MAT.NEON,
			Transparency = 0.5,
			CanCollide = false,
		})
	end
end

-- ─── Start grid (boats start at Z=200, just below farm island) ───────────────

local function _buildStartGrid(root)
	-- Floating start platform / dock at Z=200
	_part(root, {
		Name     = "StartDock",
		Size     = Vector3.new(COURSE_HALF_W * 2, 1, 20),
		Position = Vector3.new(0, WATER_Y + 0.5, 200),
		Color    = C.DOCK,
		Material = MAT.WOOD,
	})
	-- Start line banner poles
	for side = -1, 1, 2 do
		_part(root, {
			Name     = "StartPole" .. (side > 0 and "R" or "L"),
			Size     = Vector3.new(1.5, 10, 1.5),
			Position = Vector3.new(side * (COURSE_HALF_W + 1), WATER_Y + 5, 192),
			Color    = C.BUOY_WHITE,
			Material = MAT.METAL,
		})
	end
	_part(root, {
		Name     = "StartBanner",
		Size     = Vector3.new(COURSE_HALF_W * 2 + 4, 2, 1),
		Position = Vector3.new(0, WATER_Y + 10, 192),
		Color    = Color3.fromRGB(255, 220, 40),
		Material = MAT.NEON,
		CanCollide = false,
	})
end

-- ─── Finish line ─────────────────────────────────────────────────────────────

local function _buildFinishLine(root)
	-- Checkered floating surface at finish
	for col = -COURSE_HALF_W, COURSE_HALF_W - 4, 4 do
		for row = 0, 1 do
			_part(root, {
				Name     = "FinishTile",
				Size     = Vector3.new(4, 0.4, 4),
				Position = Vector3.new(col + 2, WATER_Y + 0.4, -596 + row * 4),
				Color    = (math.floor((col + COURSE_HALF_W) / 4) + row) % 2 == 0
					and Color3.new(1,1,1) or Color3.new(0,0,0),
				Material = MAT.METAL,
				CanCollide = false,
			})
		end
	end

	local finish = _part(root, {
		Name         = "FinishLine",
		Size         = Vector3.new(COURSE_HALF_W * 2, 8, 2),
		Position     = Vector3.new(0, WATER_Y + 4, -598),
		CanCollide   = false,
		Transparency = 1,
	})
	_tag(finish, "FinishLine")

	for side = -1, 1, 2 do
		_part(root, {
			Name     = "FinishPole" .. (side > 0 and "R" or "L"),
			Size     = Vector3.new(1.5, 16, 1.5),
			Position = Vector3.new(side * (COURSE_HALF_W + 2), WATER_Y + 8, -598),
			Color    = C.BUOY_WHITE,
			Material = MAT.METAL,
		})
	end
	_part(root, {
		Name     = "FinishArch",
		Size     = Vector3.new(COURSE_HALF_W * 2 + 6, 2, 1.5),
		Position = Vector3.new(0, WATER_Y + 16, -598),
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
	_buildBuoyancyZones(root)
	_buildCourseBuoys(root)
	_buildTurnMarkers(root)
	_buildBoostPads(root)
	_buildStartGrid(root)
	_buildFinishLine(root)

	CollectionService:AddTag(root, "BiomeMap")
	root:SetAttribute("Biome", "OCEAN")

	print("[OceanMapBuilder] Built OCEAN map (" .. #root:GetChildren() .. " objects)")
	return root
end

local ok, err = pcall(buildOcean)
if not ok then warn("[OceanMapBuilder] Build failed: " .. tostring(err)) end
