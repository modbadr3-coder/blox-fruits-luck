--[[
    data/mobs.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Mob and boss reference data.

    Levels are the in-game "Lv." shown on the mob. The auto-farm module
    uses them to pick a target that is close to the player's own level, so a
    level that drifted with a game update only costs a slightly worse pick --
    the module re-reads the real level from the live model whenever one is
    available and prefers that over this table.
]]

local Mobs = {}

Mobs.Seas = { "First Sea", "Second Sea", "Third Sea" }

-- name, level, sea, island
Mobs.List = {
    -- ── First Sea ───────────────────────────────────────────────────────
    { name = "Bandit",              level = 5,    sea = "First Sea",  island = "Starter Island" },
    { name = "Monkey",              level = 14,   sea = "First Sea",  island = "Jungle" },
    { name = "Gorilla",             level = 20,   sea = "First Sea",  island = "Jungle" },
    { name = "Pirate",              level = 35,   sea = "First Sea",  island = "Pirate Village" },
    { name = "Brute",               level = 45,   sea = "First Sea",  island = "Pirate Village" },
    { name = "Desert Bandit",       level = 60,   sea = "First Sea",  island = "Desert" },
    { name = "Desert Officer",      level = 75,   sea = "First Sea",  island = "Desert" },
    { name = "Snow Bandit",         level = 90,   sea = "First Sea",  island = "Frozen Village" },
    { name = "Snowman",             level = 95,   sea = "First Sea",  island = "Frozen Village" },
    { name = "Marine",              level = 110,  sea = "First Sea",  island = "Marine Fortress" },
    { name = "Chief Petty Officer", level = 120,  sea = "First Sea",  island = "Marine Fortress" },
    { name = "Sky Bandit",          level = 150,  sea = "First Sea",  island = "Skypiea Island" },
    { name = "God's Guard",         level = 180,  sea = "First Sea",  island = "Skypiea Island" },
    { name = "Prisoner",            level = 225,  sea = "First Sea",  island = "Prison" },
    { name = "Chief Warden",        level = 250,  sea = "First Sea",  island = "Prison" },
    { name = "Gladiator",           level = 275,  sea = "First Sea",  island = "Colosseum" },
    { name = "Toga Warrior",        level = 300,  sea = "First Sea",  island = "Colosseum" },
    { name = "Military Soldier",    level = 400,  sea = "First Sea",  island = "Magma Village" },
    { name = "Military Spy",        level = 425,  sea = "First Sea",  island = "Magma Village" },
    { name = "Magma Ninja",         level = 450,  sea = "First Sea",  island = "Magma Village" },
    { name = "Fishman",             level = 525,  sea = "First Sea",  island = "Underwater City" },
    { name = "Galley Pirate",       level = 625,  sea = "First Sea",  island = "Fountain City" },

    -- ── Second Sea ──────────────────────────────────────────────────────
    { name = "Raider",              level = 700,  sea = "Second Sea", island = "Kingdom of Rose" },
    { name = "Mercenary",           level = 750,  sea = "Second Sea", island = "Kingdom of Rose" },
    { name = "Swan Pirate",         level = 775,  sea = "Second Sea", island = "Kingdom of Rose" },
    { name = "Factory Staff",       level = 800,  sea = "Second Sea", island = "Kingdom of Rose" },
    { name = "Marine Lieutenant",   level = 875,  sea = "Second Sea", island = "Green Zone" },
    { name = "Marine Captain",      level = 900,  sea = "Second Sea", island = "Green Zone" },
    { name = "Zombie",              level = 950,  sea = "Second Sea", island = "Graveyard" },
    { name = "Vampire",             level = 975,  sea = "Second Sea", island = "Graveyard" },
    { name = "Undead Pirate",       level = 1000, sea = "Second Sea", island = "Graveyard" },
    { name = "Snow Trooper",        level = 1000, sea = "Second Sea", island = "Snow Mountain" },
    { name = "Winter Warrior",      level = 1050, sea = "Second Sea", island = "Snow Mountain" },
    { name = "Lab Subordinate",     level = 1150, sea = "Second Sea", island = "Hot and Cold" },
    { name = "Horned Warrior",      level = 1175, sea = "Second Sea", island = "Hot and Cold" },
    { name = "Lava Pirate",         level = 1200, sea = "Second Sea", island = "Hot and Cold" },
    { name = "Ship Deckhand",       level = 1250, sea = "Second Sea", island = "Cursed Ship" },
    { name = "Ship Officer",        level = 1325, sea = "Second Sea", island = "Cursed Ship" },
    { name = "Sea Soldier",         level = 1400, sea = "Second Sea", island = "Forgotten Island" },
    { name = "Water Fighter",       level = 1425, sea = "Second Sea", island = "Forgotten Island" },

    -- ── Third Sea ───────────────────────────────────────────────────────
    { name = "Pirate Millionaire",  level = 1500, sea = "Third Sea",  island = "Port Town" },
    { name = "Pistol Billionaire",  level = 1525, sea = "Third Sea",  island = "Port Town" },
    { name = "Dragon Archer",       level = 1575, sea = "Third Sea",  island = "Hydra Island" },
    { name = "Dragon Warrior",      level = 1600, sea = "Third Sea",  island = "Hydra Island" },
    { name = "Marine Commodore",    level = 1700, sea = "Third Sea",  island = "Great Tree" },
    { name = "Marine Rear Admiral", level = 1725, sea = "Third Sea",  island = "Great Tree" },
    { name = "Fishman Raider",      level = 1775, sea = "Third Sea",  island = "Floating Turtle" },
    { name = "Fishman Captain",     level = 1800, sea = "Third Sea",  island = "Floating Turtle" },
    { name = "Forest Pirate",       level = 1825, sea = "Third Sea",  island = "Floating Turtle" },
    { name = "Mythological Pirate", level = 1850, sea = "Third Sea",  island = "Floating Turtle" },
    { name = "Jungle Pirate",       level = 1900, sea = "Third Sea",  island = "Floating Turtle" },
    { name = "Musketeer Pirate",     level = 1925, sea = "Third Sea", island = "Floating Turtle" },
    { name = "Reborn Skeleton",     level = 1950, sea = "Third Sea",  island = "Haunted Castle" },
    { name = "Demonic Soul",        level = 1975, sea = "Third Sea",  island = "Haunted Castle" },
    { name = "Cookie Crafter",      level = 2075, sea = "Third Sea",  island = "Sea of Treats" },
    { name = "Cake Guard",          level = 2125, sea = "Third Sea",  island = "Sea of Treats" },
    { name = "Sanguine Warrior",    level = 2500, sea = "Third Sea",  island = "Tiki Outpost" },
    { name = "Reef Bandit",         level = 2600, sea = "Third Sea",  island = "Submerged Island" },
    { name = "Coral Pirate",        level = 2625, sea = "Third Sea",  island = "Submerged Island" },
}

