-- OceanMapBuilder.server.lua
-- Procedurally builds the OCEAN biome map:
--   - Open water plane with farm island
--   - S-curve race course marked by buoys (3 corners at Z=0, -180, -360)
--   - Buoyancy zones, boost pads, drift corner zones, obstacles, finish line
-- Resolves: Issue #9, #114

local CollectionService = game:GetService("CollectionService")

local C = {
	WATER      = Color3.fromRGB(30,  90,  180),
	DOCK       = Color3.fromRGB(140, 100, 60),
	SAND       = Color3.fromRGB(220, 190, 120),
	BOOST      = Color3.fromRGB(60,  200, 255),
	PALM_TRUNK = Color3.fromRGB(120, 85,  40),
	PALM_LEAF  = Color3.fromRGB(60,  160, 50),
	BUOY_RED   = Color3.fromRGB(220, 50,  50),
	BUOY_WHITE = Color3.fromRGB(240, 240, 240),
	DRIFT_GLOW = Color3.fromRGB(40,  220, 255),
}

local MAT = {
	WATER  = Enum.Material.Glass,
	WOOD   = Enum.Material.Wood,
	SAND   = Enum.Material.Sand,
	METAL  = Enum.Material.Metal,
	NEON   = Enum.Material.Neon,
	LEAVES = Enum.Material.LeafyGrass,
}

local WATER_Y       = 2    -- WaterPlane top face at Y=2
local COURSE_HALF_W = 25   -- half-width of race lane (50 studs total)
local BUOY_INTERVAL = 60   -- studs between buoy pairs

local function _part(parent, props)
	local p = Instance.new("Part")
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

-- ─── S-curve course centerline ────────────────────────────────────────────────
-- Three corners at Z=0, Z=-180, Z=-360 (matching neon arch markers).
--   Z ≥  0:          straight,     center X = 0
--   Z  0 → -180:    swing LEFT,   center X = 0  → -22
--   Z -180 → -360:  swing RIGHT,  center X = -22 → +22
--   Z -360 → -580:  return centre, center X = +22 →  0

local function _cX(z)
	if z >= 0 then
		return 0
	elseif z >= -180 then
		return -22 * (-z / 180)
	elseif z >= -360 then
		local t = (-z - 180) / 180
		return -22 + 44 * t
	elseif z >= -580 then
		local t = (-z - 360) / 220
		return 22 - 22 * t
	end
	return 0
end

-- ─── Water plane ─────────────────────────────────────────────────────────────

local function _buildWater(root)
	_part(root, {
		Name = "OceanFloor", Size = Vector3.new(800, 2, 1800),
		Position = Vector3.new(0, WATER_Y - 14, 0),
		Color = Color3.fromRGB(8, 35, 90), Material = Enum.Material.SmoothPlastic,
		CanCollide = false, CastShadow = false,
	})
	_part(root, {
		Name = "WaterVolume", Size = Vector3.new(700, 12, 1700),
		Position = Vector3.new(0, WATER_Y - 8, 0),
		Color = Color3.fromRGB(12, 55, 140), Material = Enum.Material.SmoothPlastic,
		Transparency = 0.15, CanCollide = false, CastShadow = false,
	})
	_part(root, {
		Name = "WaterPlane", Size = Vector3.new(600, 4, 1600),
		Position = Vector3.new(0, WATER_Y - 2, 0),
		Color = Color3.fromRGB(25, 105, 210), Material = MAT.WATER,
		Transparency = 0.35, CanCollide = false,
	})
	_part(root, {
		Name = "WaterShimmer", Size = Vector3.new(600, 0.25, 1600),
		Position = Vector3.new(0, WATER_Y, 0),
		Color = Color3.fromRGB(120, 200, 255), Material = Enum.Material.Neon,
		Transparency = 0.82, CanCollide = false, CastShadow = false,
	})
end

-- ─── Farm island (Z = 250 to 500) ────────────────────────────────────────────

