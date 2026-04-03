-- GameBootstrap.server.lua
-- Single server Script entry point.
-- Requires GameManager and SessionManager (both ModuleScripts) so that
-- all other server scripts can require them via ServerScriptService.GameManager
-- and ServerScriptService.SessionManager.
-- Roblox can only `require()` ModuleScripts; Scripts cannot be required.
-- Resolves: architecture issue with .server.lua files not being requireable.

local ServerScriptService = game:GetService("ServerScriptService")

-- Load order matters: GameManager first (no deps), then SessionManager (needs GameManager)
require(ServerScriptService.GameManager)
require(ServerScriptService.SessionManager)