-- name, level, sea, island
Mobs.Bosses = {
    { name = "Gorilla King",     level = 25,   sea = "First Sea",  island = "Jungle" },
    { name = "Bobby",            level = 55,   sea = "First Sea",  island = "Pirate Village" },
    { name = "The Saw",          level = 100,  sea = "First Sea",  island = "Desert" },
    { name = "Yeti",             level = 120,  sea = "First Sea",  island = "Frozen Village" },
    { name = "Vice Admiral",     level = 150,  sea = "First Sea",  island = "Marine Fortress" },
    { name = "Chief Warden",     level = 200,  sea = "First Sea",  island = "Prison" },
    { name = "Sand",             level = 275,  sea = "First Sea",  island = "Desert" },
    { name = "Magma Admiral",    level = 450,  sea = "First Sea",  island = "Magma Village" },
    { name = "Wysper",           level = 500,  sea = "First Sea",  island = "Underwater City" },
    { name = "Thunder God",      level = 575,  sea = "First Sea",  island = "Fountain City" },
    { name = "Cyborg",           level = 600,  sea = "First Sea",  island = "Fountain City" },

    { name = "Diamond",          level = 750,  sea = "Second Sea", island = "Kingdom of Rose" },
    { name = "Jeremy",           level = 850,  sea = "Second Sea", island = "Kingdom of Rose" },
    { name = "Fajita",           level = 850,  sea = "Second Sea", island = "Green Zone" },
    { name = "Smoke Admiral",    level = 1200, sea = "Second Sea", island = "Hot and Cold" },
    { name = "Ice Admiral",      level = 1400, sea = "Second Sea", island = "Ice Castle" },
    { name = "Tide Keeper",      level = 1500, sea = "Second Sea", island = "Forgotten Island" },

    { name = "Stone",            level = 1550, sea = "Third Sea",  island = "Port Town" },
    { name = "Empress",          level = 1700, sea = "Third Sea",  island = "Hydra Island" },
    { name = "Kilo Admiral",     level = 1750, sea = "Third Sea",  island = "Great Tree" },
    { name = "Beautiful Pirate", level = 1950, sea = "Third Sea",  island = "Port Town" },
    { name = "Soul Reaper",      level = 2100, sea = "Third Sea",  island = "Haunted Castle" },
    { name = "Dough King",       level = 2300, sea = "Third Sea",  island = "Sea of Treats" },
    { name = "Tyrant of the Skies", level = 2450, sea = "Third Sea", island = "Sea of Treats" },
}

Mobs.ByName = {}
for _, mob in ipairs(Mobs.List) do
    Mobs.ByName[mob.name:lower()] = mob
end

Mobs.BossByName = {}
for _, boss in ipairs(Mobs.Bosses) do
    Mobs.BossByName[boss.name:lower()] = boss
end

--- Mobs that fit a level bracket. `maxDiff` limits how far above the
--- player a target may be.
function Mobs.ForLevel(level, maxDiff)
    maxDiff = maxDiff or 100
    local out = {}
    for _, mob in ipairs(Mobs.List) do
        if mob.level <= level + maxDiff then
            out[#out + 1] = mob
        end
    end
    table.sort(out, function(a, b)
        return a.level > b.level
    end)
    return out
end

--- Mobs belonging to a sea.
function Mobs.ForSea(sea)
    local out = {}
    for _, mob in ipairs(Mobs.List) do
        if mob.sea == sea then
            out[#out + 1] = mob
        end
    end
    return out
end

--- True when the name looks like a boss rather than a regular mob.
function Mobs.IsBossName(name)
    if type(name) ~= "string" then
        return false
    end
    return Mobs.BossByName[name:lower()] ~= nil
end

return Mobs
