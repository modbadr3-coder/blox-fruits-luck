--[[
    ui/tabs/about.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    The About page.

    It is worth being explicit here about what the suite can and cannot
    do, because the v11 build advertised capabilities it did not have.
]]

local Tab = {}

function Tab.Create(window, suite)
    local tab = window:AddTab("About")

    local infoSection = tab:AddSection("Build")

    infoSection:AddLabel("Version", "v12.0.0")
    infoSection:AddLabel("Engine", "Luau (Roblox client)")
    local moduleLabel = infoSection:AddLabel("Modules", "0")
    infoSection:AddLabel("Documentation", "README.md in the archive")

    local statModules = infoSection:AddStat("Loaded modules", "0")

    -- ── capabilities ───────────────────────────────────────────────────
    local realSection = tab:AddSection("What actually works")
    realSection:AddLabel("Fruit ESP", "yes - reads live world models")
    realSection:AddLabel("Mob / boss / chest ESP", "yes - reads live world models")
    realSection:AddLabel("Auto farm and auto collect", "yes - needs an executor with input events")
    realSection:AddLabel("Gacha result tracking", "yes - listens to the game's own events")
    realSection:AddLabel("Fruit spawn tracking", "yes - observes the world")

    -- ── limits ─────────────────────────────────────────────────────────
    local limitSection = tab:AddSection("What it cannot do")
    limitSection:AddLabel("Change the server's drop rates", "no - the server decides")
    limitSection:AddLabel("Guarantee a mythical fruit", "no - nothing client side can")
    limitSection:AddLabel("Read client id / hardware id", "no - not attempted on purpose")

    local noteSection = tab:AddSection("Note")
    local note = noteSection:AddLabel("Statement", "")
    note:SetValue("Fair use only. You are responsible for your account.")

    window:AddRefresher(function()
        statModules:SetValue(#suite:ModuleNames())
        moduleLabel:SetValue(tostring(#suite:ModuleNames()))
    end)

    return tab
end

return Tab
