-- CharacterConfig.lua
-- 10 unique character skin configs with colour palettes.
-- Resolves: Issue #12

local CharacterConfig = {}

-- Each skin defines body colour, clothing colours, and an icon emoji.
-- bodyColor: Torso/limb BrickColor
-- headColor: Head BrickColor (sometimes different for helmet/hat effect)
-- shirtColor / pantsColor: RGB for programmatic clothing
-- accessory: optional hat/accessory description (for Studio prop)
-- icon: emoji used in LobbyUI player list

CharacterConfig.SKINS = {
	[1] = {
		name        = "Racer Red",
		icon        = "🔴",
		bodyColor   = BrickColor.new("Bright red"),
		headColor   = BrickColor.new("Bright red"),
		shirtColor  = Color3.fromRGB(200, 30,  30),
		pantsColor  = Color3.fromRGB(80,  10,  10),
		helmetColor = Color3.fromRGB(255, 60,  60),
	},
	[2] = {
		name        = "Ocean Blue",
		icon        = "🔵",
		bodyColor   = BrickColor.new("Bright blue"),
		headColor   = BrickColor.new("Bright blue"),
		shirtColor  = Color3.fromRGB(30,  80,  220),
		pantsColor  = Color3.fromRGB(10,  30,  100),
		helmetColor = Color3.fromRGB(60,  140, 255),
	},
	[3] = {
		name        = "Forest Green",
		icon        = "🟢",
		bodyColor   = BrickColor.new("Bright green"),
		headColor   = BrickColor.new("Bright green"),
		shirtColor  = Color3.fromRGB(30,  160, 30),
		pantsColor  = Color3.fromRGB(10,  70,  10),
		helmetColor = Color3.fromRGB(80,  200, 60),
	},
	[4] = {
		name        = "Solar Yellow",
		icon        = "🟡",
		bodyColor   = BrickColor.new("Bright yellow"),
		headColor   = BrickColor.new("Bright yellow"),
		shirtColor  = Color3.fromRGB(230, 200, 20),
		pantsColor  = Color3.fromRGB(120, 100, 10),
		helmetColor = Color3.fromRGB(255, 240, 60),
	},
	[5] = {
		name        = "Midnight Purple",
		icon        = "🟣",
		bodyColor   = BrickColor.new("Medium lilac"),
		headColor   = BrickColor.new("Medium lilac"),
		shirtColor  = Color3.fromRGB(100, 40,  180),
		pantsColor  = Color3.fromRGB(40,  10,  80),
		helmetColor = Color3.fromRGB(160, 100, 255),
	},
	[6] = {
		name        = "Ghost White",
		icon        = "⚪",
		bodyColor   = BrickColor.new("White"),
		headColor   = BrickColor.new("White"),
		shirtColor  = Color3.fromRGB(240, 240, 240),
		pantsColor  = Color3.fromRGB(180, 180, 180),
		helmetColor = Color3.fromRGB(255, 255, 255),
	},
	[7] = {
		name        = "Ember Orange",
		icon        = "🟠",
		bodyColor   = BrickColor.new("Bright orange"),
		headColor   = BrickColor.new("Bright orange"),
		shirtColor  = Color3.fromRGB(220, 100, 20),
		pantsColor  = Color3.fromRGB(100, 40,  10),
		helmetColor = Color3.fromRGB(255, 150, 40),
	},
	[8] = {
		name        = "Cyber Teal",
		icon        = "🩵",
		bodyColor   = BrickColor.new("Cyan"),
		headColor   = BrickColor.new("Cyan"),
		shirtColor  = Color3.fromRGB(20,  180, 180),
		pantsColor  = Color3.fromRGB(10,  80,  80),
		helmetColor = Color3.fromRGB(60,  220, 220),
	},
	[9] = {
		name        = "Shadow Black",
		icon        = "⚫",
		bodyColor   = BrickColor.new("Black"),
		headColor   = BrickColor.new("Dark stone grey"),
		shirtColor  = Color3.fromRGB(30,  30,  30),
		pantsColor  = Color3.fromRGB(10,  10,  10),
		helmetColor = Color3.fromRGB(60,  60,  60),
	},
	[10] = {
		name        = "Cotton Pink",
		icon        = "🩷",
		bodyColor   = BrickColor.new("Hot pink"),
		headColor   = BrickColor.new("Hot pink"),
		shirtColor  = Color3.fromRGB(220, 80,  160),
		pantsColor  = Color3.fromRGB(120, 20,  80),
		helmetColor = Color3.fromRGB(255, 140, 200),
	},
}

function CharacterConfig.get(skinIndex)
	return CharacterConfig.SKINS[skinIndex] or CharacterConfig.SKINS[1]
end

function CharacterConfig.count()
	return #CharacterConfig.SKINS
end

return CharacterConfig
