-- SkyMapBuilder.server.lua
-- Procedurally builds the SKY biome map:
--   - Floating platform farm area
--   - Sky race track with platforms and gaps
--   - Updraft zones, kill plane, boost pads, obstacles
-- Resolves: Issue #10

local CollectionService = game:GetService("CollectionService")

local C = {
	CLOUD      = Color3.fromRGB(235, 240, 255),
	PLATFORM   = Color3.fromRGB(180, 160, 220),
	PLATFORM2  = Color3.fromRGB(140, 120, 190),
	CRYSTAL    = Color3.fromRGB(160, 120, 255),
	BOOST      = Color3.fromRGB(200, 160, 255),
	BARRIER    = Color3.fromRGB(255, 100, 80),
	UPDRAFT    = Color3.fromRGB(120, 200, 255),
	STAR       = Color3.fromRGB(255, 240, 100),
	ARCH       = Color3.fromRGB(180, 100, 255),
}

local MAT = {
	CLOUD   = Enum.Material.SmoothPlastic,
	ROCK    = Enum.Material.Rock,
	CRYSTAL = Enum.Material.Neon,
	NEON    = Enum.Material.Neon,
	METAL   = Enum.Material.Metal,
	ICE     = Enum.Material.Ice,
}

local SKY_BASE_Y = 80   -- everything lives up here

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
	local existing = maps:FindFirstChild("SkyMap")
	if existing then existing:Destroy() end
	local model = Instance.new("Model")
	model.Name   = "SkyMap"
	model.Parent = maps
	return model
end

-- ─── Cloud decoration layer ──────────────────────────────────────────────────

local function _buildClouds(root)
	local rng = Random.new(77)
	for _ = 1, 30 do
		local cx = rng:NextNumber(-200, 200)
		local cy = SKY_BASE_Y + rng:NextNumber(-20, 30)
		local cz = rng:NextNumber(-650, 650)
		local cw = rng:NextNumber(30, 80)
		local cd = rng:NextNumber(15, 40)

		_part(root, {
			Name         = "Cloud",
			Size         = Vector3.new(cw, 8, cd),
			Position     = Vector3.new(cx, cy, cz),
			Color        = C.CLOUD,
			Material     = MAT.CLOUD,
			CanCollide   = false,
			CastShadow   = false,
			Transparency = 0.5,
		})
		-- second blob
		_part(root, {
			Name         = "CloudBlob",
			Size         = Vector3.new(cw * 0.7, 10, cd * 0.7),
			Position     = Vector3.new(cx + rng:NextNumber(-10, 10), cy + 5, cz + rng:NextNumber(-8, 8)),
			Color        = C.CLOUD,
			Material     = MAT.CLOUD,
			CanCollide   = false,
			CastShadow   = false,
			Transparency = 0.45,
		})
	end
end

-- ─── Farm platform (Z = 300 to 500) ─────────────────────────────────────────

local function _buildFarmPlatform(root)
	-- Large floating platform for farming
	_part(root, {
		Name     = "FarmPlatform",
		Size     = Vector3.new(180, 8, 220),
		Position = Vector3.new(0, SKY_BASE_Y - 4, 390),
		Color    = C.PLATFORM,
		Material = MAT.ROCK,
	})
	-- Crystal pillars underneath for visual
	for _, pos in ipairs({ {-70, 390}, {70, 390}, {0, 310}, {0, 470} }) do
		_part(root, {
			Name         = "CrystalPillar",
			Size         = Vector3.new(5, 40, 5),
			Position     = Vector3.new(pos[1], SKY_BASE_Y - 28, pos[2]),
			Color        = C.CRYSTAL,
			Material     = MAT.CRYSTAL,
			CanCollide   = false,
			CastShadow   = false,
		})
	end

	-- Spawn points on platform
	local cols = { -60, -30, 0, 30, 60 }
	local rows = { 340, 380 }
	for _, row in ipairs(rows) do
		for _, col in ipairs(cols) do
			local sp = _part(root, {
				Name      = "FarmSpawnPoint",
				Size      = Vector3.new(4, 0.5, 4),
				Position  = Vector3.new(col, SKY_BASE_Y + 4.5, row),
				Color     = Color3.fromRGB(255, 220, 60),
				Material  = MAT.NEON,
				CanCollide = false,
				Transparency = 0.5,
			})
			_tag(sp, "FarmSpawn")
		end
	end
