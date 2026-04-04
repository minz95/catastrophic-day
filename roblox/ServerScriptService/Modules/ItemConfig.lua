-- ItemConfig.lua
-- Server-side entry point: re-exports the shared ReplicatedStorage version.
-- Keeps server requires working without path changes.
-- Resolves: Issue #6, #62, #67
return require(game.ReplicatedStorage.Shared.ItemConfig)
