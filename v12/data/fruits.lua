--[[
    data/fruits.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Fruit reference table.

    Rarity tiers and membership follow the live game (snapshot: 2026-10).
    Dealer prices are community-reported and drift between game updates --
    they are display-only and are never used by the roll engine.

    Aliases let the tracker match the in-game model names, which have
    changed over time:
        Chop   -> Blade      (pre-2024 name)
        Revive -> Ghost      (pre-2024 name)
        Leopard-> Tiger      (renamed, both spellings still appear in scripts)
]]

local Fruits = {}

Fruits.Order = { "Common", "Uncommon", "Rare", "Legendary", "Mythic" }

-- name, rarity, type, beli, robux, aliases
Fruits.List = {
    -- ── Common ──────────────────────────────────────────────────────────
    { name = "Rocket",    rarity = "Common",    type = "Natural",  beli = 5000,      robux = 50 },
    { name = "Spin",      rarity = "Common",    type = "Natural",  beli = 7500,      robux = 75 },
    { name = "Blade",     rarity = "Common",    type = "Natural",  beli = 30000,     robux = 100,  aliases = { "Chop" } },
    { name = "Spring",    rarity = "Common",    type = "Natural",  beli = 60000,     robux = 180 },
    { name = "Bomb",      rarity = "Common",    type = "Natural",  beli = 80000,     robux = 220 },
    { name = "Smoke",     rarity = "Common",    type = "Elemental", beli = 100000,    robux = 250 },
    { name = "Spike",     rarity = "Common",    type = "Natural",  beli = 180000,    robux = 380 },

    -- ── Uncommon ────────────────────────────────────────────────────────
    { name = "Flame",     rarity = "Uncommon",  type = "Elemental", beli = 250000,    robux = 550 },
    { name = "Ice",       rarity = "Uncommon",  type = "Elemental", beli = 350000,    robux = 750 },
    { name = "Sand",      rarity = "Uncommon",  type = "Elemental", beli = 420000,    robux = 850 },
    { name = "Dark",      rarity = "Uncommon",  type = "Elemental", beli = 500000,    robux = 950 },
    { name = "Eagle",     rarity = "Uncommon",  type = "Beast",     beli = 550000,    robux = 975 },
    { name = "Diamond",   rarity = "Uncommon",  type = "Natural",  beli = 600000,    robux = 1000 },

    -- ── Rare ────────────────────────────────────────────────────────────
    { name = "Light",     rarity = "Rare",      type = "Elemental", beli = 650000,    robux = 1100 },
    { name = "Rubber",    rarity = "Rare",      type = "Natural",  beli = 750000,    robux = 1200 },
    { name = "Ghost",     rarity = "Rare",      type = "Natural",  beli = 940000,    robux = 1275,  aliases = { "Revive" } },
    { name = "Magma",     rarity = "Rare",      type = "Elemental", beli = 960000,    robux = 1300 },

    -- ── Legendary ───────────────────────────────────────────────────────
    { name = "Quake",     rarity = "Legendary", type = "Natural",  beli = 1000000,   robux = 1500 },
    { name = "Buddha",    rarity = "Legendary", type = "Beast",     beli = 1200000,   robux = 1650 },
    { name = "Love",      rarity = "Legendary", type = "Natural",  beli = 1300000,   robux = 1700 },
    { name = "Creation",  rarity = "Legendary", type = "Natural",  beli = 1400000,   robux = 1750 },
    { name = "Spider",    rarity = "Legendary", type = "Natural",  beli = 1500000,   robux = 1800 },
    { name = "Sound",     rarity = "Legendary", type = "Natural",  beli = 1700000,   robux = 1900 },
    { name = "Phoenix",   rarity = "Legendary", type = "Beast",     beli = 1800000,   robux = 2000 },
    { name = "Portal",    rarity = "Legendary", type = "Natural",  beli = 1900000,   robux = 2000 },
    { name = "Lightning", rarity = "Legendary", type = "Elemental", beli = 2100000,   robux = 2100 },
    { name = "Pain",      rarity = "Legendary", type = "Natural",  beli = 2300000,   robux = 2200 },
    { name = "Blizzard",  rarity = "Legendary", type = "Elemental", beli = 2400000,   robux = 2250 },

    -- ── Mythic ──────────────────────────────────────────────────────────
    { name = "Gravity",   rarity = "Mythic",    type = "Natural",  beli = 2500000,   robux = 2300 },
    { name = "Mammoth",   rarity = "Mythic",    type = "Beast",     beli = 2700000,   robux = 2350 },
    { name = "T-Rex",     rarity = "Mythic",    type = "Beast",     beli = 2700000,   robux = 2350 },
    { name = "Dough",     rarity = "Mythic",    type = "Elemental", beli = 2800000,   robux = 2400 },
    { name = "Shadow",    rarity = "Mythic",    type = "Natural",  beli = 2900000,   robux = 2425 },
    { name = "Venom",     rarity = "Mythic",    type = "Natural",  beli = 3000000,   robux = 2450 },
    { name = "Tiger",     rarity = "Mythic",    type = "Beast",     beli = 3000000,   robux = 2450,  aliases = { "Leopard" } },
    { name = "Yeti",      rarity = "Mythic",    type = "Beast",     beli = 2800000,   robux = 2400 },
    { name = "Gas",       rarity = "Mythic",    type = "Elemental", beli = 3200000,   robux = 2500 },
    { name = "Spirit",    rarity = "Mythic",    type = "Natural",  beli = 3400000,   robux = 2550 },
    { name = "Magnet",    rarity = "Mythic",    type = "Natural",  beli = 6000000,   robux = 3500 },
    { name = "Kitsune",   rarity = "Mythic",    type = "Beast",     beli = 8000000,   robux = 4000 },
    { name = "Control",   rarity = "Mythic",    type = "Natural",  beli = 9000000,   robux = 4000 },
    { name = "Dragon",    rarity = "Mythic",    type = "Beast",     beli = 15000000,  robux = 5000 },
}

