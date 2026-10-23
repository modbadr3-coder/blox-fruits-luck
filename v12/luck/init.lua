--[[
    luck/init.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Luck module facade.

    Owns the roll engine, the spawn tracker, the gacha tracker and the
    optional client-side roll hook, and exposes a single surface to the
    interface.
]]

local RollEngine = require("luck.roll_engine")
local SpawnTracker = require("luck.spawn_tracker")
local GachaTracker = require("luck.gacha_tracker")
local ClientRoll = require("luck.client_roll")
local Rarity = require("luck.rarity")
local Fruits = require("data.fruits")
local LuckMath = require("luck.luck_math")

local Luck = {}

Luck.__index = Luck

function Luck.new(options)
    options = options or {}

    local self = setmetatable({
        _logger = options.logger,
        _settings = options.settings,
        _cleanup = options.cleanup,
        _engine = RollEngine.new({
            mode = "spawn",
            maxHistory = 50,
        }),
        _spawnTracker = nil,
        _gachaTracker = nil,
        _clientRoll = nil,
        _started = false,
    }, Luck)

    return self
end

function Luck:Start(suite)
    local settings = suite and suite:settings() or self._settings

    self:SpawnTracker():Start()
    self:GachaTracker()
    self:ClientRoll()

    -- react to the settings
    if settings then
        settings:onChange("luck.multiplier", function(value)
            self._engine:SetLuckStat(math.max(0, (tonumber(value) or 1) - 1))
        end)

        settings:onChange("luck.rollHistorySize", function(value)
            self._engine:SetHistoryLimit(value)
        end)

        settings:onChange("luck.trackGacha", function(value)
            if value then
                self._gachaTracker:Start()
            else
                self._gachaTracker:Stop()
            end
        end)
    end

    -- apply the current values
    if settings then
        self._engine:SetLuckStat(math.max(0, (settings:get("luck.multiplier", 2) or 2) - 1))
        self._engine:SetHistoryLimit(settings:get("luck.rollHistorySize", 50))
        if settings:get("luck.trackGacha", true) then
            self._gachaTracker:Start()
        end
    end

    self._started = true

    if self._logger then
        self._logger:info("Luck module started (engine + spawn tracker + gacha tracker)")
    end

    return true
end

function Luck:Stop()
    self._started = false
    if self._gachaTracker then
        self._gachaTracker:Stop()
    end
    if self._clientRoll then
        self._clientRoll:Disable()
    end
    return true
end

--- True once Start() has run successfully.
function Luck:IsStarted()
    return self._started
end

-- ── accessors ────────────────────────────────────────────────────────────

function Luck:Engine()
    return self._engine
end

--- The spawn tracker, created on first use.
---
--- The interface is built before the modules are started, so the tabs ask
--- for the tracker while it does not exist yet. Creating it lazily keeps
--- both orderings safe.
function Luck:SpawnTracker()
    if not self._spawnTracker then
        self._spawnTracker = SpawnTracker.new({
            logger = self._logger,
            engine = self._engine,
            maxHistory = 100,
        })
        self._spawnTracker:Start()
    end
    return self._spawnTracker
end

--- The gacha tracker, created on first use.
function Luck:GachaTracker()
    if not self._gachaTracker then
        self._gachaTracker = GachaTracker.new({
            logger = self._logger,
            engine = self._engine,
        })
    end
    return self._gachaTracker
end

--- The optional client-side roll hook, created on first use.
function Luck:ClientRoll()
    if not self._clientRoll then
        self._clientRoll = ClientRoll.new({
            logger = self._logger,
            cleanup = self._cleanup,
        })
    end
    return self._clientRoll
end

--- One snapshot for the dashboard.
function Luck:GetStats()
    local engineStats = self._engine:GetStats()
    local spawnDistribution = self._spawnTracker and self._spawnTracker:Distribution() or {}
    local gachaHistory = self._gachaTracker and self._gachaTracker:History() or {}

    return {
        engine = engineStats,
        spawns = {
            total = self._spawnTracker and #self._spawnTracker:History() or 0,
            active = self._spawnTracker and #self._spawnTracker:Active() or 0,
            distribution = spawnDistribution,
        },
        gacha = {
            total = #gachaHistory,
            last = gachaHistory[#gachaHistory],
        },
        clientRoll = self._clientRoll and self._clientRoll:GetStats() or { enabled = false },
        chances = {
            spawn = {
                legendary = Rarity.Chance(Rarity.SPAWN_WEIGHTS, "Legendary"),
                mythic = Rarity.Chance(Rarity.SPAWN_WEIGHTS, "Mythic"),
            },
            gacha = {
                legendary = Rarity.Chance(Rarity.GACHA_WEIGHTS, "Legendary"),
                mythic = Rarity.Chance(Rarity.GACHA_WEIGHTS, "Mythic"),
            },
        },
    }
end

--- Roll once using the engine. Used by the "Roll" button in the Luck tab.
function Luck:Roll()
    return self._engine:Roll()
end

function Luck:SetMode(mode)
    self._engine:SetMode(mode)
end

function Luck:GetMode()
    return self._engine:GetMode()
end

function Luck:SetLuckStat(value)
    self._engine:SetLuckStat(value)
end

function Luck:GetLuckStat()
    return self._engine:GetLuckStat()
end

function Luck:Simulate(iterations)
    return self._engine:Simulate(iterations)
end

function Luck:Reset()
    self._engine:Reset()
    if self._spawnTracker then
        self._spawnTracker:Reset()
    end
    if self._gachaTracker then
        self._gachaTracker:Reset()
    end
end

return Luck
