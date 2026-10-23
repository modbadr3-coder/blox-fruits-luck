--[[
    luck/roll_engine.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    The roll engine.

    It ties together the rarity tables, the fruit database and the luck
    statistics, and keeps a rolling history that the interface renders.

    Two important notes about what this engine is and is not:

    1. It rolls from the *modelled* tables. It does not and cannot change
       the odds the Blox Fruits server uses -- no client-side script can,
       because the server decides the result and only sends the outcome
       to the client.
    2. It is still useful: it powers the simulator in the Luck tab, it
       estimates the effective odds of the current table, and it grades
       the *real* results that the spawn and gacha trackers observe.
]]

local Rng = require("luck.rng")
local Rarity = require("luck.rarity")
local Fruits = require("data.fruits")
local LuckMath = require("luck.luck_math")
local Util = require("core.util")

local RollEngine = {}

RollEngine.__index = RollEngine

function RollEngine.new(options)
    options = options or {}

    local self = setmetatable({
        _rng = Rng.new(options.seed),
        _mode = options.mode or "spawn",   -- "spawn" | "gacha"
        _luckStat = options.luckStat or 0,
        _history = {},
        _maxHistory = options.maxHistory or 50,
        _totalRolls = 0,
        _rarityCounts = {},
        _lastResult = nil,
    }, RollEngine)

    for _, rarity in ipairs(Rarity.Order) do
        self._rarityCounts[rarity] = 0
    end

    return self
end

function RollEngine:SetMode(mode)
    self._mode = (mode == "gacha") and "gacha" or "spawn"
end

function RollEngine:GetMode()
    return self._mode
end

function RollEngine:SetLuckStat(value)
    self._luckStat = tonumber(value) or 0
end

function RollEngine:GetLuckStat()
    return self._luckStat
end

function RollEngine:SetHistoryLimit(limit)
    self._maxHistory = math.max(1, tonumber(limit) or 50)
    while #self._history > self._maxHistory do
        table.remove(self._history, 1)
    end
end

--- The weight table for the current mode, before luck is applied.
function RollEngine:BaseWeights()
    if self._mode == "gacha" then
        return Rarity.GACHA_WEIGHTS
    end
    return Rarity.SPAWN_WEIGHTS
end

--- The weight table actually used for a roll.
function RollEngine:EffectiveWeights()
    return Rarity.ApplyLuck(self:BaseWeights(), self._luckStat)
end

--- Roll a rarity, then a fruit inside that rarity.
--- Returns nil when the rarity is empty.
function RollEngine:Roll()
    local weights = self:EffectiveWeights()
    local rarityName = Rarity.Roll(weights, self._rng)

    local pool = Fruits.ByRarity[rarityName] or {}
    if #pool == 0 then
        return nil
    end

    local fruit = self._rng:PickWeighted(pool, "beli")

    local result = {
        rarity = rarityName,
        rank = Rarity.Rank(rarityName),
        fruit = fruit.name,
        type = fruit.type,
        beli = fruit.beli,
        timestamp = os.time(),
        luckStat = self._luckStat,
        mode = self._mode,
    }

    self:_record(result)
    return result
end

--- Roll `count` times. Returns the list of results.
function RollEngine:RollMany(count)
    local out = {}
    for _ = 1, (count or 10) do
        local result = self:Roll()
        if result then
            out[#out + 1] = result
        end
    end
    return out
end

function RollEngine:_record(result)
    self._totalRolls = self._totalRolls + 1
    self._rarityCounts[result.rarity] = (self._rarityCounts[result.rarity] or 0) + 1
    self._lastResult = result

    table.insert(self._history, result)
    if #self._history > self._maxHistory then
        table.remove(self._history, 1)
    end
end

--- Record a result that was observed in the real game (from the spawn or
--- gacha tracker) so that the statistics reflect reality rather than the
--- model.
function RollEngine:RecordExternal(result)
    if type(result) ~= "table" or not result.rarity then
        return false
    end
    result.external = true
    self:_record(result)
    return true
end

function RollEngine:History()
    return self._history
end

function RollEngine:LastResult()
    return self._lastResult
end

function RollEngine:TotalRolls()
    return self._totalRolls
end

function RollEngine:RarityCounts()
    return self._rarityCounts
end

--- Percentage of rolls that landed on each rarity.
function RollEngine:RarityDistribution()
    local out = {}
    for _, rarity in ipairs(Rarity.Order) do
        local count = self._rarityCounts[rarity] or 0
        local percent = 0
        if self._totalRolls > 0 then
            percent = (count / self._totalRolls) * 100
        end
        out[rarity] = {
            count = count,
            percent = percent,
        }
    end
    return out
end

--- Luck report for the recorded results.
function RollEngine:GetStats()
    local ranks = {}
    for _, result in ipairs(self._history) do
        ranks[#ranks + 1] = result.rank or Rarity.Rank(result.rarity)
    end

    local weights = self:BaseWeights()
    local expectedMean = Rarity.ExpectedRank(weights)
    local expectedStdDev = Rarity.StdDev(weights)

    local report = LuckMath.Report(ranks, expectedMean, expectedStdDev)

    return {
        -- NOTE: keys are lower camel case everywhere. The v11 build mixed
        -- `Active` and `active` in the same project, which is why its
        -- statistics tab always showed zeros.
        active = self._luckStat > 0,
        mode = self._mode,
        multiplier = 1 + self._luckStat,
        totalRolls = self._totalRolls,
        enhancedRolls = self._rarityCounts.Legendary + self._rarityCounts.Mythic,
        successRate = report.zScore and ((report.zScore + 3) / 6) * 100 or 0,
        luckRating = report.rating,
        luckVerdict = report.verdict,
        luckZScore = report.zScore,
        expectedMean = expectedMean,
        observedMean = report.mean,
        confidence = LuckMath.Confidence(report.zScore, report.count),
        lastResult = self._lastResult,
        distribution = self:RarityDistribution(),
    }
end

--- Effective probability of a rarity after luck is applied.
function RollEngine:EffectiveChance(rarity)
    local weights = self:EffectiveWeights()
    return Rarity.Chance(weights, rarity)
end

--- Monte-Carlo estimate of the effective odds. Used by the simulator tab
--- so the user can see the table they are actually rolling against.
function RollEngine:Simulate(iterations)
    iterations = iterations or 1000
    local counts = {}
    for _, rarity in ipairs(Rarity.Order) do
        counts[rarity] = 0
    end

    for _ = 1, iterations do
        local weights = self:EffectiveWeights()
        local picked = Rarity.Roll(weights, self._rng)
        counts[picked] = counts[picked] + 1
    end

    local out = {}
    for _, rarity in ipairs(Rarity.Order) do
        out[rarity] = {
            count = counts[rarity],
            percent = (counts[rarity] / iterations) * 100,
            expected = Rarity.Chance(self:EffectiveWeights(), rarity),
        }
    end
    return out
end

function RollEngine:Reset()
    self._history = {}
    self._totalRolls = 0
    self._lastResult = nil
    for _, rarity in ipairs(Rarity.Order) do
        self._rarityCounts[rarity] = 0
    end
end

return RollEngine