--- name -> record
Fruits.ByName = {}
--- lowercased name/alias -> canonical name
Fruits.Aliases = {}
--- rarity -> array of records
Fruits.ByRarity = {}
--- type -> array of records
Fruits.ByType = {}

for _, rarity in ipairs(Fruits.Order) do
    Fruits.ByRarity[rarity] = {}
end

Fruits.ByType = {
    Natural = {},
    Elemental = {},
    Beast = {},
}

for _, record in ipairs(Fruits.List) do
    Fruits.ByName[record.name] = record
    Fruits.Aliases[record.name:lower()] = record.name

    table.insert(Fruits.ByRarity[record.rarity], record)
    if Fruits.ByType[record.type] then
        table.insert(Fruits.ByType[record.type], record)
    end

    for _, alias in ipairs(record.aliases or {}) do
        Fruits.Aliases[alias:lower()] = record.name
    end
end

--- Resolve any spelling of a fruit name to its canonical record.
--- Returns nil when the name is unknown.
function Fruits.Resolve(name)
    if type(name) ~= "string" then
        return nil
    end

    local canonical = Fruits.Aliases[name:lower()]
    if canonical then
        return Fruits.ByName[canonical]
    end

    -- substring match, longest canonical name wins
    local lowered = name:lower()
    local best, bestLength = nil, 0
    for canonicalName, record in pairs(Fruits.ByName) do
        local candidate = canonicalName:lower()
        if lowered:find(candidate, 1, true) and #candidate > bestLength then
            best, bestLength = record, #candidate
        end
    end

    return best
end

--- Rarity rank, 1 (Common) .. 5 (Mythic).
function Fruits.RarityRank(rarity)
    for index, name in ipairs(Fruits.Order) do
        if name == rarity then
            return index
        end
    end
    return 0
end

function Fruits.Count()
    return #Fruits.List
end

return Fruits
