-- ItemTypes.lua
-- Canonical enum of all 37 item names and their slot type.
-- Import this anywhere you need item identity without stats.
-- Resolves: Issue #6, #62

local ItemTypes = {}

-- ─── Slot Types ───────────────────────────────────────────────────────────────
ItemTypes.SlotType = {
	BODY    = "BODY",
	ENGINE  = "ENGINE",
	SPECIAL = "SPECIAL",
}

-- ─── Item Registry ─────────────────────────────────────────────────────────────
-- { name, slotType }
-- Keep alphabetical within each tier for diffing convenience.

ItemTypes.ALL = {
	-- ── BODY (13) ─────────────────────────────────────────────────────────────
	{ name = "Backpack",      slotType = "BODY" },
	{ name = "Bamboo Raft",   slotType = "BODY" },
	{ name = "Bathtub",       slotType = "BODY" },
	{ name = "Cardboard Box", slotType = "BODY" },
	{ name = "Kite",          slotType = "BODY" },
	{ name = "Laptop",        slotType = "BODY" },
	{ name = "Life Preserver",slotType = "BODY" },
	{ name = "Log",           slotType = "BODY" },
	{ name = "Microwave",     slotType = "BODY" },
	{ name = "Red Sofa",      slotType = "BODY" },
	{ name = "Shopping Cart", slotType = "BODY" },
	{ name = "Skateboard",    slotType = "BODY" },
	{ name = "Stick",         slotType = "BODY" },

	-- ── ENGINE (12) ───────────────────────────────────────────────────────────
	{ name = "Big Gear",      slotType = "ENGINE" },
	{ name = "Cup Noodle",    slotType = "ENGINE" },
	{ name = "Flower",        slotType = "ENGINE" },
	{ name = "Kettle",        slotType = "ENGINE" },
	{ name = "Leaf Blower",   slotType = "ENGINE" },
	{ name = "Pinwheel",      slotType = "ENGINE" },
	{ name = "Propeller",     slotType = "ENGINE" },
	{ name = "Rocket",        slotType = "ENGINE" },
	{ name = "Shovel",        slotType = "ENGINE" },
	{ name = "Spinning Top",  slotType = "ENGINE" },
	{ name = "V8 Engine",     slotType = "ENGINE" },
	{ name = "Watering Can",  slotType = "ENGINE" },

	-- ── SPECIAL (12) ──────────────────────────────────────────────────────────
	{ name = "Balloon Bunch", slotType = "SPECIAL" },
	{ name = "Boombox",       slotType = "SPECIAL" },
	{ name = "Bubble Wrap",   slotType = "SPECIAL" },
	{ name = "Cactus",        slotType = "SPECIAL" },
	{ name = "Leaves",        slotType = "SPECIAL" },
	{ name = "Pizza",         slotType = "SPECIAL" },
	{ name = "Racing Flag",   slotType = "SPECIAL" },
	{ name = "Rocket Boost",  slotType = "SPECIAL" },
	{ name = "Rubber Duck",   slotType = "SPECIAL" },
	{ name = "Scarf",         slotType = "SPECIAL" },
	{ name = "Soda Bottle",   slotType = "SPECIAL" },
	{ name = "Toilet Paper",  slotType = "SPECIAL" },
	{ name = "Umbrella",      slotType = "SPECIAL" },
}

-- ─── Lookup helpers ───────────────────────────────────────────────────────────

-- Build name → entry map for O(1) lookup
ItemTypes.byName = {}
for _, item in ipairs(ItemTypes.ALL) do
	ItemTypes.byName[item.name] = item
end

-- Returns filtered list by slotType
function ItemTypes.getBySlot(slotType)
	local result = {}
	for _, item in ipairs(ItemTypes.ALL) do
		if item.slotType == slotType then
			table.insert(result, item)
		end
	end
	return result
end

return ItemTypes
