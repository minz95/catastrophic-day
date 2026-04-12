-- ForestMapBuilder.server.lua
-- Procedurally builds the FOREST biome map:
--   - Farm area with crop rows and barn silhouette
--   - S-curve race track (alternating left/right offsets via node-based layout)
--   - River-crossing bridge section, rock pile obstacles, mud zones
--   - 3 distinct tree species (pine, oak, birch) for visual variety
-- Resolves: Issue #8, #83, #66, #87, #97

local CollectionService = game:GetService("CollectionService")

local C = {
	GRASS        = Color3.fromRGB(76,  120, 50),
	DIRT         = Color3.fromRGB(120, 85,  50),
	MUD          = Color3.fromRGB(80,  55,  30),
	TRACK        = Color3.fromRGB(55,  50,  45),
	TRACK_EDGE   = Color3.fromRGB(240, 240, 240),
	RIVER        = Color3.fromRGB(55,  110, 200),
	BRIDGE       = Color3.fromRGB(140, 100, 55),
	ROCK         = Color3.fromRGB(110, 100, 90),
	ROCK_DARK    = Color3.fromRGB(80,  72,  65),
	BOOST_PAD    = Color3.fromRGB(255, 200, 40),
	RAMP         = Color3.fromRGB(150, 125, 80),
	BARRIER      = Color3.fromRGB(200, 60,  40),
	BARN_WALL    = Color3.fromRGB(165, 55,  40),
	BARN_ROOF    = Color3.fromRGB(80,  60,  45),
	CROP_GREEN   = Color3.fromRGB(70,  160, 55),
	FENCE        = Color3.fromRGB(180, 150, 100),

	PINE_TRUNK   = Color3.fromRGB(85,  60,  40),
	PINE_LEAF    = Color3.fromRGB(35,  100, 35),
	PINE_LEAF2   = Color3.fromRGB(25,  80,  28),
	OAK_TRUNK    = Color3.fromRGB(110, 75,  45),
	OAK_LEAF     = Color3.fromRGB(65,  140, 45),
	OAK_LEAF2    = Color3.fromRGB(50,  110, 35),
	BIRCH_TRUNK  = Color3.fromRGB(215, 210, 195),
	BIRCH_LEAF   = Color3.fromRGB(95,  175, 65),
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
	ROCK   = Enum.Material.Rock,
	WATER  = Enum.Material.SmoothPlastic,
}

local function _part(parent, props)
	local p = Instance.new("Part")
	p.Anchored   = true
	p.CanCollide = true
	p.CastShadow = true
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
	local existing = maps:FindFirstChild("ForestMap")
	if existing then existing:Destroy() end
	local model = Instance.new("Model")
	model.Name   = "ForestMap"
	model.Parent = maps
	return model
end

-- ─── Segment CFrame helper ────────────────────────────────────────────────────
-- Returns a CFrame at the midpoint of A→B oriented so local +Z runs along A→B.

local function _segCF(ax, az, bx, bz)
	local mx, mz = (ax + bx) * 0.5, (az + bz) * 0.5
	local rotY   = math.atan2(bx - ax, bz - az)
	return CFrame.new(mx, 0.5, mz) * CFrame.Angles(0, rotY, 0)
end

local function _segLen(ax, az, bx, bz)
	local dx, dz = bx - ax, bz - az
	return math.sqrt(dx * dx + dz * dz)
end

-- ─── Ground plane ─────────────────────────────────────────────────────────────

local function _buildGround(root)
	_part(root, {
		Name     = "Ground",
		Size     = Vector3.new(400, 4, 1500),
		Position = Vector3.new(0, -2, 0),
		Color    = C.GRASS,
		Material = MAT.GRASS,
	})
	-- Darker undergrowth strips for texture
	local rng = Random.new(77)
	for _ = 1, 30 do
		_part(root, {
			Name         = "GrassDetail",
			Size         = Vector3.new(rng:NextNumber(12,35), 0.3, rng:NextNumber(8,22)),
			Position     = Vector3.new(rng:NextNumber(-180,180), 0.2, rng:NextNumber(-600,600)),
			Color        = Color3.fromRGB(55, 100, 38),
			Material     = MAT.GRASS,
			CanCollide   = false,
			CastShadow   = false,
		})
	end
