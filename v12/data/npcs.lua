--[[
    data/npcs.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    NPC reference data.

    The world module locates NPCs by scanning the live workspace, so this
    table is used for two things:
        1. deciding which NPC is worth showing in the ESP list
        2. giving the fast-travel module a human readable label
]]

local NPCs = {}

-- role, display name, island, sea
NPCs.List = {
    { role = "fruit_dealer",  name = "Blox Fruit Dealer",  island = "Multiple",     sea = "First Sea" },
    { role = "gacha",         name = "Blox Fruit Gacha",   island = "Multiple",     sea = "First Sea" },
    { role = "weapon_dealer", name = "Weapon Dealer",      island = "Multiple",     sea = "First Sea" },
    { role = "sword_dealer",  name = "Sword Dealer",       island = "Multiple",     sea = "First Sea" },
    { role = "black_market",  name = "Black Market",       island = "Multiple",     sea = "First Sea" },
    { role = "boat_dealer",   name = "Boat Dealer",        island = "Multiple",     sea = "First Sea" },
    { role = "luxury_boat",   name = "Luxury Boat Dealer", island = "Multiple",     sea = "First Sea" },
    { role = "quest",         name = "Quest Giver",        island = "Multiple",     sea = "First Sea" },
    { role = "seed",          name = "Seed Dealer",        island = "Multiple",     sea = "Second Sea" },
    { role = "prime",         name = "Prime Shop",         island = "Multiple",     sea = "Second Sea" },
    { role = "flame",         name = "Flame Hunter",       island = "Green Zone",   sea = "Second Sea" },
    { role = "quest",         name = "Bandit Quest Giver", island = "Starter Island", sea = "First Sea" },
    { role = "quest",         name = "Marine Leader",      island = "Starter Island", sea = "First Sea" },
    { role = "quest",         name = "Monkey Quest Giver", island = "Jungle",       sea = "First Sea" },
    { role = "quest",         name = "Gorilla Quest Giver", island = "Jungle",      sea = "First Sea" },
    { role = "quest",         name = "Pirate Recruiter",   island = "Pirate Village", sea = "First Sea" },
    { role = "quest",         name = "Desert Bandit Quest Giver", island = "Desert", sea = "First Sea" },
    { role = "quest",         name = "Marine Quest Giver", island = "Marine Fortress", sea = "First Sea" },
    { role = "quest",         name = "Sky Quest Giver",    island = "Skypiea Island", sea = "First Sea" },
    { role = "quest",         name = "Prison Quest Giver", island = "Prison",       sea = "First Sea" },
    { role = "quest",         name = "Colosseum Quest Giver", island = "Colosseum", sea = "First Sea" },
    { role = "quest",         name = "Military Quest Giver", island = "Magma Village", sea = "First Sea" },
    { role = "quest",         name = "Pirate Port Quest Giver", island = "Port Town", sea = "Third Sea" },
    { role = "quest",         name = "Marine Tree Quest Giver", island = "Great Tree", sea = "Third Sea" },
}

--- Substrings that identify an NPC model in the workspace.
NPCs.Signatures = {
    fruit_dealer  = { "Blox Fruit Dealer", "FruitDealer", "Fruit Dealer" },
    gacha         = { "Gacha", "Fruit Gacha" },
    weapon_dealer = { "Weapon Dealer", "Weapons" },
    sword_dealer  = { "Sword", "SwordMaster" },
    black_market  = { "Black Market", "BlackMarket" },
    boat_dealer   = { "Boat", "Shipwright" },
    luxury_boat   = { "Luxury" },
    seed          = { "Seed" },
    prime         = { "Prime" },
    flame         = { "Flame Hunter", "FlameHunter" },
    quest         = { "Quest Giver", "QuestGiver", "Recruiter", "Leader", "Quest" },
}

--- Guess an NPC role from a model name.
function NPCs.RoleFromName(modelName)
    if type(modelName) ~= "string" then
        return nil
    end
    local lowered = modelName:lower()

    for role, signatures in pairs(NPCs.Signatures) do
        for _, signature in ipairs(signatures) do
            if lowered:find(signature:lower(), 1, true) then
                return role
            end
        end
    end
    return nil
end

--- True when the name looks like a quest giver.
function NPCs.IsQuestGiver(modelName)
    return NPCs.RoleFromName(modelName) == "quest"
end

function NPCs.QuestGivers()
    local out = {}
    for _, npc in ipairs(NPCs.List) do
        if npc.role == "quest" then
            out[#out + 1] = npc
        end
    end
    return out
end

return NPCs
