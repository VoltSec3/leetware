local baseUrl = "https://raw.githubusercontent.com/VoltSec3/leetware/main/"

local function loadModule(path, name)
    local source = game:HttpGet(baseUrl .. path)
    local chunk, compileError = loadstring(source)

    assert(
        chunk,
        string.format("Failed to compile %s: %s", name, tostring(compileError))
    )

    return chunk()
end

local function run(auth, hwid)
    local Dispatcher = loadModule("Loader/Core/Dispatcher.luau", "Dispatcher")
    local module, entry = Dispatcher.load(auth, hwid)

    warn(string.format(
        "[leetware] Loading %s for PlaceId %s",
        entry and entry.name or "universal boilerplate",
        tostring(game.PlaceId)
    ))

    return module, entry
end

return run
