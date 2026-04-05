-- SkyMapBuilder.server.lua
-- Procedurally builds the SKY biome map:
--   - Floating platform farm area with crystal pillar supports
--   - Sky race track: stepping-stone platforms with dramatic height variance (±25 studs)
--   - Crystal cluster formations between platforms
--   - Updraft zones, ring arch obstacles, boost pads
--   - Multi-layer clouds (large flat slabs + small puff balls)
-- Resolves: Issue #10, #97

local CollectionService = game:GetService("CollectionService")

local C = {
	CLOUD_FLAT   = Color3.fromRGB(240, 245, 255),
	CLOUD_PUFF   = Color3.fromRGB(255, 255, 255),
	CLOUD_SHADOW = Color3.fromRGB(210, 215, 235),
	PLATFORM     = Color3.fromRGB(175, 155, 218),
	PLATFORM2    = Color3.fromRGB(135, 115, 188),
	PLATFORM3    = Color3.fromRGB(200, 180, 240),
	CRYSTAL      = Color3.fromRGB(155, 110, 255),
	CRYSTAL2     = Color3.fromRGB(100, 180, 255),
	CRYSTAL3     = Color3.fromRGB(255, 130, 220),
	BOOST        = Color3.fromRGB(195, 150, 255),
	STAR         = Color3.fromRGB(255, 240, 100),
	ARCH         = Color3.fromRGB(175, 95, 255),
	ARCH_RING    = Color3.fromRGB(255, 200, 80),
	UPDRAFT      = Color3.fromRGB(115, 200, 255),
}

local MAT = {
	CLOUD   = Enum.Material.SmoothPlastic,
	ROCK    = Enum.Material.Rock,
	CRYSTAL = Enum.Material.Neon,
	NEON    = Enum.Material.Neon,
	METAL   = Enum.Material.Metal,
	ICE     = Enum.Material.Ice,
}

local SKY_BASE_Y = 80

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
	local existing = maps:FindFirstChild("SkyMap")
	if existing then existing:Destroy() end
	local model = Instance.new("Model")
	model.Name   = "SkyMap"
	model.Parent = maps
	return model
end

-- ─── Multi-layer clouds ────────────────────────────────────────────────────────
-- Two layers: large flat slabs below the track, small puff balls at/above track level.

local function _buildClouds(root)
	local rng = Random.new(77)

	-- Large flat slab clouds (background layer, well below track)
	for _ = 1, 20 do
		local cx  = rng:NextNumber(-250, 250)
		local cy  = SKY_BASE_Y + rng:NextNumber(-45, -20)
		local cz  = rng:NextNumber(-650, 650)
		local cw  = rng:NextNumber(50, 140)
		local cd  = rng:NextNumber(25, 70)
		_part(root, {
			Name         = "CloudSlab",
			Size         = Vector3.new(cw, rng:NextNumber(4, 8), cd),
			Position     = Vector3.new(cx, cy, cz),
			Color        = C.CLOUD_SHADOW,
			Material     = MAT.CLOUD,
			CanCollide   = false,
			CastShadow   = false,
			Transparency = 0.55,
		})
		-- Top highlight
		_part(root, {
			Name         = "CloudSlabTop",
			Size         = Vector3.new(cw * 0.85, 3, cd * 0.85),
			Position     = Vector3.new(cx, cy + 4, cz),
			Color        = C.CLOUD_FLAT,
			Material     = MAT.CLOUD,
			CanCollide   = false,
			CastShadow   = false,
			Transparency = 0.45,
		})
	end

	-- Small puff balls around platform level
	for _ = 1, 25 do
		local px  = rng:NextNumber(-200, 200)
		local py  = SKY_BASE_Y + rng:NextNumber(-12, 25)
		local pz  = rng:NextNumber(-650, 650)
		local pr  = rng:NextNumber(10, 28)
		-- Core puff
		_part(root, {
			Name         = "CloudPuff",
			Size         = Vector3.new(pr * 2, pr, pr * 1.3),
			Position     = Vector3.new(px, py, pz),
			Color        = C.CLOUD_PUFF,
			Material     = MAT.CLOUD,
			CanCollide   = false,
			CastShadow   = false,
			Transparency = 0.4,
		})
		-- Side blob
		_part(root, {
			Name         = "CloudPuffBlob",
			Size         = Vector3.new(pr * 1.3, pr * 0.8, pr * 0.9),
			Position     = Vector3.new(px + rng:NextNumber(-pr, pr) * 0.6, py + 2, pz + rng:NextNumber(-pr, pr) * 0.4),
			Color        = C.CLOUD_FLAT,
			Material     = MAT.CLOUD,
			CanCollide   = false,
			CastShadow   = false,
			Transparency = 0.5,
		})
	end
