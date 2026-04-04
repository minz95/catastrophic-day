-- ForestMapBuilder.server.lua
-- Procedurally builds the FOREST biome map at runtime:
--   - Farm area (item scatter zone)
--   - Race track with mud zones, drift corners, jump ramps, boost pads
--   - Decorative trees and foliage
-- Resolves: Issue #8

local CollectionService = game:GetService("CollectionService")

local MapBuilders = {}

-- ─── Colour palette ───────────────────────────────────────────────────────────

local C = {
	GRASS       = Color3.fromRGB(76,  120, 50),
	DIRT        = Color3.fromRGB(120, 85,  50),
	MUD         = Color3.fromRGB(80,  55,  30),
	TRACK       = Color3.fromRGB(60,  55,  50),
	TRACK_EDGE  = Color3.fromRGB(240, 240, 240),
	TREE_TRUNK  = Color3.fromRGB(100, 70,  40),
	TREE_LEAF   = Color3.fromRGB(55,  130, 45),
	TREE_LEAF2  = Color3.fromRGB(40,  100, 35),
	FINISH_LINE = Color3.fromRGB(240, 240, 240),
	BOOST_PAD   = Color3.fromRGB(255, 200, 40),
	RAMP        = Color3.fromRGB(160, 130, 80),
	BARRIER     = Color3.fromRGB(200, 60,  40),
}

local MAT = {
	GRASS  = Enum.Material.Grass,
	DIRT   = Enum.Material.Ground,
	MUD    = Enum.Material.Ground,
	TRACK  = Enum.Material.Asphalt,
	WOOD   = Enum.Material.Wood,
	LEAVES = Enum.Material.LeafyGrass,
	METAL  = Enum.Material.Metal,
	NEON   = Enum.Material.Neon,
}

-- ─── Part factory ─────────────────────────────────────────────────────────────

local function _part(parent, props)
	local p = Instance.new("Part")
	p.Anchored    = true
	p.CanCollide  = true
	p.CastShadow  = true
	for k, v in pairs(props) do
		pcall(function() p[k] = v end)
	end
	p.Parent = parent
	return p
end

local function _wedge(parent, props)
	local p = Instance.new("WedgePart")
	p.Anchored   = true
	p.CanCollide = true
	for k, v in pairs(props) do
		pcall(function() p[k] = v end)
	end
	p.Parent = parent
	return p
end

local function _tag(part, tagName)
	CollectionService:AddTag(part, tagName)
end

-- ─── Map root ─────────────────────────────────────────────────────────────────

local function _getOrCreateMap()
	local maps = workspace:FindFirstChild("Maps") or (function()
		local f = Instance.new("Folder"); f.Name = "Maps"; f.Parent = workspace; return f
	end)()
	local existing = maps:FindFirstChild("ForestMap")
	if existing then existing:Destroy() end
	local model = Instance.new("Model")
	model.Name   = "ForestMap"
	model.Parent = maps
	return model
end

-- ─── Ground plane ────────────────────────────────────────────────────────────

local function _buildGround(root)
	-- Large grass plane
	_part(root, {
		Name     = "Ground",
		Size     = Vector3.new(300, 4, 1400),
		Position = Vector3.new(0, -2, 0),
		Color    = C.GRASS,
		Material = MAT.GRASS,
	})
end

-- ─── Farm area (Z = 200 to 500) ──────────────────────────────────────────────
-- Open field where items scatter. Slightly elevated from track.

local function _buildFarmArea(root)
	-- Dirt patch
	_part(root, {
		Name     = "FarmGround",
		Size     = Vector3.new(200, 2, 300),
		Position = Vector3.new(0, 0, 350),
		Color    = C.DIRT,
		Material = MAT.DIRT,
	})

	-- Farm boundary fence (4 sides, simple barriers)
	local fenceData = {
		{ Vector3.new(200, 6, 2), Vector3.new(0,   3, 200) },  -- near
		{ Vector3.new(200, 6, 2), Vector3.new(0,   3, 500) },  -- far
		{ Vector3.new(2,   6, 302), Vector3.new(-100, 3, 350) },  -- left
		{ Vector3.new(2,   6, 302), Vector3.new(100,  3, 350) },  -- right
	}
	for _, fd in ipairs(fenceData) do
		local f = _part(root, {
			Name     = "Fence",
			Size     = fd[1],
			Position = fd[2],
			Color    = C.TREE_TRUNK,
			Material = MAT.WOOD,
		})
		f.CanCollide = false
		f.Transparency = 0.3
	end

	-- FarmSpawn points (10 positions, tagged)
	local cols = { -80, -40, 0, 40, 80 }
	local rows = { 280, 320 }
	for _, row in ipairs(rows) do
		for _, col in ipairs(cols) do
			local sp = _part(root, {
				Name      = "FarmSpawnPoint",
				Size      = Vector3.new(4, 0.5, 4),
				Position  = Vector3.new(col, 1.5, row),
				Color     = Color3.fromRGB(255, 220, 60),
				Material  = MAT.NEON,
				CanCollide = false,
				CastShadow = false,
				Transparency = 0.5,
			})
			_tag(sp, "FarmSpawn")
		end
	end