end

-- ─── Farm area (Z = 200 to 500) ───────────────────────────────────────────────

local function _buildFarmArea(root)
	-- Dirt base
	_part(root, {
		Name     = "FarmGround",
		Size     = Vector3.new(200, 2, 300),
		Position = Vector3.new(0, 0, 350),
		Color    = C.DIRT,
		Material = MAT.DIRT,
	})

	-- Crop rows: thin green strips in a grid
	for row = 0, 6 do
		for col = -3, 3 do
			_part(root, {
				Name         = "CropRow",
				Size         = Vector3.new(18, 1.5, 3),
				Position     = Vector3.new(col * 22, 0.8, 280 + row * 30),
				Color        = C.CROP_GREEN,
				Material     = MAT.LEAVES,
				CanCollide   = false,
				CastShadow   = false,
			})
		end
	end

	-- Barn silhouette (left side of farm)
	_part(root, {  -- barn walls
		Name     = "BarnWall",
		Size     = Vector3.new(25, 14, 18),
		Position = Vector3.new(-75, 7, 360),
		Color    = C.BARN_WALL,
		Material = MAT.WOOD,
	})
	local barnRoof = _wedge(root, {  -- barn roof left slope
		Name     = "BarnRoof",
		Size     = Vector3.new(12, 8, 18),
		Position = Vector3.new(-81, 18, 360),
		Color    = C.BARN_ROOF,
		Material = MAT.WOOD,
		CanCollide = false,
	})
	barnRoof.CFrame = CFrame.new(-81, 18, 360) * CFrame.Angles(0, math.pi/2, 0)
	local barnRoof2 = _wedge(root, {  -- barn roof right slope
		Name     = "BarnRoof2",
		Size     = Vector3.new(12, 8, 18),
		Position = Vector3.new(-69, 18, 360),
		Color    = C.BARN_ROOF,
		Material = MAT.WOOD,
		CanCollide = false,
	})
	barnRoof2.CFrame = CFrame.new(-69, 18, 360) * CFrame.Angles(0, -math.pi/2, 0)
	-- Barn door
	_part(root, {
		Name     = "BarnDoor",
		Size     = Vector3.new(8, 10, 0.5),
		Position = Vector3.new(-75, 5, 351),
		Color    = C.BARN_ROOF,
		Material = MAT.WOOD,
		CanCollide = false,
	})

	-- Fence boundary
	local fences = {
		{ Vector3.new(202, 5, 1.5), Vector3.new(0,   2.5, 200) },
		{ Vector3.new(202, 5, 1.5), Vector3.new(0,   2.5, 500) },
		{ Vector3.new(1.5, 5, 302), Vector3.new(-101, 2.5, 350) },
		{ Vector3.new(1.5, 5, 302), Vector3.new( 101, 2.5, 350) },
	}
	for _, fd in ipairs(fences) do
		local f = _part(root, { Name="Fence", Size=fd[1], Position=fd[2], Color=C.FENCE, Material=MAT.WOOD })
		f.CanCollide   = false
		f.Transparency = 0.2
		-- Fence post caps
	end

	-- Fence posts (along near edge only for performance)
	for px = -100, 100, 20 do
		_part(root, {
			Name     = "FencePost",
			Size     = Vector3.new(1.5, 7, 1.5),
			Position = Vector3.new(px, 3.5, 200),
			Color    = C.FENCE,
			Material = MAT.WOOD,
		})
	end

	-- Spawn points
	local cols = { -80, -40, 0, 40, 80 }
	local rows = { 280, 320 }
	for _, row in ipairs(rows) do
		for _, col in ipairs(cols) do
			local sp = _part(root, {
				Name         = "FarmSpawnPoint",
				Size         = Vector3.new(4, 0.5, 4),
				Position     = Vector3.new(col, 1.5, row),
				Color        = Color3.fromRGB(255, 220, 60),
				Material     = MAT.NEON,
				CanCollide   = false,
				CastShadow   = false,
				Transparency = 0.5,
			})
			_tag(sp, "FarmSpawn")
		end
	end
end

-- ─── S-curve race track ───────────────────────────────────────────────────────
-- Node layout (X, Z) defines the track centerline.
-- Travel direction: decreasing Z (farm → finish).
--
--  (0,175) → (-22,45) → (-22,-65) → (20,-185) → (20,-305) → (-18,-415) → (-18,-510) → (0,-575)
--
-- This creates two full S-curves along the 750-stud stretch.

