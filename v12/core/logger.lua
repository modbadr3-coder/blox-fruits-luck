--[[
    core/logger.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Levelled logger with optional file sink.

    The v11 build silenced `print` wholesale at protection level >= 7, which
    also killed the script's own output. This logger never touches the global
    `print`; it only writes when a level is enabled.
]]

local Logger = {}

Logger.__index = Logger

Logger.LEVELS = {
    TRACE = 0,
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    NONE = 5,
}

-- Keyed by the level value, not by position. The levels start at 0 and
-- Lua tables are 1 based, so an array here would shift every name by one
-- and report a warning as an info.
local LEVEL_NAMES = {
    [Logger.LEVELS.TRACE] = "TRACE",
    [Logger.LEVELS.DEBUG] = "DEBUG",
    [Logger.LEVELS.INFO] = "INFO",
    [Logger.LEVELS.WARN] = "WARN",
    [Logger.LEVELS.ERROR] = "ERROR",
}

function Logger.new(config)
    config = config or {}

    local self = setmetatable({
        _level = config.level or Logger.LEVELS.INFO,
        _prefix = config.prefix or "[BFS]",
        _file = config.file or nil,
        _fileEnabled = config.fileEnabled or false,
        _history = {},
        _maxHistory = config.maxHistory or 200,
        _echo = config.echo ~= false,
    }, Logger)

    return self
end

function Logger:setLevel(level)
    if type(level) == "number" then
        self._level = level
    elseif type(level) == "string" then
        self._level = Logger.LEVELS[string.upper(level)] or self._level
    end
    return self._level
end

function Logger:getLevel()
    return self._level
end

function Logger:setPrefix(prefix)
    self._prefix = prefix or self._prefix
end

function Logger:enableFile(enabled, path)
    self._fileEnabled = enabled and true or false
    if path then
        self._file = path
    end
end

function Logger:_writeLine(line)
    self._history[#self._history + 1] = line
    if #self._history > self._maxHistory then
        table.remove(self._history, 1)
    end

    if self._fileEnabled and self._file then
        pcall(function()
            local handle = io.open(self._file, "a")
            if handle then
                handle:write(line .. "\n")
                handle:close()
            end
        end)
    end
end

function Logger:log(level, message, ...)
    if level < self._level then
        return
    end

    if type(message) == "string" and select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, message, ...)
        if ok then
            message = formatted
        end
    end

    message = tostring(message)
    local name = LEVEL_NAMES[level] or "INFO"
    local line = string.format("%s [%s] %s", self._prefix, name, message)

    if self._echo then
        pcall(print, line)
    end

    self:_writeLine(line)
end

function Logger:trace(message, ...)
    self:log(Logger.LEVELS.TRACE, message, ...)
end

function Logger:debug(message, ...)
    self:log(Logger.LEVELS.DEBUG, message, ...)
end

function Logger:info(message, ...)
    self:log(Logger.LEVELS.INFO, message, ...)
end

function Logger:warn(message, ...)
    self:log(Logger.LEVELS.WARN, message, ...)
end

function Logger:error(message, ...)
    self:log(Logger.LEVELS.ERROR, message, ...)
end

--- Recent log lines, newest last.
function Logger:history(limit)
    local out = {}
    local count = #self._history
    local from = math.max(1, count - (limit or 50) + 1)
    for i = from, count do
        out[#out + 1] = self._history[i]
    end
    return out
end

function Logger:clear()
    self._history = {}
end

return Logger
