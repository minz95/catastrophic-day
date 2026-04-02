-- BiomeConfig.lua
-- Per-biome map settings, physics overrides, and track metadata.
-- Resolves: Issue #11

local Constants = require(game.ReplicatedStorage.Shared.Constants)

local BiomeConfig = {}

BiomeConfig["FOREST"] = {
	mapPath        = "Workspace.Maps.ForestMap",
	vehicleType    = "Car",
	mobilitySlot   = "WHEELS",
	skyboxId       = "rbxassetid://0",          -- TODO: replace with asset IDs
	ambientSoundId = "rbxassetid://0",          -- TODO

	-- Track hazards
	hazards = {
		{
			tag      = "MudZone",
			type     = "mud",
			speedMult = Constants.MUD_SPEED_MULT,
		},
		{
			type       = "fallingLog",           -- periodic obstacle (Issue #66)
			interval   = 8,                      -- seconds between spawns
			count      = 3,
		},
	},

	-- Drift corner parameters (Issue #66)
	driftCorners = 4,
	jumpRamps    = 2,
	boostPads    = 4,
}

BiomeConfig["OCEAN"] = {
	mapPath        = "Workspace.Maps.OceanMap",
	vehicleType    = "Boat",
	mobilitySlot   = "SAIL",
	skyboxId       = "rbxassetid://0",
	ambientSoundId = "rbxassetid://0",

	waterPlaneY    = 0,                         -- Y coordinate of water surface

	hazards = {
		{
			tag      = "BuoyancyZone",
			type     = "buoyancy",
			-- physics applied per-frame in RacingManager
		},
		{
			type       = "waveFlood",            -- periodic water level surge (Issue #66)
			interval   = 12,
			riseHeight = 3,
			duration   = 4,
		},
	},

	driftCorners = 3,
	jumpRamps    = 2,
	boostPads    = 4,
}

BiomeConfig["SKY"] = {
	mapPath        = "Workspace.Maps.SkyMap",
	vehicleType    = "FlyingVehicle",
	mobilitySlot   = "WINGS",
	skyboxId       = "rbxassetid://0",
	ambientSoundId = "rbxassetid://0",

	killPlaneY     = -200,                      -- Y below which players respawn

	hazards = {
		{
			tag  = "UpdraftZone",
			type = "updraft",
			baseForce = Constants.UPDRAFT_BASE_FORCE,
		},
		{
			type     = "gustZone",               -- random directional wind (Issue #66)
			interval = 10,
			force    = 150,
		},
	},

	driftCorners = 3,
	jumpRamps    = 3,
	boostPads    = 5,
}

-- ─── Helper ───────────────────────────────────────────────────────────────────

function BiomeConfig.random()
	local biomes = Constants.BIOMES
	return biomes[math.random(#biomes)]
end

function BiomeConfig.get(biome)
	assert(BiomeConfig[biome], "Unknown biome: " .. tostring(biome))
	return BiomeConfig[biome]
end

return BiomeConfig
