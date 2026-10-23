--[[
    data/islands.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Island reference data.

    Hard coordinates are useless here: every server lays the islands out
    differently. The suite therefore locates islands by their NPCs and by
    the mob populations that live on them, and this table supplies the
    level brackets and names used to label what was found.
]]

local Islands = {}

-- name, sea, min level, max level
Islands.List = {
    { name = "Starter Island",  sea = "First Sea",  min = 1,    max = 10 },
    { name = "Jungle",          sea = "First Sea",  min = 10,   max = 30 },
    { name = "Pirate Village",  sea = "First Sea",  min = 30,   max = 60 },
    { name = "Desert",          sea = "First Sea",  min = 60,   max = 90 },
    { name = "Frozen Village",  sea = "First Sea",  min = 90,   max = 120 },
    { name = "Marine Fortress", sea = "First Sea",  min = 120,  max = 150 },
    { name = "Skypiea Island",  sea = "First Sea",  min = 150,  max = 190 },
    { name = "Prison",          sea = "First Sea",  min = 190,  max = 260 },
    { name = "Colosseum",       sea = "First Sea",  min = 260,  max = 320 },
    { name = "Mob Island",      sea = "First Sea",  min = 300,  max = 375 },
    { name = "Magma Village",   sea = "First Sea",  min = 375,  max = 460 },
    { name = "Underwater City", sea = "First Sea",  min = 460,  max = 560 },
    { name = "Fountain City",   sea = "First Sea",  min = 560,  max = 700 },

    { name = "Kingdom of Rose", sea = "Second Sea", min = 700,  max = 850 },
    { name = "Green Zone",      sea = "Second Sea", min = 850,  max = 950 },
    { name = "Graveyard",       sea = "Second Sea", min = 950,  max = 1000 },
    { name = "Snow Mountain",   sea = "Second Sea", min = 1000, max = 1100 },
    { name = "Hot and Cold",    sea = "Second Sea", min = 1100, max = 1250 },
    { name = "Cursed Ship",     sea = "Second Sea", min = 1250, max = 1350 },
    { name = "Ice Castle",      sea = "Second Sea", min = 1350, max = 1425 },
    { name = "Forgotten Island", sea = "Second Sea", min = 1425, max = 1500 },

    { name = "Port Town",       sea = "Third Sea",  min = 1500, max = 1575 },
    { name = "Hydra Island",    sea = "Third Sea",  min = 1575, max = 1700 },
    { name = "Great Tree",      sea = "Third Sea",  min = 1700, max = 1775 },
    { name = "Floating Turtle", sea = "Third Sea",  min = 1775, max = 1950 },
    { name = "Haunted Castle",  sea = "Third Sea",  min = 1950, max = 2075 },
    { name = "Sea of Treats",   sea = "Third Sea",  min = 2075, max = 2450 },
    { name = "Tiki Outpost",    sea = "Third Sea",  min = 2450, max = 2550 },
    { name = "Submerged Island", sea = "Third Sea", min = 2550, max = 2700 },
}

Islands.ByName = {}
for _, island in ipairs(Islands.List) do
    Islands.ByName[island.name:lower()] = island
end

--- Island that fits a level, or the closest one.
function Islands.ForLevel(level)
    local best, bestDiff = nil, math.huge
    for _, island in ipairs(Islands.List) do
        if level >= island.min and level <= island.max then
            return island
        end
        local diff = math.min(math.abs(level - island.min), math.abs(level - island.max))
        if diff < bestDiff then
            best, bestDiff = island, diff
        end
    end
    return best
end

--- Island that fits a level in a given sea.
function Islands.ForLevelInSea(level, sea)
    local best, bestDiff = nil, math.huge
    for _, island in ipairs(Islands.List) do
        if island.sea == sea then
            if level >= island.min and level <= island.max then
                return island
            end
            local diff = math.min(math.abs(level - island.min), math.abs(level - island.max))
            if diff < bestDiff then
                best, bestDiff = island, diff
            end
        end
    end
    return best
end

function Islands.SeaForLevel(level)
    if level < 700 then
        return "First Sea"
    elseif level < 1500 then
        return "Second Sea"
    end
    return "Third Sea"
end

return Islands
