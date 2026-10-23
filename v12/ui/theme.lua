--[[
    ui/theme.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Theme definitions.

    A theme is a flat table of colours. The window reads the active theme
    from here and every widget pulls its colours from `window.Theme`, so
    switching themes restyles the whole interface without any widget
    needing to know about it.
]]

local Theme = {}

--- Accent colours the user can pick from.
Theme.ACCENTS = {
    { name = "Cyan",   value = Color3.fromRGB(0, 170, 255) },
    { name = "Blue",   value = Color3.fromRGB(60, 120, 255) },
    { name = "Purple", value = Color3.fromRGB(150, 80, 240) },
    { name = "Pink",   value = Color3.fromRGB(240, 80, 170) },
    { name = "Green",  value = Color3.fromRGB(40, 200, 110) },
    { name = "Yellow", value = Color3.fromRGB(240, 190, 50) },
    { name = "Orange", value = Color3.fromRGB(240, 130, 40) },
    { name = "Red",    value = Color3.fromRGB(230, 60, 70) },
}

Theme.ACCENT_NAMES = {}
for _, accent in ipairs(Theme.ACCENTS) do
    table.insert(Theme.ACCENT_NAMES, accent.name)
end

function Theme.AccentColor(name)
    for _, accent in ipairs(Theme.ACCENTS) do
        if accent.name:lower() == tostring(name):lower() then
            return accent.value
        end
    end
    return Theme.ACCENTS[1].value
end

--- Built in themes. `accent` is filled in from the user's choice.
Theme.THEMES = {
    midnight = {
        name = "Midnight",
        background = Color3.fromRGB(10, 11, 16),
        surface = Color3.fromRGB(20, 22, 30),
        surfaceAlt = Color3.fromRGB(28, 30, 40),
        border = Color3.fromRGB(44, 47, 60),
        text = Color3.fromRGB(238, 240, 248),
        textDim = Color3.fromRGB(140, 146, 165),
        success = Color3.fromRGB(40, 200, 110),
        danger = Color3.fromRGB(230, 60, 70),
        warning = Color3.fromRGB(240, 180, 50),
        shadow = Color3.fromRGB(0, 0, 0),
    },
    carbon = {
        name = "Carbon",
        background = Color3.fromRGB(16, 16, 16),
        surface = Color3.fromRGB(28, 28, 28),
        surfaceAlt = Color3.fromRGB(38, 38, 38),
        border = Color3.fromRGB(56, 56, 56),
        text = Color3.fromRGB(240, 240, 240),
        textDim = Color3.fromRGB(150, 150, 150),
        success = Color3.fromRGB(60, 200, 120),
        danger = Color3.fromRGB(240, 70, 70),
        warning = Color3.fromRGB(240, 190, 60),
        shadow = Color3.fromRGB(0, 0, 0),
    },
    ocean = {
        name = "Ocean",
        background = Color3.fromRGB(8, 20, 32),
        surface = Color3.fromRGB(14, 34, 52),
        surfaceAlt = Color3.fromRGB(20, 44, 66),
        border = Color3.fromRGB(30, 62, 90),
        text = Color3.fromRGB(232, 244, 252),
        textDim = Color3.fromRGB(130, 165, 190),
        success = Color3.fromRGB(50, 200, 160),
        danger = Color3.fromRGB(240, 90, 90),
        warning = Color3.fromRGB(240, 200, 80),
        shadow = Color3.fromRGB(0, 0, 0),
    },
    daylight = {
        name = "Daylight",
        background = Color3.fromRGB(238, 240, 245),
        surface = Color3.fromRGB(255, 255, 255),
        surfaceAlt = Color3.fromRGB(226, 230, 238),
        border = Color3.fromRGB(198, 204, 215),
        text = Color3.fromRGB(26, 30, 40),
        textDim = Color3.fromRGB(110, 118, 135),
        success = Color3.fromRGB(30, 160, 90),
        danger = Color3.fromRGB(210, 50, 60),
        warning = Color3.fromRGB(220, 160, 30),
        shadow = Color3.fromRGB(120, 126, 140),
    },
    ember = {
        name = "Ember",
        background = Color3.fromRGB(22, 12, 12),
        surface = Color3.fromRGB(36, 20, 18),
        surfaceAlt = Color3.fromRGB(48, 27, 24),
        border = Color3.fromRGB(70, 40, 34),
        text = Color3.fromRGB(248, 236, 230),
        textDim = Color3.fromRGB(168, 140, 130),
        success = Color3.fromRGB(210, 160, 60),
        danger = Color3.fromRGB(230, 70, 60),
        warning = Color3.fromRGB(240, 150, 50),
        shadow = Color3.fromRGB(0, 0, 0),
    },
}

Theme.NAMES = {}
for key, _ in pairs(Theme.THEMES) do
    table.insert(Theme.NAMES, key)
end
table.sort(Theme.NAMES)

--- Build the live theme table.
--- `themeName` is a key of Theme.THEMES, `accentName` a name of Theme.ACCENTS.
function Theme.Build(themeName, accentName)
    local base = Theme.THEMES[themeName] or Theme.THEMES.midnight

    local built = {}
    for key, value in pairs(base) do
        built[key] = value
    end

    built.accent = Theme.AccentColor(accentName)
    built.accentSoft = built.accent:Lerp(built.background, 0.55)
    built.key = themeName or "midnight"

    return built
end

return Theme