local TRACK_W = 30

local NODES = {
	{  0,   215 },  -- [1] pre-start straight (covers spawn area Z=195–203)
	{ -22,   45 },  -- [2] first curve, shifts left
	{ -22,  -65 },  -- [3] left straight
	{  20, -185 },  -- [4] S-curve, swings right
	{  20, -305 },  -- [5] right straight
	{ -18, -415 },  -- [6] second S-curve, swings left
	{ -18, -510 },  -- [7] left straight
	{   0, -605 },  -- [8] finish approach (extends past finish line at Z=-599)
}

local function _buildTrack(root)
	for i = 1, #NODES - 1 do
		local a, b   = NODES[i], NODES[i + 1]
		local segLen = _segLen(a[1], a[2], b[1], b[2])
		local cf     = _segCF(a[1], a[2], b[1], b[2])

		local seg = _part(root, {
			Name     = "TrackSeg_" .. i,
			Size     = Vector3.new(TRACK_W, 1, segLen),
			Color    = C.TRACK,
			Material = MAT.TRACK,
		})
		seg.CFrame = cf

		-- White edge lines + invisible boundary walls
		for _, side in ipairs({ -1, 1 }) do
			local edge = _part(root, {
				Name     = "TrackEdge",
				Size     = Vector3.new(1.5, 1.1, segLen),
				Color    = C.TRACK_EDGE,
				Material = MAT.METAL,
				CanCollide = false,
				CastShadow = false,
			})
			edge.CFrame = cf * CFrame.new(side * (TRACK_W / 2 - 1), 0.05, 0)

			-- Invisible collideable wall at the outer track boundary.
			-- Prevents vehicles from leaving the lane.
			local wall = _part(root, {
				Name         = "TrackBoundary",
				Size         = Vector3.new(1, 5, segLen),
				Transparency = 1,
				CastShadow   = false,
			})
			wall.CFrame = cf * CFrame.new(side * (TRACK_W / 2 + 0.5), 2.5, 0)
		end

		-- Dashed centre line every ~30 studs
		local dashCount = math.floor(segLen / 30)
		for d = 0, dashCount - 1 do
			local dz = -segLen / 2 + (d + 0.5) * (segLen / (dashCount > 0 and dashCount or 1))
			local dash = _part(root, {
				Name     = "CentreDash",
				Size     = Vector3.new(1, 1.15, 14),
				Color    = Color3.fromRGB(255, 220, 60),
				Material = MAT.NEON,
				CanCollide = false,
				CastShadow = false,
			})
			dash.CFrame = cf * CFrame.new(0, 0.05, dz)
		end
	end
end

-- ─── River crossing (between nodes 3 and 4, Z ≈ -125) ────────────────────────

local function _buildRiverBridge(root)
	-- Water channel running east-west (perpendicular to track)
	local riverZ = -125
	local waterPart = _part(root, {
		Name         = "RiverWater",
		Size         = Vector3.new(300, 2, 28),
		Position     = Vector3.new(0, -1, riverZ),
		Color        = C.RIVER,
		Material     = MAT.WATER,
		Transparency = 0.35,
		CanCollide   = false,
	})

	-- Riverbank embankments
	for _, side in ipairs({ -1, 1 }) do
		_wedge(root, {
			Name     = "RiverBank",
			Size     = Vector3.new(300, 3, 10),
			Position = Vector3.new(0, -0.5, riverZ + side * 19),
			Color    = C.DIRT,
			Material = MAT.DIRT,
		})
	end

	-- Wooden bridge decking over the track portion
	-- The track crosses at approximately X = -1 (midpoint between nodes 3 and 4)
	for plank = -12, 12, 4 do
		_part(root, {
			Name     = "BridgePlank",
			Size     = Vector3.new(4, 1.5, 28),
			Position = Vector3.new(plank, 0.75, riverZ),
			Color    = C.BRIDGE,
			Material = MAT.WOOD,
		})
	end

	-- Bridge railings
	for _, side in ipairs({ -1, 1 }) do
		_part(root, {
			Name     = "BridgeRailing",
			Size     = Vector3.new(0.6, 3, 30),
			Position = Vector3.new(side * 15.5, 2, riverZ),
			Color    = C.BRIDGE,
			Material = MAT.WOOD,
			CanCollide = false,
		})
		-- Railing posts
		for pz = -12, 12, 8 do
			_part(root, {
				Name     = "BridgePost",
				Size     = Vector3.new(1.2, 4, 1.2),
				Position = Vector3.new(side * 15.5, 2, riverZ + pz),
				Color    = C.BRIDGE,
				Material = MAT.WOOD,
			})
		end
	end

	-- Splash zone tag (vehicles entering water area near bridge edges get slowed)
	local splash = _part(root, {
		Name         = "MudZone_Bridge",
		Size         = Vector3.new(10, 2, 28),
		Position     = Vector3.new(-22, 0.6, riverZ),  -- water near left edge of track
		Color        = C.RIVER,
		Material     = MAT.WATER,
		CanCollide   = false,
		Transparency = 0.6,
	})
	_tag(splash, "MudZone")