local function _buildFarmIsland(root)
	_part(root, {
		Name = "FarmIsland", Size = Vector3.new(160, 6, 260),
		Position = Vector3.new(0, WATER_Y - 1, 375),
		Color = C.SAND, Material = MAT.SAND,
	})
	_part(root, {
		Name = "FarmGrass", Size = Vector3.new(140, 1, 230),
		Position = Vector3.new(0, WATER_Y + 2.5, 375),
		Color = Color3.fromRGB(80, 160, 70), Material = Enum.Material.Grass,
	})

	local cols = { -50, -25, 0, 25, 50 }
	local rows = { 290, 330 }
	for _, row in ipairs(rows) do
		for _, col in ipairs(cols) do
			local sp = _part(root, {
				Name = "FarmSpawnPoint", Size = Vector3.new(4, 0.5, 4),
				Position = Vector3.new(col, WATER_Y + 3.5, row),
				Color = Color3.fromRGB(255, 220, 60), Material = MAT.NEON,
				CanCollide = false, Transparency = 0.5,
			})
			_tag(sp, "FarmSpawn")
		end
	end

	local rng = Random.new(99)
	for _ = 1, 8 do
		local tx = rng:NextNumber(-60, 60)
		local tz = rng:NextNumber(260, 490)
		local h  = rng:NextNumber(8, 14)
		_part(root, {
			Name = "PalmTrunk", Size = Vector3.new(1.2, h, 1.2),
			Position = Vector3.new(tx, WATER_Y + 2.5 + h / 2, tz),
			Color = C.PALM_TRUNK, Material = MAT.WOOD, CanCollide = false,
		})
		for i = 0, 4 do
			local angle = (i / 5) * math.pi * 2
			_part(root, {
				Name = "PalmLeaf", Size = Vector3.new(0.6, 0.3, 8),
				Color = C.PALM_LEAF, Material = MAT.LEAVES,
				CFrame = CFrame.new(tx + math.cos(angle)*2, WATER_Y + 2.5 + h + 0.5, tz + math.sin(angle)*2)
					* CFrame.Angles(0, angle, math.rad(-20)),
				CanCollide = false,
			})
		end
	end
end

-- ─── Buoyancy zones ──────────────────────────────────────────────────────────
-- Expanded X width (110) covers course shifts: ±(22 center + 25 half-width) = ±47.

local function _buildBuoyancyZones(root)
	local z1 = _part(root, {
		Name = "BuoyancyZone_Main", Size = Vector3.new(110, 6, 900),
		Position = Vector3.new(0, WATER_Y - 1, -200), CanCollide = false, Transparency = 1,
	})
	_tag(z1, "BuoyancyZone")

	local z2 = _part(root, {
		Name = "BuoyancyZone_Start", Size = Vector3.new(110, 6, 200),
		Position = Vector3.new(0, WATER_Y - 1, 130), CanCollide = false, Transparency = 1,
	})
	_tag(z2, "BuoyancyZone")
end

-- ─── S-curve course buoys ─────────────────────────────────────────────────────
-- Each pair is offset by _cX(z) so boundaries follow the curve.

local function _buildCourseBuoys(root)
	local buoyIdx = 0
	for z = 180, -580, -BUOY_INTERVAL do
		buoyIdx = buoyIdx + 1
		local isRedSide = (buoyIdx % 2 == 0)
		local cx = _cX(z)

		for _, side in ipairs({ -1, 1 }) do
			local isRed = (side == 1) == isRedSide
			local bx = cx + side * COURSE_HALF_W

			local body = _part(root, {
				Name     = "Buoy_" .. buoyIdx .. (side > 0 and "R" or "L"),
				Size     = Vector3.new(2.5, 4, 2.5),
				Position = Vector3.new(bx, WATER_Y + 2, z),
				Color    = isRed and C.BUOY_RED or C.BUOY_WHITE,
				Material = MAT.NEON,
			})
			_tag(body, "Obstacle")

			_part(root, {
				Name     = "BuoyChain_" .. buoyIdx .. (side > 0 and "R" or "L"),
				Size     = Vector3.new(0.3, 4, 0.3),
				Position = Vector3.new(bx, WATER_Y - 2, z),
				Color    = Color3.fromRGB(80, 80, 80), Material = MAT.METAL,
				CanCollide = false,
			})
		end
	end
