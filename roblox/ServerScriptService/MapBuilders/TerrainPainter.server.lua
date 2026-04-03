-- TerrainPainter.server.lua
-- Uses workspace.Terrain API to paint biome-specific terrain
-- underneath the procedural map parts.
-- Runs once at server start, before MapBuilders execute.
-- Resolves: Issue #8 #9 #10 (terrain layer)

local Terrain = workspace.Terrain

-- ─── Terrain material enums ───────────────────────────────────────────────────

local TM = Enum.Material

-- ─── Helper: fill a box region with terrain material ─────────────────────────

local function _fillBox(x, y, z, sizeX, sizeY, sizeZ, material)
	local region = Region3.new(
		Vector3.new(x - sizeX / 2, y - sizeY / 2, z - sizeZ / 2),
		Vector3.new(x + sizeX / 2, y + sizeY / 2, z + sizeZ / 2)
	)
	Terrain:FillBlock(region.CFrame, region.Size, material)
end

-- ─── Helper: fill a cylinder ──────────────────────────────────────────────────

local function _fillCylinder(x, y, z, height, radius, material)
	local cf     = CFrame.new(x, y, z)
	Terrain:FillCylinder(cf, height, radius, material)
end

-- ─── Helper: fill a sphere ────────────────────────────────────────────────────

local function _fillSphere(x, y, z, radius, material)
	Terrain:FillBall(Vector3.new(x, y, z), radius, material)
end

-- ─── Clear all terrain first ─────────────────────────────────────────────────

local function _clearTerrain()
	Terrain:Clear()
end

-- ─── FOREST terrain ──────────────────────────────────────────────────────────

local function _paintForest()
	-- Ground layer (grass over dirt)
	_fillBox(0, -6, 0, 400, 8, 1400, TM.Grass)
	_fillBox(0, -14, 0, 400, 8, 1400, TM.Ground)
	_fillBox(0, -22, 0, 400, 8, 1400, TM.Rock)

	-- Farm area: dirt patch
	_fillBox(0, -2, 350, 220, 3, 310, TM.Ground)
	_fillBox(0, -0.5, 350, 200, 1, 290, TM.Mud)

	-- Mud zones (slightly depressed)
	local mudAreas = {
		{ 0, -1, -50,  35, 1.5, 35 },
		{ 8, -1, -200, 25, 1.5, 25 },
		{ -5,-1, -380, 30, 1.5, 30 },
		{ 3, -1, -480, 40, 1.5, 40 },
	}
	for _, m in ipairs(mudAreas) do
		_fillBox(m[1], m[2], m[3], m[4], m[5], m[6], TM.Mud)
	end

	-- Hills on sides (decorative)
	local rng = Random.new(12)
	for _ = 1, 20 do
		local hx = rng:NextNumber(-150, -40) * (rng:NextNumber() > 0.5 and 1 or -1)
		local hz = rng:NextNumber(-580, 580)
		local hr = rng:NextNumber(10, 25)
		_fillSphere(hx, -hr * 0.5, hz, hr, TM.Grass)
	end

	-- River / stream crossing track at Z=-120 (water hazard visual)
	_fillBox(0, -2, -120, 30, 2, 20, TM.Water)

	print("[TerrainPainter] FOREST terrain painted")
end

-- ─── OCEAN terrain ───────────────────────────────────────────────────────────

local function _paintOcean()
	-- Seabed
	_fillBox(0, -30, 0, 600, 20, 1600, TM.Sand)
	_fillBox(0, -50, 0, 600, 20, 1600, TM.Rock)

	-- Water volume
	_fillBox(0, -8, 0, 600, 16, 1600, TM.Water)

	-- Farm island sand base
	_fillBox(0, -4, 375, 170, 8, 270, TM.Sand)
	_fillBox(0, 2, 375, 140, 2, 230, TM.Grass)

	-- Coral reef decorations (shallow rocks near track)
	local rng = Random.new(55)
	for _ = 1, 30 do
		local rx = rng:NextNumber(-100, 100)
		local rz = rng:NextNumber(-580, 180)
		local rr = rng:NextNumber(2, 8)
		_fillSphere(rx, -12, rz, rr, TM.Rock)
	end

	-- Sandy shallows near island
	for _ = 1, 15 do
		local sx = rng:NextNumber(-120, 120)
		local sz = rng:NextNumber(200, 550)
		_fillSphere(sx, -5, sz, rng:NextNumber(5, 12), TM.Sand)
	end

	print("[TerrainPainter] OCEAN terrain painted")
end

-- ─── SKY terrain ─────────────────────────────────────────────────────────────

local function _paintSky()
	-- Small floating rock islands beneath platforms for visual depth
	local rng = Random.new(33)

	for _ = 1, 12 do
		local rx = rng:NextNumber(-100, 100)
		local ry = rng:NextNumber(20, 60)
		local rz = rng:NextNumber(-580, 580)
		local rr = rng:NextNumber(8, 20)
		_fillSphere(rx, ry, rz, rr, TM.Rock)
		-- Grass cap
		_fillSphere(rx, ry + rr * 0.6, rz, rr * 0.5, TM.Grass)
	end

	-- Main farm platform base (rocky underside)
	_fillBox(0, 65, 390, 180, 20, 220, TM.Rock)
	_fillBox(0, 79, 390, 175, 3, 215, TM.Grass)

	-- Track platform bases
	local platZ = { 200, 110, 30, -60, -160, -270, -370, -460, -560 }
	for _, z in ipairs(platZ) do
		_fillBox(0, 72, z, 40, 10, 70, TM.Rock)
	end

	print("[TerrainPainter] SKY terrain painted")
end

-- ─── Dispatch ────────────────────────────────────────────────────────────────
-- Wait for MapManager / BiomeSelected to know which biome to paint.
-- Listen to the map model attribute set by MapBuilders.

local function _detectAndPaint()
	-- Watch for map models being created
	workspace:DescendantAdded:Connect(function(desc)
		if desc:IsA("Model") and desc:GetAttribute("Biome") then
			local biome = desc:GetAttribute("Biome")
			_clearTerrain()
			if biome == "FOREST" then
				_paintForest()
			elseif biome == "OCEAN" then
				_paintOcean()
			elseif biome == "SKY" then
				_paintSky()
			end
		end
	end)

	-- Also check existing maps (in case MapBuilders ran first)
	local maps = workspace:FindFirstChild("Maps")
	if maps then
		for _, model in ipairs(maps:GetChildren()) do
			local biome = model:GetAttribute("Biome")
			if biome then
				_clearTerrain()
				if biome == "FOREST" then _paintForest()
				elseif biome == "OCEAN" then _paintOcean()
				elseif biome == "SKY" then _paintSky()
				end
				break
			end
		end
	end
end

task.defer(_detectAndPaint)
