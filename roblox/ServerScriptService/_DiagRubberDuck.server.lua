-- Temporary diagnostic. Delete after debugging.

print("[DIAG] _DiagRubberDuck script loaded")

local ServerStorage    = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")

task.wait(3)

-- ── Global scan for v8_engine and ItemMeshes folder ─────────────────────────
print("[DIAG] ===== GLOBAL SCAN =====")
local function scan(root, label)
	local hits = 0
	for _, d in ipairs(root:GetDescendants()) do
		local n = d.Name:lower()
		if n:find("v8") or d.Name == "ItemMeshes" then
			hits = hits + 1
			print(string.format("[DIAG] [%s] %s (%s)", label, d:GetFullName(), d.ClassName))
		end
	end
	print(string.format("[DIAG] [%s] %d hits", label, hits))
end
scan(ServerStorage,    "ServerStorage")
scan(ReplicatedStorage,"ReplicatedStorage")
scan(Workspace,        "Workspace")
print("[DIAG] ===== END SCAN =====")

-- ── Dump first 5 Models in workspace.SpawnedItems (or any folder named so) ──
task.wait(10)  -- let farming spawn complete
print("[DIAG] ===== SPAWNED ITEMS =====")
local spawnFolder
for _, d in ipairs(Workspace:GetDescendants()) do
	if d:IsA("Folder") and (d.Name == "SpawnedItems" or d.Name == "Items") then
		spawnFolder = d
		break
	end
end
if spawnFolder then
	print(string.format("[DIAG] Found %s with %d children", spawnFolder:GetFullName(), #spawnFolder:GetChildren()))
	local count = 0
	for _, m in ipairs(spawnFolder:GetChildren()) do
		if count >= 3 then break end
		count = count + 1
		print(string.format("[DIAG] Item #%d: %s", count, m.Name))
		if m:IsA("Model") then
			print(string.format("[DIAG]   PrimaryPart=%s", m.PrimaryPart and m.PrimaryPart.Name or "nil"))
			local pc = 0
			for _, c in ipairs(m:GetDescendants()) do
				if c:IsA("BasePart") then
					pc = pc + 1
					print(string.format("[DIAG]   PART %s Size=%s Trans=%.1f",
						c.Name, tostring(c.Size), c.Transparency))
				end
			end
			print(string.format("[DIAG]   total parts=%d", pc))
		end
	end
else
	print("[DIAG] No SpawnedItems/Items folder found. Listing top-level workspace folders:")
	for _, c in ipairs(Workspace:GetChildren()) do
		print(string.format("[DIAG]   - %s (%s)", c.Name, c.ClassName))
	end
end
print("[DIAG] ===== END SPAWNED =====")