end

-- ─── Turn markers ─────────────────────────────────────────────────────────────
-- Neon arches positioned on the course centerline at each S-curve apex.

local function _buildTurnMarkers(root)
	local turns = {
		{ 0,    _cX(-90)  },   -- first swing apex (use midpoint Z=-90 for visual centering)
		{ -180, _cX(-180) },   -- second apex: X=-22
		{ -360, _cX(-360) },   -- third apex: X=+22
		{ -520, _cX(-520) },   -- finish approach
	}
	for i, t in ipairs(turns) do
		local tz = t[1]
		local cx = t[2]
		_part(root, {
			Name = "TurnArch_L" .. i, Size = Vector3.new(2, 12, 2),
			Position = Vector3.new(cx - COURSE_HALF_W - 2, WATER_Y + 6, tz),
			Color = Color3.fromRGB(40, 200, 255), Material = MAT.NEON, CanCollide = false,
		})
		_part(root, {
			Name = "TurnArch_R" .. i, Size = Vector3.new(2, 12, 2),
			Position = Vector3.new(cx + COURSE_HALF_W + 2, WATER_Y + 6, tz),
			Color = Color3.fromRGB(40, 200, 255), Material = MAT.NEON, CanCollide = false,
		})
		_part(root, {
			Name = "TurnArch_Top" .. i, Size = Vector3.new(COURSE_HALF_W * 2 + 8, 2, 2),
			Position = Vector3.new(cx, WATER_Y + 12, tz),
			Color = Color3.fromRGB(40, 200, 255), Material = MAT.NEON, CanCollide = false,
		})
	end
end

-- ─── Drift corner zones ───────────────────────────────────────────────────────
-- 3 trigger volumes at S-curve apexes; cyan wake rings mark them visually.

local function _buildDriftCorners(root)
	local corners = {
		{ -180, _cX(-180) },   -- apex 1: X=-22 (left)
		{ -360, _cX(-360) },   -- apex 2: X=+22 (right)
		{ -470, _cX(-470) },   -- apex 3: X≈+9  (return leg)
	}
	for i, c in ipairs(corners) do
		local cz, cx = c[1], c[2]

		-- Cyan wake ring (visual)
		_part(root, {
			Name = "WakeRing_" .. i, Size = Vector3.new(COURSE_HALF_W * 2 + 4, 0.3, 42),
			Position = Vector3.new(cx, WATER_Y + 0.3, cz),
			Color = C.DRIFT_GLOW, Material = MAT.NEON,
			CanCollide = false, CastShadow = false, Transparency = 0.52,
		})

		-- Invisible trigger
		local trigger = _part(root, {
			Name = "DriftCorner_" .. i, Size = Vector3.new(COURSE_HALF_W * 2 + 22, 8, 46),
			Position = Vector3.new(cx, WATER_Y + 1, cz),
			CanCollide = false, Transparency = 1,
		})
		_tag(trigger, "DriftCorner")
	end
end

-- ─── Boost pads (on S-curve centerline) ──────────────────────────────────────

local function _buildBoostPads(root)
	local padZs = { 60, -100, -280, -450 }
	for i, z in ipairs(padZs) do
		local cx = _cX(z)
		local pad = _part(root, {
			Name = "BoostPad_" .. i, Size = Vector3.new(12, 0.4, 8),
			Position = Vector3.new(cx, WATER_Y + 0.4, z),
			Color = C.BOOST, Material = MAT.NEON, CanCollide = false,
		})
		_tag(pad, "BoostPad")
		_part(root, {
			Name = "BoostRing_" .. i, Size = Vector3.new(16, 0.2, 12),
			Position = Vector3.new(cx, WATER_Y + 0.3, z),
			Color = Color3.fromRGB(100, 240, 255), Material = MAT.NEON,
			Transparency = 0.5, CanCollide = false,
		})
	end
