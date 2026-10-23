--[[
    data/chests.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Chest reference data.

    Blox Fruits spawns chests in the world; digging them yields Beli, XP and
    occasionally a fruit. The chest tracker uses these tiers to colour the
    ESP overlay and to decide which chests are worth walking to.
]]

local Chests = {}

-- name, tier, weight of the reward pool, rarity colour
Chests.List = {
    { name = "Chest",            tier = 1, reward = "Beli + XP" },
    { name = "Rare Chest",       tier = 2, reward = "Beli + XP + rare loot" },
    { name = "Legendary Chest",  tier = 3, reward = "Beli + XP + fruit chance" },
    { name = "Super Rare Chest", tier = 4, reward = "High tier loot" },
}

Chests.ByName = {}
for _, chest in ipairs(Chests.List) do
    Chests.ByName[chest.name:lower()] = chest
end

--- Substrings used to spot a chest model.
Chests.Signatures = { "Chest", "Treasure" }

--- True when the model name looks like a chest.
function Chests.IsChest(modelName)
    if type(modelName) ~= "string" then
        return false
    end
    local lowered = modelName:lower()
    for _, signature in ipairs(Chests.Signatures) do
        if lowered:find(signature:lower(), 1, true) then
            return true
        end
    end
    return false
end

--- Tier of a chest model name (1 = plain chest).
function Chests.TierOf(modelName)
    if type(modelName) ~= "string" then
        return 0
    end
    local record = Chests.ByName[modelName:lower()]
    if record then
        return record.tier
    end
    if Chests.IsChest(modelName) then
        return 1
    end
    return 0
end

return Chests