end

-- ─── Farm platform (Z = 300 to 510) ───────────────────────────────────────────

local function _buildFarmPlatform(root)
	_part(root, {
		Name     = "FarmPlatform",
		Size     = Vector3.new(185, 9, 225),
		Position = Vector3.new(0, SKY_BASE_Y - 4.5, 395),
		Color    = C.PLATFORM3,
		Material = MAT.ROCK,
	})
	-- Bevelled lower edge decoration
	for _, side in ipairs({ -1, 1 }) do
		local bev = _wedge(root, {
			Name     = "FarmBevel",
			Size     = Vector3.new(185, 5, 6),
			Color    = C.PLATFORM2,
			Material = MAT.ROCK,
			CanCollide = false,
		})
		bev.CFrame = CFrame.new(0, SKY_BASE_Y - 7.5, 395 + side * 117)
			* CFrame.Angles(0, side > 0 and 0 or math.pi, 0)
	end

	-- Crystal pillar supports (6 pillars in a ring)
	local pillarPositions = {
		{ -75, 395 }, {  75, 395 },
		{ -75, 300 }, {  75, 300 },
		{ -75, 490 }, {  75, 490 },
	}
	for _, pp in ipairs(pillarPositions) do
		-- Tall main pillar
		_part(root, {
			Name         = "CrystalPillar",
			Size         = Vector3.new(5, 50, 5),
			Position     = Vector3.new(pp[1], SKY_BASE_Y - 33, pp[2]),
			Color        = C.CRYSTAL,
			Material     = MAT.CRYSTAL,
			CanCollide   = false,
			CastShadow   = false,
		})
		-- Angled side shard
		local shard = _wedge(root, {
			Name     = "CrystalShard",
			Size     = Vector3.new(2.5, 22, 2.5),
			Color    = C.CRYSTAL2,
			Material = MAT.CRYSTAL,
			CanCollide = false,
			CastShadow = false,
		})
		shard.CFrame = CFrame.new(pp[1] + 4, SKY_BASE_Y - 22, pp[2])
			* CFrame.Angles(0, 0, math.rad(20))
	end

	-- Spawn points
	local cols = { -65, -32, 0, 32, 65 }
	local rows = { 345, 385 }
	for _, row in ipairs(rows) do
		for _, col in ipairs(cols) do
			local sp = _part(root, {
				Name         = "FarmSpawnPoint",
				Size         = Vector3.new(4, 0.5, 4),
				Position     = Vector3.new(col, SKY_BASE_Y + 4.5, row),
				Color        = Color3.fromRGB(255, 220, 60),
				Material     = MAT.NEON,
				CanCollide   = false,
				Transparency = 0.5,
			})
			_tag(sp, "FarmSpawn")
		end
	end
end

-- ─── Sky race track (stepping-stone platforms) ────────────────────────────────
-- Dramatic height variance: y offsets range from -25 to +25 studs.
-- Platforms alternate color and have edge glow strips.
-- { centerX, yOffset, centerZ, width, length }

local PLATFORM_DATA = {
	{ 0,    0,   200,  42, 85  },   -- [1] transition from farm
	{ 0,   -8,   105,  36, 65  },   -- [2] slight drop
	{-18,  -18,   15,  36, 65  },   -- [3] drop + shift left (large gap)
	{ 14,   5,  -90,   36, 65  },   -- [4] rise + shift right
	{ 0,  -15, -195,  42, 85  },   -- [5] drop, wide section
	{ 18,   8,  -310,  32, 60  },   -- [6] rise + shift right
	{-14, -22, -415,  32, 60  },   -- [7] big drop + shift left
	{  4,   0,  -505,  36, 80  },   -- [8] level out
	{  0,   5,  -575,  42, 75  },   -- [9] slight rise, near finish
}