end

-- ─── Start grid ──────────────────────────────────────────────────────────────

local function _buildStartGrid(root)
	_part(root, {
		Name = "StartDock", Size = Vector3.new(COURSE_HALF_W * 2, 1, 20),
		Position = Vector3.new(0, WATER_Y + 0.5, 200),
		Color = C.DOCK, Material = MAT.WOOD,
	})
	for side = -1, 1, 2 do
		_part(root, {
			Name = "StartPole" .. (side > 0 and "R" or "L"),
			Size = Vector3.new(1.5, 10, 1.5),
			Position = Vector3.new(side * (COURSE_HALF_W + 1), WATER_Y + 5, 192),
			Color = C.BUOY_WHITE, Material = MAT.METAL,
		})
	end
	_part(root, {
		Name = "StartBanner", Size = Vector3.new(COURSE_HALF_W * 2 + 4, 2, 1),
		Position = Vector3.new(0, WATER_Y + 10, 192),
		Color = Color3.fromRGB(255, 220, 40), Material = MAT.NEON, CanCollide = false,
	})
end

-- ─── Finish line ─────────────────────────────────────────────────────────────

local function _buildFinishLine(root)
	for col = -COURSE_HALF_W, COURSE_HALF_W - 4, 4 do
		for row = 0, 1 do
			_part(root, {
				Name = "FinishTile", Size = Vector3.new(4, 0.4, 4),
				Position = Vector3.new(col + 2, WATER_Y + 0.4, -596 + row * 4),
				Color = (math.floor((col + COURSE_HALF_W) / 4) + row) % 2 == 0
					and Color3.new(1,1,1) or Color3.new(0,0,0),
				Material = MAT.METAL, CanCollide = false,
			})
		end
	end

	local finish = _part(root, {
		Name = "FinishLine", Size = Vector3.new(COURSE_HALF_W * 2, 8, 2),
		Position = Vector3.new(0, WATER_Y + 4, -598),
		CanCollide = false, Transparency = 1,
	})
	_tag(finish, "FinishLine")

	for side = -1, 1, 2 do
		_part(root, {
			Name = "FinishPole" .. (side > 0 and "R" or "L"),
			Size = Vector3.new(1.5, 16, 1.5),
			Position = Vector3.new(side * (COURSE_HALF_W + 2), WATER_Y + 8, -598),
			Color = C.BUOY_WHITE, Material = MAT.METAL,
		})
	end
	_part(root, {
		Name = "FinishArch", Size = Vector3.new(COURSE_HALF_W * 2 + 6, 2, 1.5),
		Position = Vector3.new(0, WATER_Y + 16, -598),
		Color = Color3.fromRGB(40, 160, 255), Material = MAT.NEON, CanCollide = false,
	})
end

-- ─── Main build ──────────────────────────────────────────────────────────────

local function buildOcean()
	local root = _getOrCreateMap()

	local farmSub  = Instance.new("Model"); farmSub.Name  = "FarmArea";  farmSub.Parent  = root
	local trackSub = Instance.new("Model"); trackSub.Name = "RaceTrack"; trackSub.Parent = root

	_buildWater(root)
	_buildBuoyancyZones(root)
	_buildFarmIsland(farmSub)
	_buildCourseBuoys(trackSub)
	_buildTurnMarkers(trackSub)
	_buildBoostPads(trackSub)
	_buildDriftCorners(trackSub)
	_buildStartGrid(trackSub)
	_buildFinishLine(trackSub)

	CollectionService:AddTag(root, "BiomeMap")
	root:SetAttribute("Biome", "OCEAN")

	print("[OceanMapBuilder] Built OCEAN map (" .. #root:GetChildren() .. " objects)")
	return root
end

local ok, err = pcall(buildOcean)
if not ok then warn("[OceanMapBuilder] Build failed: " .. tostring(err)) end
