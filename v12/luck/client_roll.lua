--[[
    luck/client_roll.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Optional hook over `math.random`.

    READ THIS BEFORE ENABLING IT
    ---------------------------
    Blox Fruits resolves fruit rolls on the server. The server picks the
    fruit and sends the client the outcome. A client-side hook over
    `math.random` therefore cannot change which fruit you get -- it can
    only change numbers that the client itself happens to roll, such as a
    cosmetic animation or a local shuffle.

    The v11 build shipped this hook as "100% Real Luck Enhancement". It
    was not, and it was also broken in two ways that this module fixes:

        1. it called `OriginalRandom(min, max)` even when `math.random()`
           was called with no arguments, which raised
           "bad argument #2 to 'random' (number expected, got nil)" and
           took the whole script down
        2. it ran `debug.traceback()` on *every* random call to guess
           whether it was a fruit roll. Roblox calls math.random thousands
           of times per second, so this was a large and constant frame
           cost. Here the call site is identified with `debug.getinfo`
           and the answer is cached per function.

    The module is therefore off by default and clearly labelled as
    cosmetic in the interface.
]]

local ClientRoll = {}

ClientRoll.__index = ClientRoll

-- Substrings that mark a call site as "interesting" in the v11 build.
-- Kept narrow on purpose: a wide list (the v11 one matched "random" and
-- "item") flags almost every call in the game.
local INTERESTING = { "fruit", "gacha", "luck", "drop", "roll" }

function ClientRoll.new(options)
    options = options or {}

    return setmetatable({
        _logger = options.logger,
        _cleanup = options.cleanup,
        _bias = options.bias or 0.35,   -- how strongly the low end is favoured
        _enabled = false,
        _originalRandom = nil,
        _originalSeed = nil,
        _cache = {},
        _hits = 0,
        _misses = 0,
    }, ClientRoll)
end

--- Decide whether the caller at stack level 2 is an "interesting" call.
--- The answer is cached per function name, so the cost is one table
--- lookup after the first call of each function.
function ClientRoll:_isInteresting()
    local info = debug.getinfo(2, "n")
    local name = info and info.name
    if not name then
        return false
    end

    local cached = self._cache[name]
    if cached ~= nil then
        return cached
    end

    local lowered = string.lower(name)
    local verdict = false
    for _, keyword in ipairs(INTERESTING) do
        if lowered:find(keyword, 1, true) then
            verdict = true
            break
        end
    end

    self._cache[name] = verdict
    return verdict
end

function ClientRoll:Enable()
    if self._enabled then
        return false
    end

    local originalRandom = math.random
    local originalSeed = math.randomseed
    self._originalRandom = originalRandom
    self._originalSeed = originalSeed

    local self_ = self

    math.random = function(a, b)
        -- Reproduce every calling convention of the original function.
        -- math.random()        -> float in [0, 1)
        -- math.random(max)     -> integer in [1, max]
        -- math.random(min, max) -> integer in [min, max]
        local result
        if a == nil then
            result = originalRandom()
        elseif b == nil then
            result = originalRandom(a)
        else
            result = originalRandom(a, b)
        end

        if not self_._enabled then
            return result
        end

        if b == nil then
            self_._misses = self_._misses + 1
            return result
        end

        if not self_:_isInteresting() then
            self_._misses = self_._misses + 1
            return result
        end

        -- Bias towards the low end of the range. Which end is "better"
        -- depends on the table the caller uses; the low end is the
        -- convention used by the fruit tables in this game.
        local span = b - a + 1
        if span <= 1 then
            self_._hits = self_._hits + 1
            return result
        end

        local threshold = a + math.floor(span * self_._bias)
        if result > threshold then
            self_._hits = self_._hits + 1
            return originalRandom(a, threshold)
        end

        self_._hits = self_._hits + 1
        return result
    end

    math.randomseed = originalSeed

    self._enabled = true

    if self._cleanup then
        self._cleanup:trackGlobal("math.random", originalRandom)
        self._cleanup:trackGlobal("math.randomseed", originalSeed)
    end

    if self._logger then
        self._logger:warn("Client-side roll bias is ENABLED -- cosmetic only, it cannot change server rolls")
    end

    return true
end

function ClientRoll:Disable()
    if not self._enabled then
        return false
    end

    if self._originalRandom then
        math.random = self._originalRandom
    end
    if self._originalSeed then
        math.randomseed = self._originalSeed
    end

    self._enabled = false
    self._cache = {}

    if self._logger then
        self._logger:info("Client-side roll bias disabled, math.random restored")
    end

    return true
end

function ClientRoll:IsEnabled()
    return self._enabled
end

function ClientRoll:SetBias(bias)
    local value = tonumber(bias) or 0.35
    if value < 0 then value = 0 elseif value > 0.9 then value = 0.9 end
    self._bias = value
end

function ClientRoll:GetStats()
    return {
        enabled = self._enabled,
        bias = self._bias,
        hits = self._hits,
        misses = self._misses,
        cachedCallSites = (function()
            local count = 0
            for _ in pairs(self._cache) do
                count = count + 1
            end
            return count
        end)(),
    }
end

return ClientRoll
