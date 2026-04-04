-- OceanMapBuilder.server.lua
-- Procedurally builds the OCEAN biome map:
--   - Open water plane with multiple scatter islands
--   - S-curve race track as floating docks / bridges with wave-crest edges
--   - Lighthouse prop on a side island
--   - Buoyancy zones, buoys, boost pads, finish line
-- Resolves: Issue #9, #87, #97

local CollectionService = game:GetService("CollectionService")

local C = {
	WATER        = Color3.fromRGB(28,  85,  175),
	WATER_DEEP   = Color3.fromRGB(12,  45,  115),
	WATER_FOAM   = Color3.fromRGB(190, 220, 255),
	DOCK         = Color3.fromRGB(145, 105, 62),
	DOCK_PLANK   = Color3.fromRGB(165, 120, 72),
	SAND         = Color3.fromRGB(220, 195, 125),
	SAND_WET     = Color3.fromRGB(185, 160, 95),
	FOAM         = Color3.fromRGB(200, 228, 255),
	BARRIER      = Color3.fromRGB(255, 75,  40),
	BOOST        = Color3.fromRGB(55,  200, 255),
	ISLAND_GRASS = Color3.fromRGB(72,  148, 58),
	PALM_TRUNK   = Color3.fromRGB(120, 88,  42),
	PALM_LEAF    = Color3.fromRGB(55,  158, 48),
	BUOY_RED     = Color3.fromRGB(215, 48,  48),
	BUOY_WHITE   = Color3.fromRGB(238, 238, 238),
	LIGHTHOUSE   = Color3.fromRGB(235, 235, 230),
	LIGHTHOUSE_B = Color3.fromRGB(210, 55,  55),
	BEACON       = Color3.fromRGB(255, 220, 80),
	ROPE         = Color3.fromRGB(180, 148, 85),
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

local WATER_Y = 0

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

-- ─── Segment CFrame helper (same as Forest) ───────────────────────────────────

local function _segCF(ax, az, bx, bz)
	local mx, mz = (ax + bx) * 0.5, (az + bz) * 0.5
	local rotY   = math.atan2(bx - ax, bz - az)
	return CFrame.new(mx, WATER_Y + 1.5, mz) * CFrame.Angles(0, rotY, 0)
end

local function _segLen(ax, az, bx, bz)
	local dx, dz = bx - ax, bz - az
	return math.sqrt(dx * dx + dz * dz)
end

-- ─── Water plane ──────────────────────────────────────────────────────────────

local function _buildWater(root)
	_part(root, {
		Name         = "WaterPlane",
		Size         = Vector3.new(650, 4, 1700),
		Position     = Vector3.new(0, WATER_Y - 2, 0),
		Color        = C.WATER,
		Material     = MAT.WATER,
		Transparency = 0.30,
		CanCollide   = false,
	})
	_part(root, {
		Name         = "DeepWater",
		Size         = Vector3.new(650, 1, 1700),
		Position     = Vector3.new(0, WATER_Y - 7, 0),
		Color        = C.WATER_DEEP,
		Material     = MAT.WATER,
		CanCollide   = false,
	})
	-- Foam surface layer
	local rng = Random.new(11)
	for _ = 1, 25 do
		local fx = rng:NextNumber(-280, 280)
		local fz = rng:NextNumber(-700, 700)
		_part(root, {
			Name         = "WaterFoam",
			Size         = Vector3.new(rng:NextNumber(15,45), 0.5, rng:NextNumber(8,25)),
			Position     = Vector3.new(fx, WATER_Y + 0.3, fz),
			Color        = C.WATER_FOAM,
			Material     = MAT.WATER,
			Transparency = 0.65,
			CanCollide   = false,
			CastShadow   = false,
		})
	end
end

-- ─── Farm island (Z = 250 to 510) ────────────────────────────────────────────

local function _buildFarmIsland(root)
	-- Sandy base
	_part(root, {
		Name     = "FarmIsland",
		Size     = Vector3.new(170, 7, 270),
		Position = Vector3.new(0, WATER_Y - 1.5, 380),
		Color    = C.SAND,
		Material = MAT.SAND,
	})
	-- Wet sand ring
	_part(root, {
		Name     = "FarmIslandWet",
		Size     = Vector3.new(185, 5, 285),
		Position = Vector3.new(0, WATER_Y - 2.5, 380),
		Color    = C.SAND_WET,
		Material = MAT.SAND,
	})
	-- Grass top
	_part(root, {
		Name     = "FarmGrass",
		Size     = Vector3.new(145, 1, 240),
		Position = Vector3.new(0, WATER_Y + 2.5, 380),
		Color    = C.ISLAND_GRASS,
		Material = Enum.Material.Grass,
	})

	-- Spawn points
	local cols = { -50, -25, 0, 25, 50 }
	local rows = { 295, 335 }
	for _, row in ipairs(rows) do
		for _, col in ipairs(cols) do
			local sp = _part(root, {
				Name         = "FarmSpawnPoint",
				Size         = Vector3.new(4, 0.5, 4),
				Position     = Vector3.new(col, WATER_Y + 3.5, row),
				Color        = Color3.fromRGB(255, 220, 60),
				Material     = MAT.NEON,
				CanCollide   = false,
				Transparency = 0.5,
			})
			_tag(sp, "FarmSpawn")
		end
	end

	-- Palm trees on farm island
	local rng = Random.new(99)
	local function _palm(px, pz)
		local h = rng:NextNumber(9, 15)
		-- Slightly curved trunk (2 segments)
		local leanX = rng:NextNumber(-1.5, 1.5)
		_part(root, {
			Name     = "PalmTrunk",
			Size     = Vector3.new(1.2, h * 0.6, 1.2),
			Position = Vector3.new(px, WATER_Y + 2.5 + h * 0.3, pz),
			Color    = C.PALM_TRUNK,
			Material = MAT.WOOD,
			CanCollide = false,
		})
		_part(root, {
			Name     = "PalmTrunkTop",
			Size     = Vector3.new(1, h * 0.5, 1),
			Position = Vector3.new(px + leanX * 0.5, WATER_Y + 2.5 + h * 0.78, pz),
			Color    = C.PALM_TRUNK,
			Material = MAT.WOOD,
			CanCollide = false,
		})
		-- Fan leaves
		for i = 0, 5 do
			local angle = (i / 6) * math.pi * 2
			local leafX = math.cos(angle) * 5
			local leafZ = math.sin(angle) * 5
			_part(root, {
				Name     = "PalmLeaf",
				Size     = Vector3.new(0.5, 0.3, 9),
				CFrame   = CFrame.new(px + leanX + leafX * 0.4, WATER_Y + 2.5 + h + 0.5, pz + leafZ * 0.4)
					* CFrame.Angles(math.rad(-18), angle, 0),
				Color    = C.PALM_LEAF,
				Material = MAT.LEAVES,
				CanCollide = false,
			})
		end
	end

	for _ = 1, 10 do
		local px = rng:NextNumber(-65, 65)
		local pz = rng:NextNumber(265, 500)
		_palm(px, pz)
	end
end

-- ─── Scatter islands ──────────────────────────────────────────────────────────

local function _buildScatterIslands(root)
	local islands = {
		{ -220, 0,    50 },   -- west mid: lighthouse island
		{  200, 0,  -120 },   -- east mid
		{ -180, 0,  -350 },   -- west near finish
		{  210, 0,   200 },   -- east near farm
	}
	local rng = Random.new(55)
	for i, isl in ipairs(islands) do
		local ix, iz = isl[1], isl[3]
		local islandR = rng:NextNumber(35, 60)
		_part(root, {
			Name     = "Island_" .. i,
			Size     = Vector3.new(islandR * 2, 6, islandR * 1.5),
			Position = Vector3.new(ix, WATER_Y - 1.5, iz),
			Color    = C.SAND,
			Material = MAT.SAND,
		})
		_part(root, {
			Name     = "IslandGrass_" .. i,
			Size     = Vector3.new(islandR * 1.6, 1, islandR * 1.2),
			Position = Vector3.new(ix, WATER_Y + 2.5, iz),
			Color    = C.ISLAND_GRASS,
			Material = Enum.Material.Grass,
		})
		-- Palm on each scatter island
		local h = rng:NextNumber(10, 16)
		_part(root, {
			Name     = "IslandPalm_" .. i,
			Size     = Vector3.new(1.2, h, 1.2),
			Position = Vector3.new(ix + rng:NextNumber(-10, 10), WATER_Y + 2.5 + h / 2, iz + rng:NextNumber(-8, 8)),
			Color    = C.PALM_TRUNK,
			Material = MAT.WOOD,
			CanCollide = false,
		})
		for leaf = 0, 4 do
			local angle = (leaf / 5) * math.pi * 2
			_part(root, {
				Name     = "IslandLeaf_" .. i,
				Size     = Vector3.new(0.5, 0.3, 8),
				CFrame   = CFrame.new(ix + math.cos(angle) * 3, WATER_Y + 2.5 + h + 0.4, iz + math.sin(angle) * 3)
					* CFrame.Angles(math.rad(-18), angle, 0),
				Color    = C.PALM_LEAF,
				Material = MAT.LEAVES,
				CanCollide = false,
			})
		end
	end
end

-- ─── Lighthouse (on western scatter island at Z=50) ───────────────────────────

local function _buildLighthouse(root)
	local lx, lz = -220, 50

	-- Base platform
	_part(root, {
		Name     = "LighthouseBase",
		Size     = Vector3.new(10, 3, 10),
		Position = Vector3.new(lx, WATER_Y + 4, lz),
		Color    = C.LIGHTHOUSE,
		Material = MAT.ROCK,
	})
	-- Tower body (3 stacked sections narrowing upward)
	local sections = { {8,16}, {7,10}, {6,8} }
	local yBase = WATER_Y + 5.5
	for _, s in ipairs(sections) do
		_part(root, {
			Name     = "LighthouseTower",
			Size     = Vector3.new(s[1], s[2], s[1]),
			Position = Vector3.new(lx, yBase + s[2] / 2, lz),
			Color    = (s[1] == 7) and C.LIGHTHOUSE_B or C.LIGHTHOUSE,
			Material = MAT.Rock or Enum.Material.SmoothPlastic,
		})
		yBase = yBase + s[2]
	end
	-- Lantern room
	_part(root, {
		Name     = "LighthouseLantern",
		Size     = Vector3.new(7, 5, 7),
		Position = Vector3.new(lx, yBase + 2.5, lz),
		Color    = Color3.fromRGB(180, 210, 230),
		Material = Enum.Material.Glass or MAT.ROCK,
		Transparency = 0.4,
	})
	-- Beacon light
	local beacon = _part(root, {
		Name     = "LighthouseBeacon",
		Size     = Vector3.new(3, 3, 3),
		Position = Vector3.new(lx, yBase + 5.5, lz),
		Color    = C.BEACON,
		Material = MAT.NEON,
		CanCollide = false,
		CastShadow = false,
	})
	-- Roof cone (WedgePart cap)
	local roofW = _wedge(root, {
		Name     = "LighthouseRoof",
		Size     = Vector3.new(7, 5, 3.5),
		Color    = C.LIGHTHOUSE_B,
		Material = MAT.METAL,
		CanCollide = false,
	})
	roofW.CFrame = CFrame.new(lx - 1.75, yBase + 7.5, lz) * CFrame.Angles(0, 0, 0)
	local roofE = _wedge(root, {
		Name     = "LighthouseRoofE",
		Size     = Vector3.new(7, 5, 3.5),
		Color    = C.LIGHTHOUSE_B,
		Material = MAT.METAL,
		CanCollide = false,
	})
	roofE.CFrame = CFrame.new(lx + 1.75, yBase + 7.5, lz) * CFrame.Angles(0, math.pi, 0)
end

-- ─── S-curve dock track ───────────────────────────────────────────────────────
-- Same S-curve pattern as Forest but the track is floating docks at WATER_Y+1.5

local DOCK_W = 28

local NODES = {
	{   0,  155 },   -- [1] from farm island dock
	{ -22,   40 },   -- [2] curve left
	{ -22,  -70 },   -- [3] left dock
	{  20, -195 },   -- [4] S-curve right
	{  20, -315 },   -- [5] right dock
	{ -18, -425 },   -- [6] S-curve left
	{ -18, -520 },   -- [7] left dock
	{   0, -575 },   -- [8] finish approach
}

local function _buildDocks(root)
	local DOCK_Y = WATER_Y + 1.5

	for i = 1, #NODES - 1 do
		local a, b   = NODES[i], NODES[i + 1]
		local segLen = _segLen(a[1], a[2], b[1], b[2])
		local cf     = _segCF(a[1], a[2], b[1], b[2])

		-- Main dock plank base
		local dock = _part(root, {
			Name     = "Dock_" .. i,
			Size     = Vector3.new(DOCK_W, 1.5, segLen),
			Color    = C.DOCK,
			Material = MAT.WOOD,
		})
		dock.CFrame = cf

		-- Plank strips (along local Z)
		local plankCount = math.floor(segLen / 5)
		for p = 0, plankCount - 1 do
			local pz = -segLen / 2 + (p + 0.5) * (segLen / (plankCount > 0 and plankCount or 1))
			local plank = _part(root, {
				Name     = "Plank",
				Size     = Vector3.new(DOCK_W - 1, 0.4, 3.5),
				Color    = C.DOCK_PLANK,
				Material = MAT.WOOD,
				CanCollide = false,
				CastShadow = false,
			})
			plank.CFrame = cf * CFrame.new(0, 1, pz)
		end

		-- Wave-crest edge barriers (replace plain railings)
		for _, side in ipairs({ -1, 1 }) do
			local railLen = segLen
			for waveIdx = 0, math.floor(railLen / 12) - 1 do
				local wz = -railLen / 2 + (waveIdx + 0.5) * 12
				local waveH = 1.2 + math.sin(waveIdx * 1.3) * 0.5
				local rail = _part(root, {
					Name     = "WaveCrest",
					Size     = Vector3.new(0.8, waveH * 2, 11),
					Color    = C.FOAM,
					Material = MAT.WATER,
					CanCollide = false,
					CastShadow = false,
					Transparency = 0.3,
				})
				rail.CFrame = cf * CFrame.new(side * (DOCK_W / 2 - 0.5), waveH, wz)
			end
		end

		-- Support pillars under water (visible through semi-transparent water)
		local pillarCount = math.max(2, math.floor(segLen / 40))
		for p = 0, pillarCount - 1 do
			local pz = -segLen / 2 + (p + 0.5) * (segLen / pillarCount)
			for _, sx in ipairs({ -1, 1 }) do
				local pillar = _part(root, {
					Name     = "Pillar",
					Size     = Vector3.new(1.2, 9, 1.2),
					Color    = C.DOCK,
					Material = MAT.WOOD,
				})
				pillar.CFrame = cf * CFrame.new(sx * (DOCK_W / 2 - 3), -5.5, pz)
			end
		end
	end
end

-- ─── Buoyancy zones ────────────────────────────────────────────────────────────

local function _buildBuoyancyZones(root)
	local zones = {
		{ 0, -2,  100,  90, 200 },
		{ 0, -2,  -90,  90, 200 },
		{ 0, -2, -300,  90, 200 },
		{ 0, -2, -490,  90, 160 },
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

-- ─── Navigation buoys ─────────────────────────────────────────────────────────

local function _buildBuoys(root)
	-- Place buoys along the track edges at curve nodes
	for ni, node in ipairs(NODES) do
		if ni > 1 and ni < #NODES then
			for _, side in ipairs({ -1, 1 }) do
				local bx = node[1] + side * 25
				local bz = node[2]
				local buoy = _part(root, {
					Name     = "Buoy",
					Size     = Vector3.new(2.5, 6, 2.5),
					Position = Vector3.new(bx, WATER_Y + 3, bz),
					Color    = (ni + side) % 2 == 0 and C.BUOY_RED or C.BUOY_WHITE,
					Material = MAT.NEON,
				})
				_tag(buoy, "Obstacle")
				-- Float pole on top
				_part(root, {
					Name     = "BuoyPole",
					Size     = Vector3.new(0.5, 4, 0.5),
					Position = Vector3.new(bx, WATER_Y + 9, bz),
					Color    = C.BUOY_WHITE,
					Material = MAT.METAL,
					CanCollide = false,
				})
			end
		end
	end
end

-- ─── Boost pads ───────────────────────────────────────────────────────────────

local function _buildBoostPads(root)
	local pads = {
		{ NODES[1][1], NODES[1][2] - 45 },
		{ NODES[3][1], NODES[3][2] + 20 },
		{ NODES[5][1], NODES[5][2] + 55 },
		{ NODES[7][1], NODES[7][2] + 20 },
	}
	for i, pd in ipairs(pads) do
		local pad = _part(root, {
			Name     = "BoostPad_" .. i,
			Size     = Vector3.new(10, 0.3, 6),
			Position = Vector3.new(pd[1], WATER_Y + 2.3, pd[2]),
			Color    = C.BOOST,
			Material = MAT.NEON,
			CanCollide = false,
			CastShadow = false,
		})
		_tag(pad, "BoostPad")
	end
end

-- ─── Finish line ──────────────────────────────────────────────────────────────

local function _buildFinishLine(root)
	local finY = WATER_Y + 1.5

	for col = -12, 12, 4 do
		for row = 0, 1 do
			_part(root, {
				Name     = "FinishTile",
				Size     = Vector3.new(4, 0.3, 4),
				Position = Vector3.new(col, finY + 0.9, -597 + row * 4),
				Color    = (math.floor(col / 4) + row) % 2 == 0
					and Color3.new(1,1,1) or Color3.new(0,0,0),
				Material = MAT.METAL,
				CanCollide = false,
			})
		end
	end

	local finish = _part(root, {
		Name         = "FinishLine",
		Size         = Vector3.new(30, 10, 2),
		Position     = Vector3.new(0, finY + 5, -599),
		CanCollide   = false,
		Transparency = 1,
	})
	_tag(finish, "FinishLine")

	for side = -1, 1, 2 do
		_part(root, {
			Name     = "FinishPole",
			Size     = Vector3.new(1.5, 16, 1.5),
			Position = Vector3.new(side * 16, finY + 8, -599),
			Color    = C.BUOY_WHITE,
			Material = MAT.METAL,
		})
	end
	_part(root, {
		Name     = "FinishArch",
		Size     = Vector3.new(34, 2.5, 1.5),
		Position = Vector3.new(0, finY + 16.5, -599),
		Color    = Color3.fromRGB(35, 155, 255),
		Material = MAT.NEON,
		CanCollide = false,
	})
	-- Rope swags between poles
	for swagX = -14, 14, 7 do
		_part(root, {
			Name     = "FinishRope",
			Size     = Vector3.new(7.5, 0.6, 0.4),
			Position = Vector3.new(swagX, finY + 14.5, -599),
			Color    = C.ROPE,
			Material = MAT.WOOD,
			CanCollide = false,
		})
	end
end

-- ─── Main build ───────────────────────────────────────────────────────────────

local function buildOcean()
	local root = _getOrCreateMap()

	_buildWater(root)
	_buildFarmIsland(root)
	_buildScatterIslands(root)
	_buildLighthouse(root)
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