end

-- ─── Race track ──────────────────────────────────────────────────────────────
-- Straight Z axis: start Z=+600, finish Z=-600 (1200 studs total)
-- Track width: 30 studs. Curves handled with angled sections.

local function _buildTrack(root)
	-- Main straight sections
	local straights = {
		-- { centerX, centerZ, length, rotation_Y_deg }
		{ 0,    100,  200, 0  },   -- section 1: straight toward craft area
		{ 0,   -100,  200, 0  },   -- section 2
		{ 0,   -300,  200, 0  },   -- section 3
		{ 0,   -500,  200, 0  },   -- section 4
		{ 0,   -600,   60, 0  },   -- near finish
	}

	for i, s in ipairs(straights) do
		_part(root, {
			Name     = "TrackStraight_" .. i,
			Size     = Vector3.new(30, 1, s[3]),
			Position = Vector3.new(s[1], 0.5, s[2]),
			Color    = C.TRACK,
			Material = MAT.TRACK,
		})

		-- White edge lines
		for _, side in ipairs({ -14, 14 }) do
			_part(root, {
				Name     = "TrackEdge_" .. i,
				Size     = Vector3.new(1, 1.1, s[3]),
				Position = Vector3.new(s[1] + side, 0.5, s[2]),
				Color    = C.TRACK_EDGE,
				Material = MAT.METAL,
				CanCollide = false,
			})
		end
	end

	-- Connector from farm exit to track start
	_part(root, {
		Name     = "TrackStart",
		Size     = Vector3.new(30, 1, 200),
		Position = Vector3.new(0, 0.5, 200),
		Color    = C.TRACK,
		Material = MAT.TRACK,
	})
end

-- ─── Mud zones (FOREST hazard) ────────────────────────────────────────────────

local function _buildMudZones(root)
	local mudZoneData = {
		{ 0, 0.6, 20,  30, -50  },   -- zone 1: wide center strip
		{ 8, 0.6, 14,  20, -200 },   -- zone 2: off-center
		{ -5,0.6, 18,  25, -380 },   -- zone 3
		{ 3, 0.6, 22,  35, -480 },   -- zone 4: before finish
	}
	for i, mz in ipairs(mudZoneData) do
		local mud = _part(root, {
			Name     = "MudZone_" .. i,
			Size     = Vector3.new(mz[3], 0.4, mz[4]),
			Position = Vector3.new(mz[1], mz[2], mz[5]),
			Color    = C.MUD,
			Material = MAT.MUD,
		})
		mud.CanCollide = false
		_tag(mud, "MudZone")
	end
end

-- ─── Drift corners ────────────────────────────────────────────────────────────

local function _buildDriftCorners(root)
	-- 4 banked turns along the track
	local corners = {
		{ -15, 1, -80,  40, 10, 4,  -15 },   -- x, y, z, lenZ, lenX, height, bankX
		{  15, 1, -180, 40, 10, 4,   15 },
		{ -15, 1, -320, 40, 10, 4,  -15 },
		{  15, 1, -460, 40, 10, 4,   15 },
	}
	for i, c in ipairs(corners) do
		local corner = _part(root, {
			Name     = "DriftCorner_" .. i,
			Size     = Vector3.new(c[5] + 30, c[6], c[4]),
			Position = Vector3.new(c[1], c[2], c[3]),
			Color    = Color3.fromRGB(70, 65, 55),
			Material = MAT.TRACK,
		})
		-- Slight bank angle
		corner.CFrame = CFrame.new(c[1], c[2], c[3]) * CFrame.Angles(0, 0, math.rad(c[7] > 0 and 8 or -8))
		_tag(corner, "DriftCorner")

		-- Warning chevron markers
		for side = -1, 1, 2 do
			_part(root, {
				Name     = "Chevron_" .. i,
				Size     = Vector3.new(1.5, 3, 0.5),
				Position = Vector3.new(c[1] + side * 16, c[2] + 2, c[3]),
				Color    = Color3.fromRGB(255, 140, 0),
				Material = MAT.NEON,
				CanCollide = false,
			})
		end
	end
end

