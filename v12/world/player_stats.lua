--[[
    world/player_stats.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Reads the player's live statistics.

    Blox Fruits keeps the HUD values in IntValue / NumberValue instances
    inside the local player's PlayerGui. The names have changed over time
    ("Level", "XP", "Beli", "Bounty", "Honor", "Mastery"), so every value
    is looked up through a list of candidates.

    This is what the dashboard shows, and the auto-farm module uses the
    level to pick a sensible target.
]]

local Util = require("core.util")

local PlayerStats = {}

PlayerStats.__index = PlayerStats

PlayerStats.CANDIDATES = {
    level = { "Level", "PlayerLevel", "LevelValue" },
    xp = { "XP", "Experience", "Exp" },
    beli = { "Beli", "Money", "Cash" },
    bounty = { "Bounty", "BountyValue" },
    honor = { "Honor", "HonorValue" },
    mastery = { "Mastery", "FruitMastery" },
    fruit = { "CurrentFruit", "FruitName", "EquippedFruit" },
}

function PlayerStats.new(options)
    options = options or {}

    return setmetatable({
        _logger = options.logger,
        _cache = {},
        _cacheTime = 0,
        _cacheLifetime = 0.5,
    }, PlayerStats)
end

function PlayerStats:_playerGui()
    local ok, Players = pcall(function()
        return game:GetService("Players")
    end)
    if not ok then
        return nil
    end
    local okPlayer, player = pcall(function()
        return Players.LocalPlayer
    end)
    if not okPlayer or not player then
        return nil
    end
    local okGui, playerGui = pcall(function()
        return player:FindFirstChildOfClass("PlayerGui")
    end)
    if okGui then
        return playerGui
    end
    return nil
end

--- Look up a numeric HUD value.
function PlayerStats:_readNumeric(candidates)
    local playerGui = self:_playerGui()
    if not playerGui then
        return nil
    end

    for _, candidate in ipairs(candidates) do
        local ok, value = pcall(function()
            local found = playerGui:FindFirstChild(candidate, true)
            if not found then
                return nil
            end
            if found:IsA("IntValue") or found:IsA("NumberValue") or found:IsA("StringValue") then
                local raw = found.Value
                if type(raw) == "string" then
                    return tonumber(raw)
                end
                return raw
            end
            return nil
        end)
        if ok and type(value) == "number" then
            return value
        end
    end

    return nil
end

--- Look up a string HUD value.
function PlayerStats:_readString(candidates)
    local playerGui = self:_playerGui()
    if not playerGui then
        return nil
    end

    for _, candidate in ipairs(candidates) do
        local ok, value = pcall(function()
            local found = playerGui:FindFirstChild(candidate, true)
            if not found then
                return nil
            end
            if found:IsA("StringValue") or found:IsA("TextLabel") or found:IsA("TextButton") then
                return found.Value or found.Text
            end
            return nil
        end)
        if ok and type(value) == "string" and value ~= "" then
            return value
        end
    end

    return nil
end

--- Read every statistic. Results are cached briefly so the UI can poll
--- this without hammering the PlayerGui.
function PlayerStats:Get()
    local now = os.clock()
    if now - self._cacheTime < self._cacheLifetime then
        return self._cache
    end
    self._cacheTime = now

    local stats = {
        level = self:_readNumeric(PlayerStats.CANDIDATES.level) or 0,
        xp = self:_readNumeric(PlayerStats.CANDIDATES.xp) or 0,
        beli = self:_readNumeric(PlayerStats.CANDIDATES.beli) or 0,
        bounty = self:_readNumeric(PlayerStats.CANDIDATES.bounty) or 0,
        honor = self:_readNumeric(PlayerStats.CANDIDATES.honor) or 0,
        mastery = self:_readNumeric(PlayerStats.CANDIDATES.mastery) or 0,
        fruit = self:_readString(PlayerStats.CANDIDATES.fruit) or "None",
    }

    self._cache = stats
    return stats
end

--- Current level only -- used by the auto-farm target picker.
function PlayerStats:GetLevel()
    return self:Get().level
end

function PlayerStats:Invalidate()
    self._cacheTime = 0
end

return PlayerStats
