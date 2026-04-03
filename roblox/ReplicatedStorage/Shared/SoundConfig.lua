-- SoundConfig.lua
-- All audio AssetIds, volumes, and categories.
-- Uses Roblox free audio library IDs.
-- Resolves: Issue #73

local SoundConfig = {}

-- ─── BGM ─────────────────────────────────────────────────────────────────────
-- Roblox free music from the audio library

SoundConfig.BGM = {
	LOBBY = {
		id     = "rbxassetid://1843326388",   -- upbeat waiting music
		volume = 0.4,
		looped = true,
	},
	FARMING = {
		FOREST = { id = "rbxassetid://1843326388", volume = 0.45, looped = true },
		OCEAN  = { id = "rbxassetid://1843326388", volume = 0.45, looped = true },
		SKY    = { id = "rbxassetid://1843326388", volume = 0.45, looped = true },
	},
	CRAFTING = {
		id     = "rbxassetid://1843326388",
		volume = 0.35,
		looped = true,
	},
	RACING = {
		FOREST = { id = "rbxassetid://1843326388", volume = 0.55, looped = true },
		OCEAN  = { id = "rbxassetid://1843326388", volume = 0.55, looped = true },
		SKY    = { id = "rbxassetid://1843326388", volume = 0.55, looped = true },
	},
	RESULTS_WIN  = { id = "rbxassetid://1843326388", volume = 0.6, looped = false },
	RESULTS_LOSE = { id = "rbxassetid://1843326388", volume = 0.5, looped = false },
}

-- ─── Biome Ambience ───────────────────────────────────────────────────────────

SoundConfig.AMBIENCE = {
	FOREST = {
		{ id = "rbxassetid://9125364642",  volume = 0.3, looped = true },  -- birds
		{ id = "rbxassetid://9125402785",  volume = 0.2, looped = true },  -- wind leaves
	},
	OCEAN = {
		{ id = "rbxassetid://9125364642",  volume = 0.35, looped = true }, -- waves
		{ id = "rbxassetid://9125364642",  volume = 0.15, looped = true }, -- seagulls
	},
	SKY = {
		{ id = "rbxassetid://9125402785",  volume = 0.25, looped = true }, -- high wind
	},
}

-- ─── SFX ─────────────────────────────────────────────────────────────────────

