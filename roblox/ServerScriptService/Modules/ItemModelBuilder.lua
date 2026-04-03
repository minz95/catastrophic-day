-- ItemModelBuilder.lua
-- Builds 3D Part-based models for all 37 items.
-- Each item is a Model with a PrimaryPart and named sub-parts.
-- Materials use Roblox built-in textures — no external asset IDs needed.
-- Resolves: Issue #24 #25 #26

local ItemModelBuilder = {}

-- ─── Part factory ─────────────────────────────────────────────────────────────

local function _p(model, name, size, cframe, color, material, transparency)
	local p = Instance.new("Part")
	p.Name         = name
	p.Size         = size
	p.CFrame       = cframe
	p.Color        = color
	p.Material     = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored     = false
	p.CanCollide   = false
	p.CastShadow   = false
	p.Parent       = model
	return p
end

local function _w(model, part0, part1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0  = part0
	weld.Part1  = part1
	weld.Parent = model
end

local function _sphere(model, name, radius, offset, color, material)
	local p = _p(model, name,
		Vector3.new(radius * 2, radius * 2, radius * 2),
		CFrame.new(offset),
		color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent   = p
	return p
end

local function _cylinder(model, name, radius, height, offset, rotation, color, material)
	local p = _p(model, name,
		Vector3.new(radius * 2, height, radius * 2),
		CFrame.new(offset) * (rotation or CFrame.Angles(0,0,0)),
		color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Parent   = p
	return p
end

local function _wedge(model, name, size, cframe, color, material)
	local p = Instance.new("WedgePart")
	p.Name      = name
	p.Size      = size
	p.CFrame    = cframe
	p.Color     = color
	p.Material  = material or Enum.Material.SmoothPlastic
	p.Anchored  = false
	p.CanCollide = false
	p.Parent    = model
	return p
end

-- Scale factor: items are built at ~1.5–2 stud scale
local SCALE = 1.5

-- ─── BODY items ──────────────────────────────────────────────────────────────

local function _buildStick(root)
	local main = _cylinder(root, "Stick",
		0.15 * SCALE, 3 * SCALE, Vector3.new(0,0,0),
		CFrame.Angles(0, 0, math.rad(15)),
		Color3.fromRGB(140, 90, 40), Enum.Material.Wood)
	return main
end

local function _buildCardboardBox(root)
	local box = _p(root, "Body",
		Vector3.new(2,2,2) * SCALE, CFrame.new(0,0,0),
		Color3.fromRGB(200, 160, 100), Enum.Material.SmoothPlastic)
	-- Tape strips
	local tapeH = _p(root, "TapeH",
		Vector3.new(2.05 * SCALE, 0.15 * SCALE, 0.4 * SCALE), CFrame.new(0, 0.3 * SCALE, 0),
		Color3.fromRGB(140, 180, 200), Enum.Material.SmoothPlastic)
	local tapeV = _p(root, "TapeV",
		Vector3.new(0.4 * SCALE, 0.15 * SCALE, 2.05 * SCALE), CFrame.new(0, 0.3 * SCALE, 0),
		Color3.fromRGB(140, 180, 200), Enum.Material.SmoothPlastic)
	_w(root, box, tapeH)
	_w(root, box, tapeV)
	return box
end

local function _buildBambooRaft(root)
	-- 4 bamboo poles side by side
	local first
	for i = 0, 3 do
		local pole = _cylinder(root, "Pole" .. i,
			0.3 * SCALE, 3 * SCALE,
			Vector3.new((i - 1.5) * 0.7 * SCALE, 0, 0),
			CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(120, 160, 60), Enum.Material.Wood)
		if i == 0 then first = pole
		else _w(root, first, pole) end
	end
	-- Cross lashings
	local lash = _p(root, "Lash",
		Vector3.new(2.2 * SCALE, 0.25 * SCALE, 0.4 * SCALE), CFrame.new(0, 0.35 * SCALE, 0),
		Color3.fromRGB(160, 110, 40), Enum.Material.Wood)
	_w(root, first, lash)
	return first
end

local function _buildSkateboard(root)
	local deck = _p(root, "Deck",
		Vector3.new(2.6 * SCALE, 0.25 * SCALE, 1 * SCALE), CFrame.new(0,0,0),
		Color3.fromRGB(200, 80, 80), Enum.Material.Wood)
	-- Trucks
	for _, z in ipairs({ -0.8 * SCALE, 0.8 * SCALE }) do
		local truck = _p(root, "Truck",
			Vector3.new(1.2 * SCALE, 0.2 * SCALE, 0.2 * SCALE), CFrame.new(0, -0.2 * SCALE, z),
			Color3.fromRGB(180, 180, 180), Enum.Material.Metal)
		_w(root, deck, truck)
		-- Wheels
		for _, side in ipairs({ -0.5 * SCALE, 0.5 * SCALE }) do
			local wheel = _cylinder(root, "Wheel",
				0.25 * SCALE, 0.3 * SCALE,
				Vector3.new(side, -0.35 * SCALE, z),
				CFrame.Angles(math.rad(90), 0, 0),
				Color3.fromRGB(40, 40, 40), Enum.Material.SmoothPlastic)
			_w(root, deck, wheel)
		end
	end
	return deck
end

local function _buildLog(root)
	local log = _cylinder(root, "Log",
		0.6 * SCALE, 3.5 * SCALE, Vector3.new(0,0,0),
		CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(100, 65, 35), Enum.Material.Wood)
	-- Bark rings
	for _, z in ipairs({ -1 * SCALE, 0, 1 * SCALE }) do
		local ring = _cylinder(root, "Ring",
			0.62 * SCALE, 0.2 * SCALE, Vector3.new(z, 0, 0),
			CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(80, 50, 25), Enum.Material.Wood)
		_w(root, log, ring)
	end
	return log
end

local function _buildShoppingCart(root)
	local basket = _p(root, "Basket",
		Vector3.new(2 * SCALE, 1.4 * SCALE, 1.2 * SCALE), CFrame.new(0, 0.4 * SCALE, 0),
		Color3.fromRGB(160, 160, 160), Enum.Material.Metal)
	basket.Transparency = 0.5
	-- Frame bars
	local base = _p(root, "Base",
		Vector3.new(2 * SCALE, 0.15 * SCALE, 1.2 * SCALE), CFrame.new(0, -0.1 * SCALE, 0),
		Color3.fromRGB(140, 140, 140), Enum.Material.Metal)
	_w(root, basket, base)
	-- 4 wheels
	for _, pos in ipairs({ {-0.8, -0.55}, {0.8, -0.55}, {-0.8, 0.55}, {0.8, 0.55} }) do
		local wheel = _cylinder(root, "Wheel",
			0.2 * SCALE, 0.15 * SCALE,
			Vector3.new(pos[1] * SCALE, -0.5 * SCALE, pos[2] * SCALE),
			CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic)
		_w(root, basket, wheel)
	end
	return basket
end

local function _buildLifePreserver(root)
	local ring = _cylinder(root, "Ring",
		0.7 * SCALE, 0.3 * SCALE, Vector3.new(0,0,0), nil,
		Color3.fromRGB(220, 40, 40), Enum.Material.SmoothPlastic)
	-- Inner hole (white quarter sections)
	for i = 0, 3 do
		local angle = (i / 4) * math.pi * 2
		local qx = math.cos(angle) * 0.5 * SCALE
		local qz = math.sin(angle) * 0.5 * SCALE
		local seg = _cylinder(root, "Seg" .. i,
			0.35 * SCALE, 0.35 * SCALE,
			Vector3.new(qx, 0, qz), nil,
			i % 2 == 0 and Color3.fromRGB(220, 40, 40) or Color3.fromRGB(240, 240, 240),
			Enum.Material.SmoothPlastic)
		_w(root, ring, seg)
	end
	return ring
end

local function _buildKite(root)
	-- Diamond shape using two wedges
	local top = _wedge(root, "Top",
		Vector3.new(1.5 * SCALE, 1.5 * SCALE, 0.15 * SCALE),
		CFrame.new(0, 0.5 * SCALE, 0),
		Color3.fromRGB(220, 60, 60), Enum.Material.SmoothPlastic)
	local bot = _wedge(root, "Bot",
		Vector3.new(1.5 * SCALE, 1.5 * SCALE, 0.15 * SCALE),
		CFrame.new(0, -0.5 * SCALE, 0) * CFrame.Angles(math.pi, 0, 0),
		Color3.fromRGB(60, 100, 220), Enum.Material.SmoothPlastic)
	_w(root, top, bot)
	-- Tail string
	local tail = _p(root, "Tail",
		Vector3.new(0.08 * SCALE, 3 * SCALE, 0.08 * SCALE), CFrame.new(0, -2.5 * SCALE, 0),
		Color3.fromRGB(240, 200, 60), Enum.Material.SmoothPlastic)
	_w(root, top, tail)
	return top
end

local function _buildLaptop(root)
	local base = _p(root, "Base",
		Vector3.new(2.2 * SCALE, 0.15 * SCALE, 1.5 * SCALE), CFrame.new(0,0,0),
		Color3.fromRGB(60, 60, 60), Enum.Material.SmoothPlastic)
	local screen = _p(root, "Screen",
		Vector3.new(2.2 * SCALE, 1.5 * SCALE, 0.1 * SCALE),
		CFrame.new(0, 0.85 * SCALE, -0.7 * SCALE) * CFrame.Angles(math.rad(-15), 0, 0),
		Color3.fromRGB(40, 40, 40), Enum.Material.SmoothPlastic)
	local display = _p(root, "Display",
		Vector3.new(2 * SCALE, 1.3 * SCALE, 0.05 * SCALE),
		CFrame.new(0, 0.85 * SCALE, -0.74 * SCALE) * CFrame.Angles(math.rad(-15), 0, 0),
		Color3.fromRGB(40, 120, 200), Enum.Material.Neon)
	_w(root, base, screen)
	_w(root, base, display)
	-- Keyboard keys (simplified grid)
	local kbd = _p(root, "Keyboard",
		Vector3.new(1.8 * SCALE, 0.05 * SCALE, 1.1 * SCALE), CFrame.new(0, 0.1 * SCALE, 0.1 * SCALE),
		Color3.fromRGB(80, 80, 80), Enum.Material.SmoothPlastic)
	_w(root, base, kbd)
	return base
end

local function _buildBackpack(root)
	local body = _p(root, "Body",
		Vector3.new(1.8 * SCALE, 2.2 * SCALE, 0.9 * SCALE), CFrame.new(0,0,0),
		Color3.fromRGB(40, 80, 160), Enum.Material.Fabric)
	local pocket = _p(root, "Pocket",
		Vector3.new(1.4 * SCALE, 0.9 * SCALE, 0.2 * SCALE),
		CFrame.new(0, -0.5 * SCALE, 0.55 * SCALE),
		Color3.fromRGB(30, 60, 130), Enum.Material.Fabric)
	local strap1 = _p(root, "Strap1",
		Vector3.new(0.25 * SCALE, 2 * SCALE, 0.1 * SCALE),
		CFrame.new(-0.5 * SCALE, 0, -0.5 * SCALE),
		Color3.fromRGB(20, 50, 100), Enum.Material.SmoothPlastic)
	local strap2 = _p(root, "Strap2",
		Vector3.new(0.25 * SCALE, 2 * SCALE, 0.1 * SCALE),
		CFrame.new(0.5 * SCALE, 0, -0.5 * SCALE),
		Color3.fromRGB(20, 50, 100), Enum.Material.SmoothPlastic)
	_w(root, body, pocket)
	_w(root, body, strap1)
	_w(root, body, strap2)
	return body
end

local function _buildSofa(root)
	local seat = _p(root, "Seat",
		Vector3.new(2.8 * SCALE, 0.6 * SCALE, 1.4 * SCALE), CFrame.new(0,0,0),
		Color3.fromRGB(180, 50, 50), Enum.Material.Fabric)
	local back = _p(root, "Back",
		Vector3.new(2.8 * SCALE, 1.2 * SCALE, 0.3 * SCALE),
		CFrame.new(0, 0.9 * SCALE, -0.55 * SCALE),
		Color3.fromRGB(180, 50, 50), Enum.Material.Fabric)
	for _, side in ipairs({ -1.25 * SCALE, 1.25 * SCALE }) do
		local arm = _p(root, "Arm",
			Vector3.new(0.4 * SCALE, 0.8 * SCALE, 1.4 * SCALE),
			CFrame.new(side, 0.4 * SCALE, 0),
			Color3.fromRGB(160, 40, 40), Enum.Material.Fabric)
		_w(root, seat, arm)
	end
	local cushion = _p(root, "Cushion",
		Vector3.new(2.4 * SCALE, 0.35 * SCALE, 1.2 * SCALE),
		CFrame.new(0, 0.47 * SCALE, 0.05 * SCALE),
		Color3.fromRGB(200, 80, 80), Enum.Material.Fabric)
	_w(root, seat, back)
	_w(root, seat, cushion)
	return seat
end

local function _buildMicrowave(root)
	local body = _p(root, "Body",
		Vector3.new(2.2 * SCALE, 1.6 * SCALE, 1.8 * SCALE), CFrame.new(0,0,0),
		Color3.fromRGB(220, 220, 220), Enum.Material.SmoothPlastic)
	local door = _p(root, "Door",
		Vector3.new(1.6 * SCALE, 1.3 * SCALE, 0.1 * SCALE),
		CFrame.new(-0.2 * SCALE, 0, 0.95 * SCALE),
		Color3.fromRGB(40, 40, 40), Enum.Material.SmoothPlastic)
	door.Transparency = 0.6
	local panel = _p(root, "Panel",
		Vector3.new(0.55 * SCALE, 1.3 * SCALE, 0.1 * SCALE),
		CFrame.new(0.85 * SCALE, 0, 0.95 * SCALE),
		Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic)
	-- Neon display
	local disp = _p(root, "Display",
		Vector3.new(0.4 * SCALE, 0.3 * SCALE, 0.05 * SCALE),
		CFrame.new(0.85 * SCALE, 0.2 * SCALE, 1.01 * SCALE),
		Color3.fromRGB(60, 220, 60), Enum.Material.Neon)
	_w(root, body, door)
	_w(root, body, panel)
	_w(root, body, disp)
	return body
end

local function _buildBathtub(root)
	local tub = _p(root, "Tub",
		Vector3.new(3 * SCALE, 1.2 * SCALE, 1.6 * SCALE), CFrame.new(0,0,0),
		Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic)
	local inner = _p(root, "Inner",
		Vector3.new(2.6 * SCALE, 0.9 * SCALE, 1.2 * SCALE),
		CFrame.new(0, 0.15 * SCALE, 0),
		Color3.fromRGB(200, 230, 255), Enum.Material.SmoothPlastic)
	inner.Transparency = 0.4
	-- Faucet
	local faucet = _cylinder(root, "Faucet",
		0.1 * SCALE, 0.5 * SCALE,
		Vector3.new(0, 0.7 * SCALE, -0.6 * SCALE), nil,
		Color3.fromRGB(180, 180, 180), Enum.Material.Metal)
	local spout = _cylinder(root, "Spout",
		0.08 * SCALE, 0.4 * SCALE,
		Vector3.new(0, 0.7 * SCALE, -0.4 * SCALE),
		CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(180, 180, 180), Enum.Material.Metal)
	_w(root, tub, inner)
	_w(root, tub, faucet)
	_w(root, tub, spout)
	return tub
end

-- ─── ENGINE items ─────────────────────────────────────────────────────────────

local function _buildShovel(root)
	local handle = _cylinder(root, "Handle",
		0.12 * SCALE, 3 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(120, 80, 40), Enum.Material.Wood)
	local blade = _p(root, "Blade",
		Vector3.new(0.8 * SCALE, 0.6 * SCALE, 0.08 * SCALE),
		CFrame.new(0, -1.6 * SCALE, 0),
		Color3.fromRGB(160, 160, 160), Enum.Material.Metal)
	_w(root, handle, blade)
	return handle
end

local function _buildFlower(root)
	local stem = _cylinder(root, "Stem",
		0.12 * SCALE, 2 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(60, 140, 40), Enum.Material.SmoothPlastic)
	local center = _sphere(root, "Center", 0.3 * SCALE, Vector3.new(0, 1.1 * SCALE, 0),
		Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic)
	_w(root, stem, center)
	-- Petals
	for i = 0, 5 do
		local angle = (i / 6) * math.pi * 2
		local px = math.cos(angle) * 0.5 * SCALE
		local pz = math.sin(angle) * 0.5 * SCALE
		local petal = _sphere(root, "Petal" .. i, 0.2 * SCALE,
			Vector3.new(px, 1.1 * SCALE, pz),
			Color3.fromRGB(255, 120, 160), Enum.Material.SmoothPlastic)
		_w(root, stem, petal)
	end
	-- Leaf
	local leaf = _p(root, "Leaf",
		Vector3.new(0.5 * SCALE, 0.08 * SCALE, 0.3 * SCALE),
		CFrame.new(0.3 * SCALE, 0, 0) * CFrame.Angles(0, 0, math.rad(-30)),
		Color3.fromRGB(50, 160, 40), Enum.Material.SmoothPlastic)
	_w(root, stem, leaf)
	return stem
end

local function _buildPinwheel(root)
	local stick = _cylinder(root, "Stick",
		0.1 * SCALE, 2.5 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(120, 80, 40), Enum.Material.Wood)
	local hub = _sphere(root, "Hub", 0.18 * SCALE, Vector3.new(0, 1.3 * SCALE, 0),
		Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic)
	_w(root, stick, hub)
	local colors = {
		Color3.fromRGB(220, 60, 60),
		Color3.fromRGB(60, 120, 220),
		Color3.fromRGB(60, 200, 80),
		Color3.fromRGB(220, 200, 40),
	}
	for i = 0, 3 do
		local angle = (i / 4) * math.pi * 2
		local blade = _wedge(root, "Blade" .. i,
			Vector3.new(0.5 * SCALE, 0.6 * SCALE, 0.06 * SCALE),
			CFrame.new(0, 1.3 * SCALE, 0)
				* CFrame.Angles(0, angle, math.rad(30)),
			colors[i + 1], Enum.Material.SmoothPlastic)
		_w(root, stick, blade)
	end
	return stick
end

local function _buildWateringCan(root)
	local body = _p(root, "Body",
		Vector3.new(1.2 * SCALE, 1.4 * SCALE, 0.9 * SCALE), CFrame.new(0, 0, 0),
		Color3.fromRGB(60, 140, 200), Enum.Material.Metal)
	local spout = _cylinder(root, "Spout",
		0.15 * SCALE, 1.2 * SCALE,
		Vector3.new(0.5 * SCALE, 0.4 * SCALE, 0),
		CFrame.Angles(0, 0, math.rad(-30)),
		Color3.fromRGB(50, 120, 180), Enum.Material.Metal)
	local handle = _p(root, "Handle",
		Vector3.new(0.12 * SCALE, 1.1 * SCALE, 0.12 * SCALE),
		CFrame.new(-0.7 * SCALE, 0.2 * SCALE, 0),
		Color3.fromRGB(50, 120, 180), Enum.Material.Metal)
	_w(root, body, spout)
	_w(root, body, handle)
	return body
end

local function _buildBigGear(root)
	local center = _cylinder(root, "Center",
		0.8 * SCALE, 0.4 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(140, 140, 140), Enum.Material.Metal)
	local hole = _cylinder(root, "Hole",
		0.25 * SCALE, 0.5 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(80, 80, 80), Enum.Material.Metal)
	_w(root, center, hole)
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local tx = math.cos(angle) * 0.9 * SCALE
		local tz = math.sin(angle) * 0.9 * SCALE
		local tooth = _p(root, "Tooth" .. i,
			Vector3.new(0.25 * SCALE, 0.4 * SCALE, 0.35 * SCALE),
			CFrame.new(tx, 0, tz) * CFrame.Angles(0, -angle, 0),
			Color3.fromRGB(130, 130, 130), Enum.Material.Metal)
		_w(root, center, tooth)
	end
	return center
end

local function _buildLeafBlower(root)
	local body = _cylinder(root, "Body",
		0.45 * SCALE, 2.2 * SCALE, Vector3.new(0, 0, 0),
		CFrame.Angles(0, 0, math.rad(20)),
		Color3.fromRGB(40, 160, 60), Enum.Material.SmoothPlastic)
	local nozzle = _cylinder(root, "Nozzle",
		0.3 * SCALE, 0.8 * SCALE,
		Vector3.new(0.5 * SCALE, -0.5 * SCALE, 0),
		CFrame.Angles(0, 0, math.rad(-40)),
		Color3.fromRGB(30, 120, 50), Enum.Material.SmoothPlastic)
	local handle = _p(root, "Handle",
		Vector3.new(0.2 * SCALE, 0.9 * SCALE, 0.2 * SCALE),
		CFrame.new(-0.3 * SCALE, -0.8 * SCALE, 0),
		Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic)
	_w(root, body, nozzle)
	_w(root, body, handle)
	return body
end

local function _buildSpinningTop(root)
	local cone = _wedge(root, "Cone",
		Vector3.new(1.2 * SCALE, 1.4 * SCALE, 1.2 * SCALE),
		CFrame.new(0, -0.4 * SCALE, 0) * CFrame.Angles(math.rad(180), 0, 0),
		Color3.fromRGB(220, 60, 60), Enum.Material.SmoothPlastic)
	local top = _sphere(root, "Top", 0.3 * SCALE, Vector3.new(0, 0.5 * SCALE, 0),
		Color3.fromRGB(220, 200, 40), Enum.Material.SmoothPlastic)
	local tip = _cylinder(root, "Tip",
		0.06 * SCALE, 0.6 * SCALE, Vector3.new(0, -1.1 * SCALE, 0), nil,
		Color3.fromRGB(160, 160, 160), Enum.Material.Metal)
	_w(root, cone, top)
	_w(root, cone, tip)
	-- Stripes
	for i = 0, 2 do
		local stripe = _cylinder(root, "Stripe" .. i,
			0.62 * SCALE, 0.2 * SCALE,
			Vector3.new(0, -0.1 * SCALE + i * 0.3 * SCALE, 0), nil,
			Color3.fromRGB(60, 120, 220), Enum.Material.SmoothPlastic)
		_w(root, cone, stripe)
	end
	return cone
end

local function _buildPropeller(root)
	local hub = _cylinder(root, "Hub",
		0.25 * SCALE, 0.5 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(80, 80, 80), Enum.Material.Metal)
	local shaft = _cylinder(root, "Shaft",
		0.12 * SCALE, 1 * SCALE, Vector3.new(0, -0.7 * SCALE, 0), nil,
		Color3.fromRGB(100, 100, 100), Enum.Material.Metal)
	_w(root, hub, shaft)
	for i = 0, 2 do
		local angle = (i / 3) * math.pi * 2
		local bx = math.cos(angle) * 0.8 * SCALE
		local bz = math.sin(angle) * 0.8 * SCALE
		local blade = _wedge(root, "Blade" .. i,
			Vector3.new(0.4 * SCALE, 1.4 * SCALE, 0.08 * SCALE),
			CFrame.new(bx * 0.5, 0, bz * 0.5) * CFrame.Angles(0, -angle, math.rad(-20)),
			Color3.fromRGB(60, 60, 60), Enum.Material.SmoothPlastic)
		_w(root, hub, blade)
	end
	return hub
end

local function _buildV8Engine(root)
	local block = _p(root, "Block",
		Vector3.new(2.2 * SCALE, 1.6 * SCALE, 2 * SCALE), CFrame.new(0, 0, 0),
		Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
	-- 8 cylinder heads in V shape
	for row = 0, 1 do
		for col = 0, 3 do
			local side = row == 0 and -1 or 1
			local cyl = _cylinder(root, "Cyl_" .. row .. "_" .. col,
				0.25 * SCALE, 0.7 * SCALE,
				Vector3.new((col - 1.5) * 0.55 * SCALE, 0.9 * SCALE, side * 0.4 * SCALE),
				CFrame.Angles(0, 0, math.rad(side * -15)),
				Color3.fromRGB(80, 80, 80), Enum.Material.Metal)
			_w(root, block, cyl)
		end
	end
	-- Exhaust pipes
	for i = 0, 3 do
		local pipe = _cylinder(root, "Exhaust" .. i,
			0.08 * SCALE, 1.2 * SCALE,
			Vector3.new((i - 1.5) * 0.55 * SCALE, -0.8 * SCALE, -1.1 * SCALE),
			CFrame.Angles(math.rad(30), 0, 0),
			Color3.fromRGB(100, 100, 100), Enum.Material.Metal)
		_w(root, block, pipe)
	end
	return block
end

local function _buildRocket(root)
	local body = _cylinder(root, "Body",
		0.4 * SCALE, 3 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(220, 220, 220), Enum.Material.SmoothPlastic)
	-- Nose cone
	local nose = _wedge(root, "Nose",
		Vector3.new(0.8 * SCALE, 1 * SCALE, 0.8 * SCALE),
		CFrame.new(0, 2 * SCALE, 0),
		Color3.fromRGB(220, 60, 60), Enum.Material.SmoothPlastic)
	-- Fins
	for i = 0, 3 do
		local angle = (i / 4) * math.pi * 2
		local fx = math.cos(angle) * 0.5 * SCALE
		local fz = math.sin(angle) * 0.5 * SCALE
		local fin = _wedge(root, "Fin" .. i,
			Vector3.new(0.8 * SCALE, 1 * SCALE, 0.08 * SCALE),
			CFrame.new(fx * 0.5, -1.2 * SCALE, fz * 0.5) * CFrame.Angles(0, -angle, 0),
			Color3.fromRGB(200, 60, 60), Enum.Material.SmoothPlastic)
		_w(root, body, fin)
	end
	-- Exhaust glow
	local exhaust = _cylinder(root, "Exhaust",
		0.35 * SCALE, 0.4 * SCALE, Vector3.new(0, -1.7 * SCALE, 0), nil,
		Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
	_w(root, body, nose)
	_w(root, body, exhaust)
	return body
end

local function _buildCupNoodle(root)
	-- Cup body (truncated cylinder)
	local cup = _cylinder(root, "Cup",
		0.7 * SCALE, 1.6 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(220, 60, 40), Enum.Material.SmoothPlastic)
	local lid = _cylinder(root, "Lid",
		0.72 * SCALE, 0.1 * SCALE, Vector3.new(0, 0.85 * SCALE, 0), nil,
		Color3.fromRGB(240, 220, 180), Enum.Material.SmoothPlastic)
	-- Noodles sticking out
	for i = 0, 4 do
		local angle = (i / 5) * math.pi * 2
		local nx = math.cos(angle) * 0.3 * SCALE
		local nz = math.sin(angle) * 0.3 * SCALE
		local noodle = _cylinder(root, "Noodle" .. i,
			0.06 * SCALE, 0.6 * SCALE,
			Vector3.new(nx, 1.1 * SCALE, nz),
			CFrame.Angles(math.rad(30), angle, 0),
			Color3.fromRGB(240, 200, 120), Enum.Material.SmoothPlastic)
		_w(root, cup, noodle)
	end
	_w(root, cup, lid)
	return cup
end

local function _buildKettle(root)
	local body = _sphere(root, "Body", 0.8 * SCALE, Vector3.new(0, 0, 0),
		Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
	local spout = _cylinder(root, "Spout",
		0.15 * SCALE, 1 * SCALE,
		Vector3.new(0.7 * SCALE, 0.3 * SCALE, 0),
		CFrame.Angles(0, 0, math.rad(-50)),
		Color3.fromRGB(50, 50, 50), Enum.Material.Metal)
	local handle = _p(root, "Handle",
		Vector3.new(0.15 * SCALE, 1 * SCALE, 0.15 * SCALE),
		CFrame.new(-0.95 * SCALE, 0.2 * SCALE, 0),
		Color3.fromRGB(140, 80, 40), Enum.Material.Wood)
	local lid = _cylinder(root, "Lid",
		0.35 * SCALE, 0.2 * SCALE, Vector3.new(0, 0.85 * SCALE, 0), nil,
		Color3.fromRGB(50, 50, 50), Enum.Material.Metal)
	local steam = _cylinder(root, "Steam",
		0.1 * SCALE, 0.3 * SCALE, Vector3.new(0, 1.1 * SCALE, 0), nil,
		Color3.fromRGB(200, 220, 255), Enum.Material.Neon)
	_w(root, body, spout)
	_w(root, body, handle)
	_w(root, body, lid)
	_w(root, body, steam)
	return body
end

-- ─── SPECIAL items ────────────────────────────────────────────────────────────

local function _buildPizza(root)
	local slice = _wedge(root, "Slice",
		Vector3.new(1.8 * SCALE, 0.15 * SCALE, 1.4 * SCALE),
		CFrame.new(0, 0, 0),
		Color3.fromRGB(220, 160, 80), Enum.Material.SmoothPlastic)
	-- Toppings
	for i = 0, 4 do
		local angle = (i / 5) * math.pi
		local tx = math.cos(angle) * 0.4 * SCALE
		local tz = math.sin(angle) * 0.3 * SCALE - 0.2 * SCALE
		local topping = _sphere(root, "Top" .. i, 0.12 * SCALE,
			Vector3.new(tx, 0.15 * SCALE, tz),
			Color3.fromRGB(180, 50, 50), Enum.Material.SmoothPlastic)
		_w(root, slice, topping)
	end
	-- Cheese layer
	local cheese = _wedge(root, "Cheese",
		Vector3.new(1.6 * SCALE, 0.05 * SCALE, 1.2 * SCALE),
		CFrame.new(0.05 * SCALE, 0.1 * SCALE, 0),
		Color3.fromRGB(240, 200, 60), Enum.Material.SmoothPlastic)
	_w(root, slice, cheese)
	return slice
end

local function _buildToiletPaper(root)
	local roll = _cylinder(root, "Roll",
		0.5 * SCALE, 1 * SCALE, Vector3.new(0, 0, 0),
		CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(245, 245, 240), Enum.Material.SmoothPlastic)
	local core = _cylinder(root, "Core",
		0.2 * SCALE, 1.05 * SCALE, Vector3.new(0, 0, 0),
		CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(200, 180, 160), Enum.Material.SmoothPlastic)
	-- Tail strip
	local tail = _p(root, "Tail",
		Vector3.new(0.9 * SCALE, 0.06 * SCALE, 0.3 * SCALE),
		CFrame.new(0.5 * SCALE, -0.5 * SCALE, 0),
		Color3.fromRGB(245, 245, 240), Enum.Material.SmoothPlastic)
	_w(root, roll, core)
	_w(root, roll, tail)
	return roll
end

local function _buildLeaves(root)
	local stem = _cylinder(root, "Stem",
		0.08 * SCALE, 1.5 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(80, 120, 40), Enum.Material.SmoothPlastic)
	local leafColors = {
		Color3.fromRGB(60, 160, 40), Color3.fromRGB(80, 180, 50),
		Color3.fromRGB(50, 140, 30), Color3.fromRGB(100, 170, 60),
		Color3.fromRGB(40, 150, 35),
	}
	for i = 0, 4 do
		local angle = (i / 5) * math.pi * 2
		local lx = math.cos(angle) * 0.6 * SCALE
		local lz = math.sin(angle) * 0.6 * SCALE
		local leaf = _p(root, "Leaf" .. i,
			Vector3.new(0.7 * SCALE, 0.06 * SCALE, 0.4 * SCALE),
			CFrame.new(lx * 0.5, 0.5 * SCALE, lz * 0.5)
				* CFrame.Angles(0, angle, math.rad(-20)),
			leafColors[i + 1], Enum.Material.SmoothPlastic)
		_w(root, stem, leaf)
	end
	return stem
end

local function _buildRacingFlag(root)
	local pole = _cylinder(root, "Pole",
		0.1 * SCALE, 2.5 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(160, 160, 160), Enum.Material.Metal)
	-- Checkered flag
	for row = 0, 2 do
		for col = 0, 3 do
			local tile = _p(root, string.format("Tile_%d_%d", row, col),
				Vector3.new(0.5 * SCALE, 0.5 * SCALE, 0.04 * SCALE),
				CFrame.new(
					(col * 0.5 + 0.25) * SCALE,
					(1 + row * 0.5) * SCALE,
					0
				),
				(row + col) % 2 == 0 and Color3.new(0,0,0) or Color3.new(1,1,1),
				Enum.Material.SmoothPlastic)
			_w(root, pole, tile)
		end
	end
	return pole
end

local function _buildCactus(root)
	local trunk = _cylinder(root, "Trunk",
		0.3 * SCALE, 2.5 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(60, 140, 60), Enum.Material.SmoothPlastic)
	for _, arm in ipairs({ {-0.4, 0.5}, {0.4, 0} }) do
		local armPart = _cylinder(root, "Arm",
			0.2 * SCALE, 1 * SCALE,
			Vector3.new(arm[1] * SCALE, arm[2] * SCALE, 0),
			CFrame.Angles(0, 0, math.rad(arm[1] > 0 and 60 or -60)),
			Color3.fromRGB(50, 130, 50), Enum.Material.SmoothPlastic)
		_w(root, trunk, armPart)
		local armTop = _cylinder(root, "ArmTop",
			0.2 * SCALE, 0.6 * SCALE,
			Vector3.new(arm[1] * SCALE + (arm[1] > 0 and 0.5 or -0.5) * SCALE,
				(arm[2] + 0.7) * SCALE, 0), nil,
			Color3.fromRGB(50, 130, 50), Enum.Material.SmoothPlastic)
		_w(root, trunk, armTop)
	end
	-- Spines (neon dots)
	for i = 0, 5 do
		local angle = (i / 6) * math.pi * 2
		local spine = _sphere(root, "Spine" .. i, 0.05 * SCALE,
			Vector3.new(math.cos(angle) * 0.35 * SCALE, i * 0.3 * SCALE - 0.6 * SCALE, math.sin(angle) * 0.35 * SCALE),
			Color3.fromRGB(200, 200, 100), Enum.Material.Neon)
		_w(root, trunk, spine)
	end
	return trunk
end

local function _buildScarf(root)
	-- Long wavy ribbon
	local main = _p(root, "Scarf",
		Vector3.new(0.4 * SCALE, 0.15 * SCALE, 3 * SCALE), CFrame.new(0, 0, 0),
		Color3.fromRGB(180, 60, 60), Enum.Material.Fabric)
	local stripe = _p(root, "Stripe",
		Vector3.new(0.4 * SCALE, 0.16 * SCALE, 0.4 * SCALE), CFrame.new(0, 0, -1.2 * SCALE),
		Color3.fromRGB(240, 240, 240), Enum.Material.Fabric)
	local fringe = _p(root, "Fringe",
		Vector3.new(0.3 * SCALE, 0.15 * SCALE, 0.5 * SCALE), CFrame.new(0, 0, -1.6 * SCALE),
		Color3.fromRGB(180, 60, 60), Enum.Material.Fabric)
	_w(root, main, stripe)
	_w(root, main, fringe)
	return main
end

local function _buildBoombox(root)
	local body = _p(root, "Body",
		Vector3.new(2.6 * SCALE, 1.2 * SCALE, 0.8 * SCALE), CFrame.new(0,0,0),
		Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic)
	-- Speakers
	for _, side in ipairs({ -0.7 * SCALE, 0.7 * SCALE }) do
		local speaker = _cylinder(root, "Speaker",
			0.45 * SCALE, 0.3 * SCALE,
			Vector3.new(side, 0, 0.45 * SCALE), nil,
			Color3.fromRGB(40, 40, 40), Enum.Material.SmoothPlastic)
		local cone = _cylinder(root, "Cone",
			0.3 * SCALE, 0.1 * SCALE,
			Vector3.new(side, 0, 0.5 * SCALE), nil,
			Color3.fromRGB(60, 60, 60), Enum.Material.SmoothPlastic)
		_w(root, body, speaker)
		_w(root, body, cone)
	end
	-- Display
	local disp = _p(root, "Display",
		Vector3.new(0.8 * SCALE, 0.4 * SCALE, 0.1 * SCALE),
		CFrame.new(0, 0.2 * SCALE, 0.45 * SCALE),
		Color3.fromRGB(60, 200, 60), Enum.Material.Neon)
	local antenna = _cylinder(root, "Antenna",
		0.05 * SCALE, 1 * SCALE, Vector3.new(-1.1 * SCALE, 0.8 * SCALE, 0),
		CFrame.Angles(0, 0, math.rad(20)),
		Color3.fromRGB(160, 160, 160), Enum.Material.Metal)
	_w(root, body, disp)
	_w(root, body, antenna)
	return body
end

local function _buildUmbrella(root)
	local handle = _cylinder(root, "Handle",
		0.1 * SCALE, 2 * SCALE, Vector3.new(0, -0.5 * SCALE, 0), nil,
		Color3.fromRGB(80, 40, 20), Enum.Material.Wood)
	-- Canopy sections
	local colors = {
		Color3.fromRGB(220, 60, 60), Color3.fromRGB(60, 120, 220),
		Color3.fromRGB(220, 200, 40), Color3.fromRGB(60, 180, 60),
		Color3.fromRGB(180, 60, 220), Color3.fromRGB(220, 120, 40),
		Color3.fromRGB(60, 200, 220), Color3.fromRGB(220, 60, 120),
	}
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local sx = math.cos(angle) * 0.7 * SCALE
		local sz = math.sin(angle) * 0.7 * SCALE
		local seg = _wedge(root, "Seg" .. i,
			Vector3.new(0.7 * SCALE, 0.5 * SCALE, 0.05 * SCALE),
			CFrame.new(sx * 0.5, 0.8 * SCALE, sz * 0.5) * CFrame.Angles(math.rad(-30), -angle, 0),
			colors[i + 1], Enum.Material.SmoothPlastic)
		_w(root, handle, seg)
	end
	-- Tip
	local tip = _sphere(root, "Tip", 0.12 * SCALE, Vector3.new(0, 1 * SCALE, 0),
		Color3.fromRGB(200, 200, 200), Enum.Material.Metal)
	_w(root, handle, tip)
	return handle
end

local function _buildRubberDuck(root)
	local body = _sphere(root, "Body", 0.7 * SCALE, Vector3.new(0, 0, 0),
		Color3.fromRGB(255, 220, 40), Enum.Material.SmoothPlastic)
	local head = _sphere(root, "Head", 0.45 * SCALE, Vector3.new(0.5 * SCALE, 0.4 * SCALE, 0),
		Color3.fromRGB(255, 220, 40), Enum.Material.SmoothPlastic)
	local beak = _wedge(root, "Beak",
		Vector3.new(0.3 * SCALE, 0.2 * SCALE, 0.15 * SCALE),
		CFrame.new(0.95 * SCALE, 0.35 * SCALE, 0) * CFrame.Angles(0, 0, math.rad(-20)),
		Color3.fromRGB(255, 140, 20), Enum.Material.SmoothPlastic)
	local eyeL = _sphere(root, "EyeL", 0.08 * SCALE,
		Vector3.new(0.7 * SCALE, 0.6 * SCALE, 0.25 * SCALE),
		Color3.fromRGB(10, 10, 10), Enum.Material.SmoothPlastic)
	local eyeR = _sphere(root, "EyeR", 0.08 * SCALE,
		Vector3.new(0.7 * SCALE, 0.6 * SCALE, -0.25 * SCALE),
		Color3.fromRGB(10, 10, 10), Enum.Material.SmoothPlastic)
	_w(root, body, head)
	_w(root, body, beak)
	_w(root, body, eyeL)
	_w(root, body, eyeR)
	return body
end

local function _buildBubbleWrap(root)
	local sheet = _p(root, "Sheet",
		Vector3.new(2 * SCALE, 0.15 * SCALE, 2 * SCALE), CFrame.new(0,0,0),
		Color3.fromRGB(200, 230, 255), Enum.Material.SmoothPlastic)
	sheet.Transparency = 0.4
	for row = 0, 2 do
		for col = 0, 2 do
			local bubble = _sphere(root, string.format("Bubble_%d_%d", row, col),
				0.25 * SCALE,
				Vector3.new((col - 1) * 0.7 * SCALE, 0.15 * SCALE, (row - 1) * 0.7 * SCALE),
				Color3.fromRGB(200, 230, 255), Enum.Material.SmoothPlastic)
			bubble.Transparency = 0.3
			_w(root, sheet, bubble)
		end
	end
	return sheet
end

local function _buildBalloonBunch(root)
	local string_main = _cylinder(root, "String",
		0.05 * SCALE, 1.5 * SCALE, Vector3.new(0, -0.5 * SCALE, 0), nil,
		Color3.fromRGB(200, 200, 200), Enum.Material.SmoothPlastic)
	local colors = {
		Color3.fromRGB(220, 60, 60),
		Color3.fromRGB(60, 120, 220),
		Color3.fromRGB(220, 200, 40),
		Color3.fromRGB(60, 200, 80),
		Color3.fromRGB(180, 60, 220),
	}
	local offsets = {
		Vector3.new(-0.4, 0.7, 0.1), Vector3.new(0.3, 0.9, -0.2),
		Vector3.new(0, 1.1, 0.3), Vector3.new(-0.2, 0.6, -0.3),
		Vector3.new(0.5, 0.8, 0.1),
	}
	for i, off in ipairs(offsets) do
		local balloon = _sphere(root, "Balloon" .. i, 0.35 * SCALE,
			off * SCALE, colors[i], Enum.Material.SmoothPlastic)
		_w(root, string_main, balloon)
		local knot = _sphere(root, "Knot" .. i, 0.06 * SCALE,
			(off - Vector3.new(0, 0.3, 0)) * SCALE,
			colors[i], Enum.Material.SmoothPlastic)
		_w(root, string_main, knot)
	end
	return string_main
end

local function _buildSodaBottle(root)
	local bottle = _cylinder(root, "Bottle",
		0.4 * SCALE, 2.4 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(40, 160, 80), Enum.Material.SmoothPlastic)
	bottle.Transparency = 0.35
	local cap = _cylinder(root, "Cap",
		0.3 * SCALE, 0.3 * SCALE, Vector3.new(0, 1.35 * SCALE, 0), nil,
		Color3.fromRGB(200, 40, 40), Enum.Material.SmoothPlastic)
	local label = _cylinder(root, "Label",
		0.41 * SCALE, 0.9 * SCALE, Vector3.new(0, 0, 0), nil,
		Color3.fromRGB(220, 60, 40), Enum.Material.SmoothPlastic)
	-- Bubbles inside
	for i = 0, 5 do
		local bub = _sphere(root, "Bubble" .. i, 0.06 * SCALE,
			Vector3.new(
				(math.random() - 0.5) * 0.4 * SCALE,
				(i - 2) * 0.35 * SCALE,
				(math.random() - 0.5) * 0.4 * SCALE
			),
			Color3.fromRGB(180, 230, 255), Enum.Material.Neon)
		_w(root, bottle, bub)
	end
	_w(root, bottle, cap)
	_w(root, bottle, label)
	return bottle
end

-- ─── Registry ─────────────────────────────────────────────────────────────────

local BUILDERS = {
	-- BODY
	["Stick"]          = _buildStick,
	["Cardboard Box"]  = _buildCardboardBox,
	["Bamboo Raft"]    = _buildBambooRaft,
	["Skateboard"]     = _buildSkateboard,
	["Log"]            = _buildLog,
	["Shopping Cart"]  = _buildShoppingCart,
	["Life Preserver"] = _buildLifePreserver,
	["Kite"]           = _buildKite,
	["Laptop"]         = _buildLaptop,
	["Backpack"]       = _buildBackpack,
	["Red Sofa"]       = _buildSofa,
	["Microwave"]      = _buildMicrowave,
	["Bathtub"]        = _buildBathtub,
	-- ENGINE
	["Shovel"]         = _buildShovel,
	["Flower"]         = _buildFlower,
	["Pinwheel"]       = _buildPinwheel,
	["Watering Can"]   = _buildWateringCan,
	["Big Gear"]       = _buildBigGear,
	["Leaf Blower"]    = _buildLeafBlower,
	["Spinning Top"]   = _buildSpinningTop,
	["Propeller"]      = _buildPropeller,
	["V8 Engine"]      = _buildV8Engine,
	["Rocket"]         = _buildRocket,
	["Cup Noodle"]     = _buildCupNoodle,
	["Kettle"]         = _buildKettle,
	-- SPECIAL
	["Pizza"]          = _buildPizza,
	["Toilet Paper"]   = _buildToiletPaper,
	["Leaves"]         = _buildLeaves,
	["Racing Flag"]    = _buildRacingFlag,
	["Cactus"]         = _buildCactus,
	["Scarf"]          = _buildScarf,
	["Boombox"]        = _buildBoombox,
	["Umbrella"]       = _buildUmbrella,
	["Rubber Duck"]    = _buildRubberDuck,
	["Bubble Wrap"]    = _buildBubbleWrap,
	["Balloon Bunch"]  = _buildBalloonBunch,
	["Soda Bottle"]    = _buildSodaBottle,
}

-- ─── Public API ───────────────────────────────────────────────────────────────

-- Build a Model for the given item name.
-- Returns a Model with PrimaryPart set, parented to `parent`.
function ItemModelBuilder.build(itemName, parent)
	local builder = BUILDERS[itemName]
	if not builder then
		-- Fallback: coloured cube with label
		local model = Instance.new("Model")
		model.Name = itemName
		local cube = _p(model, "Primary",
			Vector3.new(SCALE, SCALE, SCALE), CFrame.new(0, 0, 0),
			Color3.fromRGB(180, 180, 180), Enum.Material.SmoothPlastic)
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 80, 0, 30)
		billboard.StudsOffset = Vector3.new(0, 1.5, 0)
		billboard.Parent = cube
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Text = itemName
		lbl.TextScaled = true
		lbl.Font = Enum.Font.GothamBold
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.Parent = billboard
		model.PrimaryPart = cube
		model.Parent = parent
		return model
	end

	local model = Instance.new("Model")
	model.Name = itemName

	local primary = builder(model)
	model.PrimaryPart = primary
	model.Parent = parent

	-- Weld all loose parts to primary
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= primary then
			local hasWeld = false
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("WeldConstraint") then hasWeld = true; break end
			end
			for _, child in ipairs(model:GetChildren()) do
				if child:IsA("WeldConstraint") and (child.Part0 == primary and child.Part1 == part) then
					hasWeld = true; break
				end
			end
			if not hasWeld then _w(model, primary, part) end
		end
	end

	return model
end

-- Pre-build all items into ServerStorage for fast cloning during farming spawn
function ItemModelBuilder.preloadAll(storageFolder)
	for itemName in pairs(BUILDERS) do
		local ok, err = pcall(function()
			local m = ItemModelBuilder.build(itemName, storageFolder)
			m.Name = itemName
		end)
		if not ok then
			warn("[ItemModelBuilder] Failed to build " .. itemName .. ": " .. tostring(err))
		end
	end
	print(string.format("[ItemModelBuilder] Preloaded %d item models", #storageFolder:GetChildren()))
end

return ItemModelBuilder
