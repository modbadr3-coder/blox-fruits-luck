--[[
    core/util.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Shared helper library. Pure functions only -- no state, no side effects
    beyond the ones explicitly documented.

    This module is intentionally dependency-free so it can be required from
    anywhere in the suite without ordering concerns.
]]

local Util = {}

-- ═══════════════════════════════════════════════════════════════════════
-- NUMBERS
-- ═══════════════════════════════════════════════════════════════════════

function Util.clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    elseif value > maximum then
        return maximum
    end
    return value
end

function Util.clamp01(value)
    return Util.clamp(value, 0, 1)
end

function Util.lerp(a, b, t)
    return a + (b - a) * Util.clamp01(t)
end

--- Round to a fixed number of decimals.
function Util.round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

function Util.roundTo(value, step)
    if not step or step == 0 then
        return value
    end
    return math.floor(value / step + 0.5) * step
end

function Util.sign(value)
    if value > 0 then
        return 1
    elseif value < 0 then
        return -1
    end
    return 0
end

-- ═══════════════════════════════════════════════════════════════════════
-- TABLES
-- ═══════════════════════════════════════════════════════════════════════

function Util.tableCount(tbl)
    local n = 0
    for _ in pairs(tbl) do
        n = n + 1
    end
    return n
end

function Util.tableKeys(tbl)
    local out = {}
    for key in pairs(tbl) do
        out[#out + 1] = key
    end
    return out
end

function Util.tableValues(tbl)
    local out = {}
    for _, value in pairs(tbl) do
        out[#out + 1] = value
    end
    return out
end

--- Shallow copy (array part included).
function Util.tableCopy(tbl)
    local out = {}
    for key, value in pairs(tbl) do
        out[key] = value
    end
    return out
end

function Util.deepCopy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end
    local out = {}
    for key, value in pairs(tbl) do
        out[key] = Util.deepCopy(value)
    end
    return out
end

function Util.tableMap(tbl, fn)
    local out = {}
    for i, value in ipairs(tbl) do
        out[i] = fn(value, i)
    end
    return out
end

function Util.tableFilter(tbl, predicate)
    local out = {}
    for i, value in ipairs(tbl) do
        if predicate(value, i) then
            out[#out + 1] = value
        end
    end
    return out
end

function Util.tableFind(tbl, predicate)
    for i, value in ipairs(tbl) do
        if predicate(value, i) then
            return value, i
        end
    end
    return nil
end

function Util.tableFindKey(tbl, value)
    for key, candidate in pairs(tbl) do
        if candidate == value then
            return key
        end
    end
    return nil
end

--- Recursively merge `source` into `target` (in place) and return target.
function Util.deepMerge(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            Util.deepMerge(target[key], value)
        else
            target[key] = value
        end
    end
    return target
end

--- Remove nil holes from an array and return the compacted copy.
function Util.compact(tbl)
    local out = {}
    for _, value in ipairs(tbl) do
        if value ~= nil then
            out[#out + 1] = value
        end
    end
    return out
end

function Util.slice(tbl, from, to)
    local out = {}
    for i = from, to do
        out[#out + 1] = tbl[i]
    end
    return out
end

function Util.reverse(tbl)
    local out = {}
    for i = #tbl, 1, -1 do
        out[#out + 1] = tbl[i]
    end
    return out
end

-- ═══════════════════════════════════════════════════════════════════════
-- STRINGS
-- ═══════════════════════════════════════════════════════════════════════

function Util.trim(str)
    if type(str) ~= "string" then
        return ""
    end
    return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

function Util.startsWith(str, prefix)
    return type(str) == "string" and str:sub(1, #prefix) == prefix
end

function Util.endsWith(str, suffix)
    if type(str) ~= "string" then
        return false
    end
    return suffix == "" or str:sub(-#suffix) == suffix
end

function Util.contains(str, needle, caseInsensitive)
    if type(str) ~= "string" then
        return false
    end
    if caseInsensitive then
        return str:lower():find(needle:lower()) ~= nil
    end
    return str:find(needle) ~= nil
end

function Util.titleCase(str)
    return (str:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

-- ═══════════════════════════════════════════════════════════════════════
-- PATHS  ("a.b.c" -> nested table access)
-- ═══════════════════════════════════════════════════════════════════════

function Util.pathGet(root, path)
    local node = root
    for segment in string.gmatch(path, "[^%.]+") do
        if type(node) ~= "table" then
            return nil
        end
        node = node[segment]
        if node == nil then
            return nil
        end
    end
    return node
end

function Util.pathSet(root, path, value)
    local segments = {}
    for segment in string.gmatch(path, "[^%.]+") do
        segments[#segments + 1] = segment
    end

    local node = root
    for i = 1, #segments - 1 do
        local segment = segments[i]
        if type(node[segment]) ~= "table" then
            node[segment] = {}
        end
        node = node[segment]
    end

    node[segments[#segments]] = value
    return value
end

-- ═══════════════════════════════════════════════════════════════════════
-- ROBLOX HELPERS
-- ═══════════════════════════════════════════════════════════════════════

--- True when `object` is a Roblox instance (and optionally of `className`).
function Util.isInstance(object, className)
    if type(object) ~= "table" then
        return false
    end
    local ok, isValid = pcall(function()
        return typeof(object) == "Instance"
    end)
    if not ok or not isValid then
        return false
    end
    if className then
        local okClass, matches = pcall(function()
            return object:IsA(className)
        end)
        return okClass and matches
    end
    return true
end

function Util.getClass(object)
    local ok, className = pcall(function()
        return typeof(object)
    end)
    if ok and className == "Instance" then
        local okName, name = pcall(function()
            return object.ClassName
        end)
        if okName then
            return name
        end
    end
    return type(object)
end

function Util.getName(object)
    local ok, name = pcall(function()
        return object.Name
    end)
    if ok and type(name) == "string" then
        return name
    end
    return nil
end

--- Distance between two BaseParts / Vector3 positions.
function Util.distance(a, b)
    local pa, pb
    if type(a) == "Vector3" then
        pa = a
    else
        local ok, pos = pcall(function()
            return a.Position
        end)
        if not ok then
            return math.huge
        end
        pa = pos
    end

    if type(b) == "Vector3" then
        pb = b
    else
        local ok, pos = pcall(function()
            return b.Position
        end)
        if not ok then
            return math.huge
        end
        pb = pos
    end

    return (pa - pb).Magnitude
end

function Util.distanceToPart(part, target)
    if not Util.isInstance(part) or not Util.isInstance(target) then
        return math.huge
    end
    return Util.distance(part.Position, target.Position)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SAFETY
-- ═══════════════════════════════════════════════════════════════════════

--- Call `fn` protected by pcall. Returns (ok, result...).
function Util.safeCall(fn, ...)
    if type(fn) ~= "function" then
        return false, "not a function"
    end
    local results = { pcall(fn, ...) }
    if not results[1] then
        return false, results[2]
    end
    return true, unpack(results, 2)
end

--- Call `fn` and swallow any error. Returns true on success.
function Util.try(fn, ...)
    local ok = pcall(fn, ...)
    return ok
end

-- ═══════════════════════════════════════════════════════════════════════
-- FORMATTING
-- ═══════════════════════════════════════════════════════════════════════

function Util.formatNumber(value)
    if type(value) ~= "number" then
        return "0"
    end
    local abs = math.abs(value)
    if abs >= 1e9 then
        return string.format("%.2fB", value / 1e9)
    elseif abs >= 1e6 then
        return string.format("%.2fM", value / 1e6)
    elseif abs >= 1e3 then
        return string.format("%.1fK", value / 1e3)
    elseif abs == math.floor(abs) then
        return string.format("%d", value)
    end
    return string.format("%.2f", value)
end

function Util.formatDuration(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%02dh %02dm %02ds", h, m, s)
    elseif m > 0 then
        return string.format("%02dm %02ds", m, s)
    end
    return string.format("%02ds", s)
end

function Util.formatClock(seconds)
    seconds = math.floor(seconds or 0)
    return string.format("%02d:%02d:%02d",
        math.floor(seconds / 3600) % 24,
        math.floor(seconds / 60) % 60,
        seconds % 60)
end

function Util.timestamp()
    return os.time()
end

-- ═══════════════════════════════════════════════════════════════════════
-- RANDOMNESS
-- ═══════════════════════════════════════════════════════════════════════

function Util.randomChoice(list)
    if type(list) ~= "table" or #list == 0 then
        return nil
    end
    return list[math.random(1, #list)]
end

--- Fisher-Yates in place.
function Util.shuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(1, i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

--- Pick one entry honouring a `weight` field (or a weight function).
function Util.pickWeighted(list, weightKey)
    local total = 0
    local weights = {}
    for i, entry in ipairs(list) do
        local w
        if type(weightKey) == "function" then
            w = weightKey(entry, i)
        else
            w = entry[weightKey or "weight"] or 1
        end
        w = tonumber(w) or 0
        weights[i] = w
        total = total + w
    end

    if total <= 0 then
        return list[math.random(1, #list)]
    end

    local roll = math.random() * total
    local running = 0
    for i = 1, #list do
        running = running + weights[i]
        if roll <= running then
            return list[i]
        end
    end
    return list[#list]
end

-- ═══════════════════════════════════════════════════════════════════════
-- COLOURS
-- ═══════════════════════════════════════════════════════════════════════

function Util.lerpColor(a, b, t)
    t = Util.clamp01(t)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

function Util.colorToHex(color)
    return string.format("%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255))
end

--- Approximate a colour's brightness -- used to pick readable text on top.
function Util.luminance(color)
    return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

-- ═══════════════════════════════════════════════════════════════════════
-- TWEENING
-- ═══════════════════════════════════════════════════════════════════════

--- Tween `instance` properties using TweenService.
-- Returns true when the tween was created.
function Util.tween(instance, properties, duration, style, direction)
    if not Util.isInstance(instance) then
        return false
    end

    local ok, TweenService = pcall(function()
        return game:GetService("TweenService")
    end)
    if not ok then
        return false
    end

    local okTween = pcall(function()
        local info = TweenInfo.new(
            duration or 0.25,
            style or Enum.EasingStyle.Quad,
            direction or Enum.EasingDirection.Out
        )
        TweenService:Create(instance, info, properties):Play()
    end)
    return okTween
end

-- ═══════════════════════════════════════════════════════════════════════
-- MISC
-- ═══════════════════════════════════════════════════════════════════════

--- Human readable byte size.
function Util.formatBytes(bytes)
    bytes = tonumber(bytes) or 0
    if bytes < 1024 then
        return string.format("%d B", bytes)
    end
    local units = { "KB", "MB", "GB", "TB" }
    local value = bytes / 1024
    local unit = 1
    while value >= 1024 and unit < #units do
        value = value / 1024
        unit = unit + 1
    end
    return string.format("%.1f %s", value, units[unit])
end

--- Split a string on a separator.
function Util.split(str, separator)
    local out = {}
    if type(str) ~= "string" then
        return out
    end
    separator = separator or ","
    local pattern = "([^" .. separator .. "]+)"
    for piece in str:gmatch(pattern) do
        out[#out + 1] = piece
    end
    return out
end

return Util
