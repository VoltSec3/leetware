local Config = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/VoltSec3/leetware/main/Loader/Core/Config.luau"
))()

local Registry = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/VoltSec3/leetware/main/Loader/Games/registry.luau"
))()

local Dispatcher = {}
Dispatcher._catalog = nil
Dispatcher._catalogFetched = false

function Dispatcher.getGameId()
	return tostring(game.PlaceId)
end

-- Fetch the server-side game catalog once per session. Entries registered in
-- the dashboard (or auto-registered by other users) become available here
-- without shipping a loader update.
function Dispatcher.fetchCatalog(auth)
	if Dispatcher._catalogFetched then
		return Dispatcher._catalog
	end

	Dispatcher._catalogFetched = true

	if not auth or not auth.get then
		return nil
	end

	local ok, data = auth.get("/games")

	if not ok or type(data) ~= "table" or type(data.games) ~= "table" then
		return nil
	end

	local catalog = {}

	for _, entry in ipairs(data.games) do
		if entry.gameId ~= nil then
			catalog[tostring(entry.gameId)] = {
				name = entry.name,
				moduleKey = entry.moduleKey,
				delivery = entry.delivery,
				scriptUrl = entry.scriptUrl,
			}
		end
	end

	Dispatcher._catalog = catalog

	return catalog
end

function Dispatcher.resolve(gameId, auth)
	gameId = gameId or Dispatcher.getGameId()

	print("[leetware] GameId:", gameId)
	print("[leetware] Registry entry:", Registry[gameId])

	local entry = Registry[gameId]

	if entry then
		print("[leetware] Built-in registry matched:", entry.name)
		return entry
	end

	print("[leetware] Built-in registry did not match, checking API catalog")

	local catalog = Dispatcher.fetchCatalog(auth)

	if catalog then
		print("[leetware] API catalog entry:", catalog[gameId])
		return catalog[gameId]
	end

	print("[leetware] No catalog available")

	return nil
end

local function compileSource(source, label)
	local chunk, err = loadstring(source)

	if not chunk then
		error("Failed to compile " .. label .. ": " .. tostring(err))
	end

	return chunk()
end

function Dispatcher.load(auth, hwid)
	local gameId = Dispatcher.getGameId()
	local entry = Dispatcher.resolve(gameId, auth)

	if entry then
		local source

		if entry.delivery == "api" then
			-- Gated delivery: server checks session + license + HWID and
			-- returns the module source stored in the dashboard.
			local ok, result = auth.payload(entry.moduleKey, hwid)

			if not ok then
				error("Payload denied for " .. tostring(entry.name) .. ": " .. tostring(result))
			end

			source = result
		elseif entry.scriptUrl then
			source = game:HttpGet(entry.scriptUrl)
		end

		if source then
			return compileSource(source, tostring(entry.name)), entry
		end

		-- Entry existed but had no usable source; fall through to boilerplate.
		warn("[leetware] No usable source for " .. tostring(entry.name) .. ", using boilerplate")
	end

	local source = game:HttpGet(Config.BOILERPLATE_URL)

	return compileSource(source, "boilerplate"), {
		name = "Universal Boilerplate",
		moduleKey = "boilerplate",
		gameId = gameId,
	}
end

return Dispatcher
