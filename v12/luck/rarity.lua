--[[
    luck/rarity.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Rarity tiers, colours and the weight tables used by the roll engine.

    The developers have never published the exact drop rates, so the weights
    below are community estimates and are clearly marked as such. They are
    configuration, not fact: edit them in `luck/rarity.lua` and the whole
    engine follows.

    Two tables are provided because the game has two different economies:
        SPAWN -- a fruit found in the world (Mythic is roughly 0.5%)
        GACHA -- the Blox Fruit Gacha (Mythic is roughly 1-4%)
]]

local Rng = require("luck.rng")

local Rarity = {}

Rarity.Order = { "Common", "Uncommon", "Rare", "Legendary", "Mythic" }

Rarity.Colors = {
    Common = Color3.fromRGB(160, 165, 175),
    Uncommon = Color3.fromRGB(70, 205, 120),
    Rare = Color3.fromRGB(60, 160, 255),
    Legendary = Color3.fromRGB(190, 80, 230),
    Mythic = Color3.fromRGB(255, 170, 40),
}

Rarity.ShortLabels = {
    Common = "COM",
    Uncommon = "UNC",
    Rare = "RAR",
    Legendary = "LEG",
    Mythic = "MYT",
}

--- Community estimated weights.
Rarity.SPAWN_WEIGHTS = {
    Common = 60.0,
    Uncommon = 25.0,
    Rare = 11.0,
    Legendary = 3.4,
    Mythic = 0.6,
}

Rarity.GACHA_WEIGHTS = {
    Common = 46.0,
    Uncommon = 28.0,
    Rare = 15.0,
    Legendary = 8.0,
    Mythic = 3.0,
}

--- Value used for the "expected luck" maths. Roughly the middle of each
--- tier's Beli range, normalised.
Rarity.VALUE = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Legendary = 4,
    Mythic = 5,
}

function Rarity.Rank(name)
    for index, rarity in ipairs(Rarity.Order) do
        if rarity == name then
            return index
        end
    end
    return 0
end

function Rarity.Color(name)
    return Rarity.Colors[name] or Color3.fromRGB(200, 200, 200)
end

function Rarity.Short(name)
    return Rarity.ShortLabels[name] or string.sub(name or "?", 1, 3):upper()
end

--- Build a weighted list of { name, weight, rank } from a weight table.
function Rarity.ToWeightedList(weights)
    local list = {}
    for _, name in ipairs(Rarity.Order) do
        list[#list + 1] = {
            name = name,
            weight = weights[name] or 0,
            rank = Rarity.Rank(name),
        }
    end
    return list
end

--- Percentage chance of a rarity under a weight table.
function Rarity.Chance(weights, name)
    local total = 0
    for _, rarity in ipairs(Rarity.Order) do
        total = total + (weights[rarity] or 0)
    end
    if total <= 0 then
        return 0
    end
    return ((weights[name] or 0) / total) * 100
end

--- Apply a luck stat to a weight table.
---
--- Luck works the way it does in every modern gacha: the higher the tier,
--- the more a point of luck is worth. A luck stat of 1.0 gives Mythic
--- entries a 60% weight boost while Common entries gain almost nothing.
function Rarity.ApplyLuck(weights, luckStat)
    local out = {}
    for _, name in ipairs(Rarity.Order) do
        local rank = Rarity.Rank(name)
        local tierBonus = 1 + (rank - 1) * 0.20
        out[name] = (weights[name] or 0) * (1 + (luckStat or 0) * tierBonus)
    end
    return out
end

--- Expected rarity rank for a weight table.
function Rarity.ExpectedRank(weights)
    local total = 0
    local weighted = 0
    for _, name in ipairs(Rarity.Order) do
        local weight = weights[name] or 0
        total = total + weight
        weighted = weighted + weight * Rarity.Rank(name)
    end
    if total <= 0 then
        return 0
    end
    return weighted / total
end

--- Standard deviation of the rarity rank distribution.
function Rarity.StdDev(weights)
    local mean = Rarity.ExpectedRank(weights)
    local total = 0
    local variance = 0
    for _, name in ipairs(Rarity.Order) do
        local weight = weights[name] or 0
        total = total + weight
        variance = variance + weight * ((Rarity.Rank(name) - mean) ^ 2)
    end
    if total <= 0 then
        return 0
    end
    return math.sqrt(variance / total)
end

--- Roll a rarity name from a weight table using the given generator.
function Rarity.Roll(weights, generator)
    generator = generator or Rng.new()
    local list = Rarity.ToWeightedList(weights)
    local picked = generator:PickWeighted(list, "weight")
    return picked and picked.name or "Common"
end

return Rarity
