--[[
    loader.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Executor bootstrap.

    Paste this into your executor and run it. It downloads the suite from
    the publish URL and starts it. Nothing else is needed.

    To run a local copy instead, set the global before loading:

        BFS_SOURCE_URL = "https://raw.githubusercontent.com/<you>/<repo>/main/v12"
        loadstring(readfile("src/main.lua"))()
]]

local SOURCE_URL = _G.BFS_SOURCE_URL
    or "https://raw.githubusercontent.com/modbadr3-coder/blox-fruits-luck/main/v12"

print("[BFS] loading from " .. SOURCE_URL)

local ok, err = pcall(function()
    local loader = loadstring or load
    local source = game:HttpGet(SOURCE_URL .. "/src/main.lua", true)
    if not source or source == "" then
        error("the server returned an empty file")
    end
    local chunk = loader(source)
    if not chunk then
        error("the downloaded file is not valid Lua")
    end
    chunk()
end)

if not ok then
    print("[BFS] failed to load: " .. tostring(err))
    print("[BFS] check the URL, or use the single file build instead")
end