-- ─── Jump ramps ───────────────────────────────────────────────────────────────

local function _buildJumpRamps(root)
	local ramps = {
		{ 0, 0, -130 },
		{ 0, 0, -400 },
	}
	for i, r in ipairs(ramps) do
		-- Ramp approach
		local ramp = _wedge(root, {
			Name     = "JumpRamp_" .. i,
			Size     = Vector3.new(20, 5, 12),
			Position = Vector3.new(r[1], r[2] + 2.5, r[3]),
			Color    = C.RAMP,
			Material = MAT.DIRT,
		})
		ramp.CFrame = CFrame.new(r[1], r[2] + 2.5, r[3]) * CFrame.Angles(0, math.pi, 0)

		-- Landing pad
		_part(root, {
			Name     = "LandingPad_" .. i,
			Size     = Vector3.new(20, 1, 20),
			Position = Vector3.new(r[1], r[2] + 0.5, r[3] - 18),
			Color    = C.RAMP,
			Material = MAT.DIRT,
		})

		-- Jump zone tag
		local jz = _part(root, {
			Name     = "JumpZone_" .. i,
			Size     = Vector3.new(20, 8, 12),
			Position = Vector3.new(r[1], r[2] + 4, r[3]),
			CanCollide = false,
			Transparency = 1,
		})
		_tag(jz, "JumpZone")
	end
end

-- ─── Boost pads ───────────────────────────────────────────────────────────────

local function _buildBoostPads(root)
	local pads = {
		{ 0, -30  },
		{ 0, -260 },
		{ 0, -370 },
		{ 0, -540 },
	}
	for i, pd in ipairs(pads) do
		local pad = _part(root, {
			Name     = "BoostPad_" .. i,
			Size     = Vector3.new(10, 0.3, 6),
			Position = Vector3.new(pd[1], 0.7, pd[2]),
			Color    = C.BOOST_PAD,
			Material = MAT.NEON,
			CanCollide = false,
		})
		_tag(pad, "BoostPad")

		-- Arrow indicator
		local arrow = _wedge(root, {
			Name     = "BoostArrow_" .. i,
			Size     = Vector3.new(4, 0.4, 4),
			Position = Vector3.new(pd[1], 0.9, pd[2] - 3),
			Color    = Color3.fromRGB(255, 240, 80),
			Material = MAT.NEON,
			CanCollide = false,
		})
		arrow.CFrame = CFrame.new(pd[1], 0.9, pd[2] - 3) * CFrame.Angles(0, math.pi, 0)
	end
end

-- ─── Obstacles ───────────────────────────────────────────────────────────────

local function _buildObstacles(root)
	local obstacles = {
		{ 8,  2, -60  },
		{ -8, 2, -160 },
		{ 6,  2, -290 },
		{ -6, 2, -430 },
		{ 0,  2, -510 },
	}
	for i, ob in ipairs(obstacles) do
		local obs = _part(root, {
			Name     = "Obstacle_" .. i,
			Size     = Vector3.new(5, 4, 5),
			Position = Vector3.new(ob[1], ob[2], ob[3]),
			Color    = C.BARRIER,
			Material = Enum.Material.SmoothPlastic,
		})
		_tag(obs, "Obstacle")

		-- Stripe pattern (decorative smaller parts)
		_part(root, {
			Name     = "ObstacleStripe_" .. i,
			Size     = Vector3.new(5.1, 1, 5.1),
			Position = Vector3.new(ob[1], ob[2] + 0.5, ob[3]),
			Color    = Color3.fromRGB(240, 240, 40),
			Material = MAT.NEON,
			CanCollide = false,
		})
	end
end

-- ─── Trees ───────────────────────────────────────────────────────────────────

local function _buildTrees(root)
	local rng = Random.new(42)  -- seeded for consistency
	local treeZones = {
		-- { xMin, xMax, zMin, zMax, count }
		{ -150, -25, -600, 600, 40 },   -- left side
		{   25, 150, -600, 600, 40 },   -- right side
		{ -100, 100, 400, 600, 15 },    -- behind farm
	}

	for _, tz in ipairs(treeZones) do
		for _ = 1, tz[5] do
			local tx = rng:NextNumber(tz[1], tz[2])
			local tz2 = rng:NextNumber(tz[3], tz[4])
			local height = rng:NextNumber(10, 22)
			local radius = rng:NextNumber(3, 7)

			-- Trunk
			_part(root, {
				Name     = "TreeTrunk",
				Size     = Vector3.new(radius * 0.4, height, radius * 0.4),
				Position = Vector3.new(tx, height / 2, tz2),
				Color    = C.TREE_TRUNK,
				Material = MAT.WOOD,
				CanCollide = false,
			})

			-- Canopy (2 spherical blobs)
			local leafColour = (rng:NextNumber() > 0.4) and C.TREE_LEAF or C.TREE_LEAF2
			for layer = 0, 1 do
				_part(root, {
					Name     = "TreeLeaves",
					Size     = Vector3.new(radius * 2, radius * 1.5, radius * 2),
					Position = Vector3.new(tx, height + radius * 0.8 * layer, tz2),
					Color    = leafColour,
					Material = MAT.LEAVES,
					CanCollide = false,
					CastShadow = false,
				})
			end
		end
	end