end

-- ─── Mud zones ────────────────────────────────────────────────────────────────

local function _buildMudZones(root)
	local zones = {
		{ NODES[2][1] + 5,  1.2,  20, -50  },  -- near node 2
		{ NODES[4][1] - 6,  1.2,  18, -210 },  -- near node 4
		{ NODES[6][1] + 8,  1.2,  22, -440 },  -- near node 6
		{ NODES[7][1] - 4,  1.2,  16, -490 },  -- node 7 stretch
	}
	for i, mz in ipairs(zones) do
		local mud = _part(root, {
			Name     = "MudZone_" .. i,
			Size     = Vector3.new(mz[3], 0.4, mz[3]),
			Position = Vector3.new(mz[1], mz[2], mz[4]),
			Color    = C.MUD,
			Material = MAT.MUD,
		})
		mud.CanCollide = false
		_tag(mud, "MudZone")
	end
end

-- ─── Rock pile obstacles ──────────────────────────────────────────────────────

local function _buildRockPiles(root)
	local piles = {
		{ NODES[2][1] - 8, NODES[2][2] - 45 },  -- left side of node 2 section
		{ NODES[4][1] + 6, NODES[4][2] + 30 },  -- right side of node 4 section
		{ NODES[5][1] - 8, NODES[5][2] + 40 },  -- node 5 approach
		{ NODES[6][1] + 7, NODES[6][2] - 30 },  -- node 6 area
		{ NODES[7][1],     NODES[7][2] + 30 },  -- near finish
	}
	for i, rp in ipairs(piles) do
		local bx, bz = rp[1], rp[2]
		-- Base boulder
		local base = _part(root, {
			Name     = "RockBase_" .. i,
			Size     = Vector3.new(5, 4, 5),
			Position = Vector3.new(bx, 2, bz),
			Color    = C.ROCK,
			Material = MAT.ROCK,
		})
		_tag(base, "Obstacle")

		-- Stacked smaller rocks
		_wedge(root, {
			Name     = "RockChip1_" .. i,
			Size     = Vector3.new(3, 2, 3),
			Position = Vector3.new(bx + 2, 5, bz - 1),
			Color    = C.ROCK_DARK,
			Material = MAT.ROCK,
		})
		_part(root, {
			Name     = "RockChip2_" .. i,
			Size     = Vector3.new(2, 1.5, 2),
			Position = Vector3.new(bx - 1.5, 5.5, bz + 1.5),
			Color    = C.ROCK,
			Material = MAT.ROCK,
			CanCollide = false,
		})

		-- Moss accent
		_part(root, {
			Name     = "Moss_" .. i,
			Size     = Vector3.new(5.2, 0.6, 5.2),
			Position = Vector3.new(bx, 4.3, bz),
			Color    = Color3.fromRGB(55, 110, 40),
			Material = MAT.LEAVES,
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- ─── Jump ramp ────────────────────────────────────────────────────────────────

local function _buildJumpRamps(root)
	local ramps = {
		{ NODES[3][1], NODES[3][2] - 30 },  -- mid left section
		{ NODES[5][1], NODES[5][2] + 50 },  -- mid right section
	}
	for i, r in ipairs(ramps) do
		local ramp = _wedge(root, {
			Name     = "JumpRamp_" .. i,
			Size     = Vector3.new(TRACK_W, 5, 12),
			Color    = C.RAMP,
			Material = MAT.DIRT,
		})
		ramp.CFrame = CFrame.new(r[1], 3.5, r[2]) * CFrame.Angles(0, math.pi, 0)

		_part(root, {
			Name     = "LandingPad_" .. i,
			Size     = Vector3.new(TRACK_W, 1, 22),
			Position = Vector3.new(r[1], 1.5, r[2] - 17),  -- match track top = 1.0
			Color    = C.RAMP,
			Material = MAT.DIRT,
		})

		local jz = _part(root, {
			Name     = "JumpZone_" .. i,
			Size     = Vector3.new(TRACK_W, 10, 14),
			Position = Vector3.new(r[1], 6, r[2]),
			CanCollide  = false,
			Transparency = 1,
		})
		_tag(jz, "JumpZone")
	end
end

-- ─── Boost pads ───────────────────────────────────────────────────────────────

local function _buildBoostPads(root)
	local pads = {
		{ NODES[1][1], NODES[1][2] - 50 },   -- early track
		{ NODES[3][1], NODES[3][2] + 20 },   -- entering left section
		{ NODES[5][1], NODES[5][2] + 60 },   -- entering right section
		{ NODES[7][1], NODES[7][2] + 20 },   -- late section
	}
	for i, pd in ipairs(pads) do
		local pad = _part(root, {
			Name     = "BoostPad_" .. i,
			Size     = Vector3.new(10, 0.3, 6),
			Position = Vector3.new(pd[1], 1.15, pd[2]),  -- on track surface (track top = 1.0)
			Color    = C.BOOST_PAD,
			Material = MAT.NEON,
			CanCollide = false,
			CastShadow = false,
		})
		_tag(pad, "BoostPad")

		local arrow = _wedge(root, {
			Name     = "BoostArrow_" .. i,
			Size     = Vector3.new(4, 0.4, 5),
			Color    = Color3.fromRGB(255, 240, 80),
			Material = MAT.NEON,
			CanCollide = false,
			CastShadow = false,
		})
		arrow.CFrame = CFrame.new(pd[1], 1.35, pd[2] - 4) * CFrame.Angles(0, math.pi, 0)
	end
end

-- ─── Barrier chevrons at tight curves ─────────────────────────────────────────

local function _buildBarriers(root)
	-- Chevron warning barriers at the sharpest direction changes
	local curveNodes = { 2, 4, 6 }  -- node indices where S-curves peak
	for _, ni in ipairs(curveNodes) do
		local nx, nz = NODES[ni][1], NODES[ni][2]
		for _, side in ipairs({ -1, 1 }) do
			for post = -1, 1, 1 do
				_part(root, {
					Name     = "Chevron",
					Size     = Vector3.new(1.5, 4, 0.5),
					Position = Vector3.new(nx + side * 18, 2, nz + post * 18),
					Color    = Color3.fromRGB(240, 100, 30),
					Material = MAT.NEON,
					CanCollide = false,
					CastShadow = false,
				})
			end
		end
	end
end

-- ─── Three tree species ───────────────────────────────────────────────────────

local function _buildTrees(root)
	local rng = Random.new(42)

	local function _pine(parent, tx, tz)
		local h = rng:NextNumber(14, 24)
		_part(parent, {
			Name     = "PineTrunk",
			Size     = Vector3.new(1, h, 1),
			Position = Vector3.new(tx, h / 2, tz),
			Color    = C.PINE_TRUNK,
			Material = MAT.WOOD,
			CanCollide = false,
		})
		-- 3-layer cone canopy stacked at the UPPER portion of the trunk.
		-- Layer 0 (largest, bottom) at 65%, layer 1 at 80%, layer 2 (smallest, tip) at 95%.
		for layer = 0, 2 do
			local layerR = (3 - layer) * 2.5
			local layerY = h * (0.65 + layer * 0.15)  -- 65%, 80%, 95% of trunk height
			_part(parent, {
				Name     = "PineLeaf",
				Size     = Vector3.new(layerR * 2, layerR * 0.9, layerR * 2),
				Position = Vector3.new(tx, layerY, tz),
				Color    = layer % 2 == 0 and C.PINE_LEAF or C.PINE_LEAF2,
				Material = MAT.LEAVES,
				CanCollide = false,
				CastShadow = false,
			})
		end
	end

	local function _oak(parent, tx, tz)
		local h = rng:NextNumber(8, 15)
		local r = rng:NextNumber(4, 8)
		_part(parent, {
			Name     = "OakTrunk",
			Size     = Vector3.new(r * 0.45, h, r * 0.45),
			Position = Vector3.new(tx, h / 2, tz),
			Color    = C.OAK_TRUNK,
			Material = MAT.WOOD,
			CanCollide = false,
		})
		-- Wide rounded canopy (2 blobs)
		for blob = 0, 1 do
			_part(parent, {
				Name     = "OakLeaf",
				Size     = Vector3.new(r * 2.2, r * 1.4, r * 2.2),
				Position = Vector3.new(tx, h + r * (0.4 + blob * 0.5), tz),
				Color    = blob == 0 and C.OAK_LEAF or C.OAK_LEAF2,
				Material = MAT.LEAVES,
				CanCollide = false,
				CastShadow = false,
			})
		end
	end

	local function _birch(parent, tx, tz)
		local h = rng:NextNumber(10, 18)
		_part(parent, {
			Name     = "BirchTrunk",
			Size     = Vector3.new(0.7, h, 0.7),
			Position = Vector3.new(tx, h / 2, tz),
			Color    = C.BIRCH_TRUNK,
			Material = MAT.WOOD,
			CanCollide = false,
		})
		-- Small oval canopy
		_part(parent, {
			Name     = "BirchLeaf",
			Size     = Vector3.new(6, 7, 6),
			Position = Vector3.new(tx, h + 2, tz),
			Color    = C.BIRCH_LEAF,
			Material = MAT.LEAVES,
			CanCollide = false,
			CastShadow = false,
		})
	end

	local builders = { _pine, _pine, _oak, _oak, _birch }  -- weighted toward pine/oak
	local zones = {
		{ -55, -160, -600, 600, 38 },  -- left forest
		{  55,  160, -600, 600, 38 },  -- right forest
		{ -120, 120,  510, 660,  18 }, -- behind farm
	}

	for _, zone in ipairs(zones) do
		local xMin, xMax, zMin, zMax, count = zone[1], zone[2], zone[3], zone[4], zone[5]
		for _ = 1, count do
			local tx  = rng:NextNumber(xMin, xMax)
			local tz  = rng:NextNumber(zMin, zMax)
			local fn  = builders[rng:NextInteger(1, #builders)]
			fn(root, tx, tz)
		end
	end
end

-- ─── Finish line ──────────────────────────────────────────────────────────────

local function _buildFinishLine(root)
	for col = -14, 14, 4 do
		for row = 0, 1 do
			_part(root, {
				Name     = "FinishTile",
				Size     = Vector3.new(4, 0.3, 4),
				Position = Vector3.new(col, 1.15, -598 + row * 4),
				Color    = (math.floor(col / 4) + row) % 2 == 0
					and Color3.new(1,1,1) or Color3.new(0,0,0),
				Material = MAT.METAL,
				CanCollide = false,
			})
		end
	end

	local finish = _part(root, {
		Name         = "FinishLine",
		Size         = Vector3.new(32, 8, 2),
		Position     = Vector3.new(0, 5, -599),  -- bottom at Y=1 (track surface), top at Y=9
		CanCollide   = false,
		Transparency = 1,
	})
	_tag(finish, "FinishLine")

	for side = -1, 1, 2 do
		_part(root, {
			Name     = "FinishPole",
			Size     = Vector3.new(1.5, 16, 1.5),
			Position = Vector3.new(side * 17, 9, -599),
			Color    = Color3.fromRGB(240, 240, 240),
			Material = MAT.METAL,
		})
	end
	_part(root, {
		Name     = "FinishArch",
		Size     = Vector3.new(36, 2.5, 1.5),
		Position = Vector3.new(0, 18, -599),
		Color    = Color3.fromRGB(220, 55, 55),
		Material = MAT.NEON,
		CanCollide = false,
	})
	-- Checkered arch banner
	for bx = -16, 16, 8 do
		_part(root, {
			Name     = "ArchBanner",
			Size     = Vector3.new(8, 4, 0.4),
			Position = Vector3.new(bx, 15, -599),
			Color    = math.abs(bx) % 16 == 0
				and Color3.new(1,1,1) or Color3.new(0,0,0),
			Material = MAT.METAL,
			CanCollide = false,
		})
	end
end

-- ─── Drift corner zones ───────────────────────────────────────────────────────
-- 4 trigger volumes at S-curve apexes. Tagged "DriftCorner" so RacingManager fires
-- DriftCharge to the player when their vehicle passes through.
-- Amber neon strips on the track surface visually mark each zone.

local function _buildDriftCorners(root)
	local corners = {
		{ NODES[2][1], NODES[2][2] },   -- Z= 45,  X=-22 (first left apex)
		{ NODES[4][1], NODES[4][2] },   -- Z=-185, X=+20 (right apex)
		{ NODES[6][1], NODES[6][2] },   -- Z=-415, X=-18 (second left apex)
		-- midpoint of node 7→8: extra charge zone on final run-in
		{
			math.floor((NODES[7][1] + NODES[8][1]) / 2),
			math.floor((NODES[7][2] + NODES[8][2]) / 2),
		},
	}
	for i, c in ipairs(corners) do
		local cx, cz = c[1], c[2]
		-- Amber neon strip (visual)
		_part(root, {
			Name         = "DriftStrip_" .. i,
			Size         = Vector3.new(TRACK_W - 2, 0.2, 38),
			Position     = Vector3.new(cx, 1.12, cz),
			Color        = Color3.fromRGB(255, 165, 20),
			Material     = Enum.Material.Neon,
			CanCollide   = false,
			CastShadow   = false,
			Transparency = 0.55,
		})
		-- Invisible trigger (tagged)
		local trigger = _part(root, {
			Name         = "DriftCorner_" .. i,
			Size         = Vector3.new(TRACK_W, 5, 40),
			Position     = Vector3.new(cx, 3.5, cz),
			CanCollide   = false,
			Transparency = 1,
		})
		_tag(trigger, "DriftCorner")
	end
end

-- ─── Start grid ───────────────────────────────────────────────────────────────

local function _buildStartGrid(root)
	local cols = { -14, -7, 0, 7, 14 }  -- match CraftingManager spawn grid x=(col-3)*7
	local rows = { 195, 203 }           -- match BiomeConfig raceStartZ=195, row2 offset +8
	for ri, z in ipairs(rows) do
		for ci, x in ipairs(cols) do
			local idx = (ri - 1) * 5 + ci
			_part(root, {
				Name     = "StartBox_" .. idx,
				Size     = Vector3.new(7, 0.2, 7),
				Position = Vector3.new(x, 1.05, z),  -- sit on track surface (track top = 1.0)
				Color    = Color3.fromRGB(60, 120, 255),
				Material = MAT.NEON,
				CanCollide = false,
			})
		end
	end
end

-- ─── Main build ───────────────────────────────────────────────────────────────

local function buildForest()
	local root = _getOrCreateMap()

	-- Sub-models so MapManager can toggle farm vs track visibility per phase
	local farmSub  = Instance.new("Model"); farmSub.Name  = "FarmArea";  farmSub.Parent  = root
	local trackSub = Instance.new("Model"); trackSub.Name = "RaceTrack"; trackSub.Parent = root

	_buildGround(root)           -- shared ground plane
	_buildTrees(root)            -- shared decoration
	_buildFarmArea(farmSub)
	_buildTrack(trackSub)
	_buildRiverBridge(trackSub)
	_buildMudZones(trackSub)
	_buildRockPiles(trackSub)
	_buildJumpRamps(trackSub)
	_buildBoostPads(trackSub)
	_buildBarriers(trackSub)
	_buildDriftCorners(trackSub)
	_buildFinishLine(trackSub)
	_buildStartGrid(trackSub)

	CollectionService:AddTag(root, "BiomeMap")
	root:SetAttribute("Biome", "FOREST")

	print("[ForestMapBuilder] Built FOREST map (" .. #root:GetChildren() .. " objects)")
	return root
end

local ok, err = pcall(buildForest)
if not ok then warn("[ForestMapBuilder] Build failed: " .. tostring(err)) end
