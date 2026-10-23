--[[
    ui/tabs/world.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    The World page: the ESP layers, the entity counters and fast travel.
]]

local Tab = {}

function Tab.Create(window, suite)
    local tab = window:AddTab("World")
    local settings = suite:settings()
    local world = suite:Get("world")

    -- ── ESP ────────────────────────────────────────────────────────────
    local espSection = tab:AddSection("ESP layers")

    local espToggles = {}

    local function addEspToggle(label, path)
        local widget = espSection:AddToggle(label, false, function(state)
            settings:set(path, state)
        end)
        espToggles[path] = widget
        return widget
    end

    addEspToggle("Fruit", "world.fruitESP")
    addEspToggle("Mobs", "world.mobESP")
    addEspToggle("Bosses", "world.bossESP")
    addEspToggle("Chests", "world.chestESP")
    addEspToggle("NPCs", "world.npcESP")

    espSection:AddSlider("Max objects", 25, 500, 150, 25, "", function(value)
        settings:set("world.maxESP", value)
    end)

    -- ── counters ───────────────────────────────────────────────────────
    local counterSection = tab:AddSection("Entities in the world")

    local statFruit = counterSection:AddStat("Fruits", "0")
    local statMob = counterSection:AddStat("Mobs", "0")
    local statBoss = counterSection:AddStat("Bosses", "0")
    local statChest = counterSection:AddStat("Chests", "0")
    local statNpc = counterSection:AddStat("NPCs", "0")
    local statScan = counterSection:AddStat("Last scan", "-")

    -- ── fast travel ────────────────────────────────────────────────────
    local travelSection = tab:AddSection("Fast travel")

    local travelInput = travelSection:AddInput("Destination", "e.g. Blox Fruit Dealer", "", function(text)
        if text == "" then
            return
        end
        local ok = world:TravelTo(text)
        window:Notify("Travel", ok and ("Travelled to " .. text) or ("No NPC matching '" .. text .. "'"),
            ok and "success" or "error")
    end)

    travelSection:AddButton("Go to the fruit dealer", "primary", function()
        local ok = world:TravelTo("Blox Fruit Dealer")
        window:Notify("Travel", ok and "Travelled" or "No fruit dealer in range", ok and "success" or "error")
    end)

    travelSection:AddButton("Go to the gacha NPC", "primary", function()
        local ok = world:TravelTo("Gacha")
        window:Notify("Travel", ok and "Travelled" or "No gacha NPC in range", ok and "success" or "error")
    end)

    -- ── live updates ───────────────────────────────────────────────────
    window:AddRefresher(function()
        local stats = world:GetStats()
        statFruit:SetValue(stats.counts.fruit)
        statMob:SetValue(stats.counts.mob)
        statBoss:SetValue(stats.counts.boss)
        statChest:SetValue(stats.counts.chest)
        statNpc:SetValue(stats.counts.npc)
        statScan:SetValue(string.format("%.0f ms", (stats.scanDuration or 0) * 1000))
    end)

    -- sync the toggles with the stored settings
    for path, widget in pairs(espToggles) do
        widget:SetValue(settings:get(path, false), true)
    end

    return tab
end

return Tab