local function _buildTrackPlatforms(root)
	local colors = { C.PLATFORM, C.PLATFORM2, C.PLATFORM3 }

	for i, pd in ipairs(PLATFORM_DATA) do
		local y = SKY_BASE_Y + pd[2]
		local color = colors[((i - 1) % 3) + 1]

		-- Main platform slab
		_part(root, {
			Name     = "TrackPlatform_" .. i,
			Size     = Vector3.new(pd[4], 6, pd[5]),
			Position = Vector3.new(pd[1], y - 3, pd[3]),
			Color    = color,
			Material = MAT.ROCK,
		})

		-- Underside bevel on long edges
		for _, side in ipairs({ -1, 1 }) do
			local bev = _wedge(root, {
				Name     = "PlatformBevel_" .. i,
				Size     = Vector3.new(pd[4], 3, 4),
				Color    = C.PLATFORM2,
				Material = MAT.ROCK,
				CanCollide = false,
			})
			bev.CFrame = CFrame.new(pd[1], y - 5.5, pd[3] + side * (pd[5] / 2))
				* CFrame.Angles(0, side > 0 and 0 or math.pi, 0)
		end

		-- Edge glow strips (left/right sides)
		for _, side in ipairs({ -1, 1 }) do
			_part(root, {
				Name     = "TrackGlow_" .. i,
				Size     = Vector3.new(1.2, 0.6, pd[5]),
				Position = Vector3.new(pd[1] + side * (pd[4] / 2 - 0.8), y + 0.4, pd[3]),
				Color    = i % 2 == 0 and C.CRYSTAL or C.CRYSTAL2,
				Material = MAT.NEON,
				CanCollide = false,
				CastShadow = false,
			})
		end

		-- Star markers on platform surface
		if i % 3 == 0 then
			_part(root, {
				Name     = "StarDecal_" .. i,
				Size     = Vector3.new(5, 0.3, 5),
				Position = Vector3.new(pd[1], y + 0.3, pd[3]),
				Color    = C.STAR,
				Material = MAT.NEON,
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
end

-- ─── Crystal cluster formations ───────────────────────────────────────────────
-- Groups of 3–5 spires between platforms; purely decorative.

local function _buildCrystalClusters(root)
	local clusterSeeds = {
		{  30, -15,  60  },   -- between platforms 1-2
		{ -30,  -8, -40  },   -- between 3-4
		{  25, -20, -145 },   -- near platform 5
		{ -28,  -5, -260 },   -- between 5-6
		{  22, -15, -365 },   -- near 7
		{ -20, -10, -460 },   -- between 7-8
	}
	local crystalColors = { C.CRYSTAL, C.CRYSTAL2, C.CRYSTAL3 }
	local rng = Random.new(33)

	for ci, cs in ipairs(clusterSeeds) do
		local baseY = SKY_BASE_Y + cs[2]
		for s = 1, rng:NextInteger(3, 5) do
			local ox = cs[1] + rng:NextNumber(-12, 12)
			local oz = cs[3] + rng:NextNumber(-10, 10)
			local sh = rng:NextNumber(15, 45)
			local sw = rng:NextNumber(1.5, 4)
			local color = crystalColors[rng:NextInteger(1, 3)]

			-- Main spire (slim wedge/part stack)
			_part(root, {
				Name     = "CrystalSpire_" .. ci .. "_" .. s,
				Size     = Vector3.new(sw, sh, sw),
				Position = Vector3.new(ox, baseY - sh / 2 + 5, oz),
				Color    = color,
				Material = MAT.CRYSTAL,
				CanCollide = false,
				CastShadow = false,
			})
			-- Tapered tip
			local tip = _wedge(root, {
				Name     = "CrystalTip_" .. ci .. "_" .. s,
				Size     = Vector3.new(sw, sh * 0.35, sw),
				Color    = color,
				Material = MAT.CRYSTAL,
				CanCollide = false,
				CastShadow = false,
			})
			tip.CFrame = CFrame.new(ox, baseY - sh * 0.12 + 5, oz)
				* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		end
	end
end

-- ─── Ring arch obstacles ──────────────────────────────────────────────────────
-- Players must fly/drive through the ring or take a damage/slowdown penalty.

local function _buildRingObstacles(root)
	local rings = {
		{ PLATFORM_DATA[3][1], SKY_BASE_Y + PLATFORM_DATA[3][2] + 4, PLATFORM_DATA[3][3] + 15 },
		{ PLATFORM_DATA[5][1], SKY_BASE_Y + PLATFORM_DATA[5][2] + 4, PLATFORM_DATA[5][3] + 15 },
		{ PLATFORM_DATA[7][1], SKY_BASE_Y + PLATFORM_DATA[7][2] + 4, PLATFORM_DATA[7][3] + 15 },
	}
	for i, rg in ipairs(rings) do
		local rx, ry, rz = rg[1], rg[2], rg[3]
		local ringR = 10  -- outer radius

		-- 8-segment ring (using short parts arranged in a circle)
		for seg = 0, 7 do
			local angle = (seg / 8) * math.pi * 2
			local sx = math.cos(angle) * ringR
			local sy = math.sin(angle) * ringR
			local arcPart = _part(root, {
				Name     = "RingArc_" .. i .. "_" .. seg,
				Size     = Vector3.new(2.5, 2.5, 9),
				Color    = C.ARCH_RING,
				Material = MAT.NEON,
				CanCollide = false,
				CastShadow = false,
			})
			arcPart.CFrame = CFrame.new(rx + sx, ry + sy, rz)
				* CFrame.Angles(0, 0, angle)
		end

		-- Ring trigger (invisible, detects pass-through)
		local trigger = _part(root, {
			Name         = "RingTrigger_" .. i,
			Size         = Vector3.new(ringR * 2 - 4, ringR * 2 - 4, 4),
			Position     = Vector3.new(rx, ry, rz),
			CanCollide   = false,
			Transparency = 1,
		})
		_tag(trigger, "Obstacle")

		-- Spin decoration (small star in ring center)
		_part(root, {
			Name     = "RingStar_" .. i,
			Size     = Vector3.new(3, 3, 0.5),
			Position = Vector3.new(rx, ry, rz),
			Color    = C.STAR,
			Material = MAT.NEON,
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- ─── Updraft zones ─────────────────────────────────────────────────────────────

local function _buildUpdraftZones(root)
	-- Placed in the gaps between platforms (where height drops)
	local zones = {
		{ PLATFORM_DATA[3][1], PLATFORM_DATA[3][3] + 45 },  -- near the big drop at platform 3
		{ PLATFORM_DATA[7][1], PLATFORM_DATA[7][3] + 45 },  -- near the big drop at platform 7
		{ 0, -250 },                                         -- mid-track recovery zone
	}
	for i, uz in ipairs(zones) do
		local ux, uz2 = uz[1], uz[2]
		local baseY = SKY_BASE_Y - 20

		-- Visual column
		_part(root, {
			Name         = "UpdraftVisual_" .. i,
			Size         = Vector3.new(14, 55, 14),
			Position     = Vector3.new(ux, baseY, uz2),
			Color        = C.UPDRAFT,
			Material     = MAT.NEON,
			CanCollide   = false,
			Transparency = 0.72,
			CastShadow   = false,
		})
		-- Trigger zone (larger)
		local trigger = _part(root, {
			Name         = "UpdraftZone_" .. i,
			Size         = Vector3.new(18, 70, 18),
			Position     = Vector3.new(ux, baseY, uz2),
			CanCollide   = false,
			Transparency = 1,
		})
		_tag(trigger, "UpdraftZone")

		-- Swirl ring at base
		_part(root, {
			Name     = "UpdraftRing_" .. i,
			Size     = Vector3.new(16, 1, 16),
			Position = Vector3.new(ux, SKY_BASE_Y - 30, uz2),
			Color    = C.UPDRAFT,
			Material = MAT.NEON,
			CanCollide = false,
			CastShadow = false,
			Transparency = 0.4,
		})
	end
end

-- ─── Boost pads ───────────────────────────────────────────────────────────────

local function _buildBoostPads(root)
	local pads = {
		{ PLATFORM_DATA[1][1], SKY_BASE_Y + PLATFORM_DATA[1][2] + 0.8, PLATFORM_DATA[1][3] - 25 },
		{ PLATFORM_DATA[4][1], SKY_BASE_Y + PLATFORM_DATA[4][2] + 0.8, PLATFORM_DATA[4][3] - 15 },
		{ PLATFORM_DATA[6][1], SKY_BASE_Y + PLATFORM_DATA[6][2] + 0.8, PLATFORM_DATA[6][3] - 15 },
		{ PLATFORM_DATA[8][1], SKY_BASE_Y + PLATFORM_DATA[8][2] + 0.8, PLATFORM_DATA[8][3] - 20 },
		{ PLATFORM_DATA[9][1], SKY_BASE_Y + PLATFORM_DATA[9][2] + 0.8, PLATFORM_DATA[9][3] + 20 },
	}
	for i, pd in ipairs(pads) do
		local pad = _part(root, {
			Name     = "BoostPad_" .. i,
			Size     = Vector3.new(10, 0.3, 6),
			Position = Vector3.new(pd[1], pd[2], pd[3]),
			Color    = C.BOOST,
			Material = MAT.NEON,
			CanCollide = false,
			CastShadow = false,
		})
		_tag(pad, "BoostPad")
	end
end

-- ─── Kill plane ────────────────────────────────────────────────────────────────

local function _buildKillPlane(root)
	local kill = _part(root, {
		Name         = "KillPlane",
		Size         = Vector3.new(2000, 4, 2000),
		Position     = Vector3.new(0, SKY_BASE_Y - 80, 0),
		CanCollide   = false,
		Transparency = 1,
	})
	_tag(kill, "KillPlane")
end

-- ─── Finish line ──────────────────────────────────────────────────────────────

local function _buildFinishLine(root)
	local lastPD = PLATFORM_DATA[#PLATFORM_DATA]
	local finY   = SKY_BASE_Y + lastPD[2]
	local finZ   = -599

	for col = -12, 12, 4 do
		for row = 0, 1 do
			_part(root, {
				Name     = "FinishTile",
				Size     = Vector3.new(4, 0.3, 4),
				Position = Vector3.new(col, finY + 0.9, finZ + row * 4),
				Color    = (math.floor(col / 4) + row) % 2 == 0
					and Color3.new(1,1,1) or Color3.new(0,0,0),
				Material = MAT.METAL,
				CanCollide = false,
			})
		end
	end

	local finish = _part(root, {
		Name         = "FinishLine",
		Size         = Vector3.new(44, 12, 2),
		Position     = Vector3.new(0, finY + 6, finZ),
		CanCollide   = false,
		Transparency = 1,
	})
	_tag(finish, "FinishLine")

	-- Arch poles with crystal material
	for side = -1, 1, 2 do
		_part(root, {
			Name     = "FinishPole",
			Size     = Vector3.new(1.8, 22, 1.8),
			Position = Vector3.new(side * 22, finY + 11, finZ),
			Color    = C.ARCH,
			Material = MAT.CRYSTAL,
		})
	end
	_part(root, {
		Name     = "FinishArch",
		Size     = Vector3.new(46, 3, 1.8),
		Position = Vector3.new(0, finY + 22.5, finZ),
		Color    = C.ARCH,
		Material = MAT.NEON,
		CanCollide = false,
	})

	-- Star burst decoration on arch
	for sx = -20, 20, 5 do
		local phase = sx * 0.6
		_part(root, {
			Name     = "ArchStar",
			Size     = Vector3.new(2.5, 2.5, 0.6),
			Position = Vector3.new(sx, finY + 23 + math.sin(phase) * 1.5, finZ - 0.5),
			Color    = C.STAR,
			Material = MAT.NEON,
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- ─── Main build ───────────────────────────────────────────────────────────────

local function buildSky()
	local root = _getOrCreateMap()

	local farmSub  = Instance.new("Model"); farmSub.Name  = "FarmArea";  farmSub.Parent  = root
	local trackSub = Instance.new("Model"); trackSub.Name = "RaceTrack"; trackSub.Parent = root

	_buildClouds(root)             -- shared decoration
	_buildUpdraftZones(root)       -- shared (physics zones needed in both phases)
	_buildFarmPlatform(farmSub)
	_buildTrackPlatforms(trackSub)
	_buildCrystalClusters(trackSub)
	_buildRingObstacles(trackSub)
	_buildBoostPads(trackSub)
	_buildKillPlane(trackSub)
	_buildFinishLine(trackSub)

	CollectionService:AddTag(root, "BiomeMap")
	root:SetAttribute("Biome", "SKY")

	print("[SkyMapBuilder] Built SKY map (" .. #root:GetChildren() .. " objects)")
	return root
end

local ok, err = pcall(buildSky)
if not ok then warn("[SkyMapBuilder] Build failed: " .. tostring(err)) end
