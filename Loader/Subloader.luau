local baseUrl = "https://raw.githubusercontent.com/VoltSec3/leetware/main/"
local registryUrl = baseUrl .. "Loader/Games/registry.luau"
local fallbackUrl = baseUrl .. "Boilerplate.luau"

local function fetchSource(url, label)
    local source = game:HttpGet(url)
    local chunk, compileError = loadstring(source)

    assert(
        chunk,
        string.format("Failed to compile %s: %s", label, tostring(compileError))
    )

    return chunk
end

local registry = fetchSource(registryUrl, "game registry")()
local gameId = tostring(game.PlaceId)
local entry = registry[gameId]
local scriptUrl = entry and entry.scriptUrl or fallbackUrl
local scriptName = entry and entry.name or "universal boilerplate"

warn(string.format("[leetware] Loading %s for PlaceId %s", scriptName, gameId))

return fetchSource(scriptUrl, scriptName)(), entry