end

-- ─── Sky race track (stepping stone platforms) ───────────────────────────────

local PLATFORM_DATA = {
	-- { centerX, centerY_offset, centerZ, width, length }
	{ 0,    0,    200,  40, 80  },   -- transition from farm
	{ 0,    0,    110,  35, 60  },
	{ -15, -5,   30,   35, 60  },   -- slight drop + offset
	{ 10,   3,  -60,   35, 60  },   -- rise
	{ 0,   -8,  -160,  40, 80  },   -- wide section
	{ 15,   0,  -270,  30, 60  },
	{ -10, -5,  -370,  30, 60  },
	{ 0,    5,  -460,  35, 80  },
	{ 0,    0,  -560,  40, 80  },   -- near finish
}

local function _buildTrackPlatforms(root)
	for i, pd in ipairs(PLATFORM_DATA) do
		local y = SKY_BASE_Y + pd[2]
		_part(root, {
			Name     = "TrackPlatform_" .. i,
			Size     = Vector3.new(pd[4], 5, pd[5]),
			Position = Vector3.new(pd[1], y - 2.5, pd[3]),
			Color    = i % 2 == 0 and C.PLATFORM or C.PLATFORM2,
			Material = MAT.ROCK,
		})

		-- Edge glow strips
		for side = -1, 1, 2 do
			_part(root, {
				Name     = "TrackGlow_" .. i,
				Size     = Vector3.new(1, 0.5, pd[5]),
				Position = Vector3.new(pd[1] + side * (pd[4] / 2 - 0.5), y + 0.3, pd[3]),
				Color    = C.CRYSTAL,
				Material = MAT.NEON,
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
end

-- ─── Updraft zones ───────────────────────────────────────────────────────────

local function _buildUpdraftZones(root)
	local zones = {
		{ 0,  SKY_BASE_Y - 10, 80   },
		{ 0,  SKY_BASE_Y - 10, -110 },
		{ 0,  SKY_BASE_Y - 10, -320 },
	}
	for i, uz in ipairs(zones) do
		-- Visual column (neon blue cylinder approximation using part)
		local visual = _part(root, {
			Name         = "UpdraftVisual_" .. i,
			Size         = Vector3.new(12, 40, 12),
			Position     = Vector3.new(uz[1], uz[2], uz[3]),
			Color        = C.UPDRAFT,
			Material     = MAT.NEON,
			CanCollide   = false,
			Transparency = 0.75,
		})

		-- Trigger zone (invisible, larger)
		local trigger = _part(root, {
			Name         = "UpdraftZone_" .. i,
			Size         = Vector3.new(16, 60, 16),
			Position     = Vector3.new(uz[1], uz[2], uz[3]),
			CanCollide   = false,
			Transparency = 1,
		})
		_tag(trigger, "UpdraftZone")
	end
end

-- ─── Obstacles (floating crystals / rocks) ───────────────────────────────────

local function _buildObstacles(root)
	local obs = {
		{ 8,   SKY_BASE_Y + 2, -30  },
		{ -8,  SKY_BASE_Y + 2, -200 },
		{ 10,  SKY_BASE_Y + 2, -310 },
		{ -10, SKY_BASE_Y + 2, -400 },
		{ 0,   SKY_BASE_Y + 3, -510 },
	}
	for i, ob in ipairs(obs) do
		local obstacle = _part(root, {
			Name     = "Obstacle_" .. i,
			Size     = Vector3.new(5, 6, 5),
			Position = Vector3.new(ob[1], ob[2], ob[3]),
			Color    = C.CRYSTAL,
			Material = MAT.CRYSTAL,
		})
		_tag(obstacle, "Obstacle")

		-- Rotating glow ring (static decoration)
		_part(root, {
			Name     = "ObstacleRing_" .. i,
			Size     = Vector3.new(8, 0.5, 8),
			Position = Vector3.new(ob[1], ob[2] - 1, ob[3]),
			Color    = C.STAR,
			Material = MAT.NEON,
			CanCollide = false,
		})
	end
end

-- ─── Boost pads ──────────────────────────────────────────────────────────────

local function _buildBoostPads(root)
	local pads = {
		{ 0, SKY_BASE_Y + 0.8, -20  },
		{ 0, SKY_BASE_Y - 4.7, -150 },  -- slightly lower platform
		{ 0, SKY_BASE_Y + 2.8, -360 },
		{ 0, SKY_BASE_Y + 0.8, -480 },
		{ 0, SKY_BASE_Y + 0.8, -545 },
	}
	for i, pd in ipairs(pads) do
		local pad = _part(root, {
			Name     = "BoostPad_" .. i,
			Size     = Vector3.new(10, 0.3, 6),
			Position = Vector3.new(pd[1], pd[2], pd[3]),
			Color    = C.BOOST,
			Material = MAT.NEON,
			CanCollide = false,
		})
		_tag(pad, "BoostPad")
	end
end

-- ─── Finish line ─────────────────────────────────────────────────────────────

local function _buildFinishLine(root)
	local finY = SKY_BASE_Y

	for col = -12, 12, 4 do
		for row = 0, 1 do
			_part(root, {
				Name     = "FinishTile",
				Size     = Vector3.new(4, 0.3, 4),
				Position = Vector3.new(col, finY + 0.9, -598 + row * 4),
				Color    = (math.floor(col / 4) + row) % 2 == 0
					and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),
				Material = MAT.METAL,
				CanCollide = false,
			})
		end
	end

	local finish = _part(root, {
		Name       = "FinishLine",
		Size       = Vector3.new(40, 10, 2),
		Position   = Vector3.new(0, finY + 5, -599),
		CanCollide = false,
		Transparency = 1,
	})
	_tag(finish, "FinishLine")

	for side = -1, 1, 2 do
		_part(root, {
			Name     = "FinishPole",
			Size     = Vector3.new(1.5, 16, 1.5),
			Position = Vector3.new(side * 20, finY + 8, -599),
			Color    = C.ARCH,
			Material = MAT.CRYSTAL,
		})
	end
	_part(root, {
		Name     = "FinishArch",
		Size     = Vector3.new(42, 2.5, 1.5),
		Position = Vector3.new(0, finY + 16, -599),
		Color    = C.ARCH,
		Material = MAT.NEON,
		CanCollide = false,
	})

	-- Star decorations on arch
	for i = -16, 16, 8 do
		_part(root, {
			Name     = "ArchStar",
			Size     = Vector3.new(2, 2, 0.5),
			Position = Vector3.new(i, finY + 16, -598),
			Color    = C.STAR,
			Material = MAT.NEON,
			CanCollide = false,
		})
	end
end

-- ─── Main build ──────────────────────────────────────────────────────────────

local function buildSky()
	local root = _getOrCreateMap()
	_buildClouds(root)
	_buildFarmPlatform(root)
	_buildTrackPlatforms(root)
	_buildUpdraftZones(root)
	_buildObstacles(root)
	_buildBoostPads(root)
	_buildFinishLine(root)

	CollectionService:AddTag(root, "BiomeMap")
	root:SetAttribute("Biome", "SKY")

	print("[SkyMapBuilder] Built SKY map (" .. #root:GetChildren() .. " objects)")
	return root
end

local ok, err = pcall(buildSky)
if not ok then warn("[SkyMapBuilder] Build failed: " .. tostring(err)) end