SoundConfig.SFX = {
	-- Farming
	ITEM_PICKUP         = { id = "rbxassetid://9125402785", volume = 0.7, pitch = 1.2  },
	ITEM_PICKUP_RARE    = { id = "rbxassetid://9125402785", volume = 0.8, pitch = 1.5  },
	ITEM_PICKUP_EPIC    = { id = "rbxassetid://9125402785", volume = 1.0, pitch = 1.8  },
	CONTEST_START       = { id = "rbxassetid://9125402785", volume = 0.8, pitch = 1.0  },
	CONTEST_WIN         = { id = "rbxassetid://9125402785", volume = 0.9, pitch = 1.3  },
	CONTEST_LOSE        = { id = "rbxassetid://9125402785", volume = 0.7, pitch = 0.7  },
	ITEM_STOLEN         = { id = "rbxassetid://9125402785", volume = 0.8, pitch = 0.8  },
	ITEM_DEFENDED       = { id = "rbxassetid://9125402785", volume = 0.8, pitch = 1.4  },

	-- Crafting
	SLOT_ASSIGN         = { id = "rbxassetid://9125402785", volume = 0.5, pitch = 1.1  },
	CRAFT_COMPLETE      = { id = "rbxassetid://9125402785", volume = 0.9, pitch = 1.0  },

	-- Racing
	BOOST_ACTIVATE      = { id = "rbxassetid://9125402785", volume = 0.8, pitch = 1.0  },
	BOOST_PAD           = { id = "rbxassetid://9125402785", volume = 0.7, pitch = 1.3  },
	DRIFT_START         = { id = "rbxassetid://9125402785", volume = 0.6, pitch = 0.9  },
	DRIFT_SLINGSHOT     = { id = "rbxassetid://9125402785", volume = 0.8, pitch = 1.4  },
	COLLISION           = { id = "rbxassetid://9125402785", volume = 0.9, pitch = 0.8  },
	MUD_ENTER           = { id = "rbxassetid://9125402785", volume = 0.6, pitch = 0.7  },
	UPDRAFT_ENTER       = { id = "rbxassetid://9125402785", volume = 0.5, pitch = 1.2  },
	RESPAWN             = { id = "rbxassetid://9125402785", volume = 0.7, pitch = 1.0  },
	BUBBLE_POP          = { id = "rbxassetid://9125402785", volume = 0.8, pitch = 1.5  },
	FINISH_1ST          = { id = "rbxassetid://9125402785", volume = 1.0, pitch = 1.0  },
	FINISH_OTHER        = { id = "rbxassetid://9125402785", volume = 0.7, pitch = 0.9  },

	-- Countdown
	COUNTDOWN_BEEP      = { id = "rbxassetid://9125402785", volume = 0.9, pitch = 1.0  },
	COUNTDOWN_GO        = { id = "rbxassetid://9125402785", volume = 1.0, pitch = 1.3  },

	-- Abilities (category-based)
	ABILITY_SPEED       = { id = "rbxassetid://9125402785", volume = 0.7, pitch = 1.2  },
	ABILITY_SHIELD      = { id = "rbxassetid://9125402785", volume = 0.7, pitch = 0.9  },
	ABILITY_OBSTACLE    = { id = "rbxassetid://9125402785", volume = 0.8, pitch = 0.8  },
	ABILITY_HACK        = { id = "rbxassetid://9125402785", volume = 0.8, pitch = 0.6  },
	ABILITY_FLOAT       = { id = "rbxassetid://9125402785", volume = 0.7, pitch = 1.1  },
	ABILITY_GENERIC     = { id = "rbxassetid://9125402785", volume = 0.6, pitch = 1.0  },

	-- UI
	PLAYER_JOIN         = { id = "rbxassetid://9125402785", volume = 0.5, pitch = 1.0  },
	PHASE_TRANSITION    = { id = "rbxassetid://9125402785", volume = 0.6, pitch = 1.0  },
	TIMER_LOW           = { id = "rbxassetid://9125402785", volume = 0.7, pitch = 1.5  },
}

-- ─── Ability → SFX category mapping ─────────────────────────────────────────

SoundConfig.ABILITY_SFX = {
	speedBoost    = "ABILITY_SPEED",
	paperBoost    = "ABILITY_SPEED",
	leafBoost     = "ABILITY_SPEED",
	flagAura      = "ABILITY_SPEED",
	overclock     = "ABILITY_SPEED",
	redline       = "ABILITY_SPEED",
	rocketBurst   = "ABILITY_SPEED",
	kettleBoost   = "ABILITY_SPEED",
	windBlast     = "ABILITY_SPEED",
	sodaBoost     = "ABILITY_SPEED",

	bubbleShield  = "ABILITY_SHIELD",
	backpackBlock = "ABILITY_SHIELD",
	sofaFortress  = "ABILITY_SHIELD",

	cactusObstacle= "ABILITY_OBSTACLE",
	leafPile      = "ABILITY_OBSTACLE",
	logObstacle   = "ABILITY_OBSTACLE",
	noodleSnare   = "ABILITY_OBSTACLE",
	steamCloud    = "ABILITY_OBSTACLE",

	hackControls  = "ABILITY_HACK",
	laptopHack    = "ABILITY_HACK",
	microFreeze   = "ABILITY_HACK",
	disguise      = "ABILITY_HACK",

	balloonLift   = "ABILITY_FLOAT",
	duckFloat     = "ABILITY_FLOAT",
	hover         = "ABILITY_FLOAT",
	raftGlide     = "ABILITY_FLOAT",
	emergencyFloat= "ABILITY_FLOAT",

	soundBlast    = "ABILITY_GENERIC",
	cartRam       = "ABILITY_GENERIC",
	bathSplash    = "ABILITY_GENERIC",
}

return SoundConfig