end

-- ─── Finish line ─────────────────────────────────────────────────────────────

local function _buildFinishLine(root)
	-- Checkered finish strip
	for col = -14, 14, 4 do
		for row = 0, 1 do
			_part(root, {
				Name     = "FinishTile",
				Size     = Vector3.new(4, 0.3, 4),
				Position = Vector3.new(col, 0.8, -598 + row * 4),
				Color    = (math.floor(col / 4) + row) % 2 == 0
					and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),
				Material = MAT.METAL,
				CanCollide = false,
			})
		end
	end

	-- Finish line trigger (invisible sensor)
	local finish = _part(root, {
		Name       = "FinishLine",
		Size       = Vector3.new(30, 8, 2),
		Position   = Vector3.new(0, 4, -599),
		CanCollide = false,
		Transparency = 1,
	})
	_tag(finish, "FinishLine")

	-- Arch poles
	for side = -1, 1, 2 do
		_part(root, {
			Name     = "FinishPole",
			Size     = Vector3.new(1.5, 14, 1.5),
			Position = Vector3.new(side * 16, 7, -599),
			Color    = C.FINISH_LINE,
			Material = MAT.METAL,
		})
	end
	-- Arch bar
	_part(root, {
		Name     = "FinishArch",
		Size     = Vector3.new(34, 2, 1.5),
		Position = Vector3.new(0, 14, -599),
		Color    = Color3.fromRGB(240, 60, 60),
		Material = MAT.NEON,
		CanCollide = false,
	})
end

-- ─── Start grid ──────────────────────────────────────────────────────────────

local function _buildStartGrid(root)
	-- Grid markers: 2 rows × 5 columns
	local cols = { -16, -8, 0, 8, 16 }
	local rows = { 165, 180 }
	for row, z in ipairs(rows) do
		for col, x in ipairs(cols) do
			local idx = (row - 1) * 5 + col
			-- Coloured grid square
			_part(root, {
				Name     = "StartBox_" .. idx,
				Size     = Vector3.new(7, 0.2, 7),
				Position = Vector3.new(x, 0.6, z),
				Color    = Color3.fromRGB(60, 120, 255),
				Material = MAT.NEON,
				CanCollide = false,
			})
			-- Number marker
			local numPart = _part(root, {
				Name     = "StartNum_" .. idx,
				Size     = Vector3.new(2, 2, 0.3),
				Position = Vector3.new(x, 1.5, z + 3),
				Color    = Color3.new(1, 1, 1),
				Material = MAT.NEON,
				CanCollide = false,
			})
		end
	end
end

-- ─── Main build function ─────────────────────────────────────────────────────

function MapBuilders.buildForest()
	local root = _getOrCreateMap()

	-- Sub-models so MapManager can toggle farm vs track visibility per phase
	local farmSub  = Instance.new("Model"); farmSub.Name  = "FarmArea";  farmSub.Parent  = root
	local trackSub = Instance.new("Model"); trackSub.Name = "RaceTrack"; trackSub.Parent = root

	_buildGround(root)           -- shared ground plane
	_buildTrees(root)            -- shared decoration
	_buildFarmArea(farmSub)
	_buildTrack(trackSub)
	_buildMudZones(trackSub)
	_buildDriftCorners(trackSub)
	_buildJumpRamps(trackSub)
	_buildBoostPads(trackSub)
	_buildObstacles(trackSub)
	_buildFinishLine(trackSub)
	_buildStartGrid(trackSub)

	-- Tag the whole model
	CollectionService:AddTag(root, "BiomeMap")
	root:SetAttribute("Biome", "FOREST")

	print("[ForestMapBuilder] Built FOREST map (" .. #root:GetChildren() .. " objects)")
	return root
end

-- ─── Auto-build when this script runs (called by MapManager) ─────────────────
-- Wrapped in pcall so errors don't crash the server
local ok, err = pcall(MapBuilders.buildForest)
if not ok then
	warn("[ForestMapBuilder] Build failed: " .. tostring(err))
end

return MapBuilders
