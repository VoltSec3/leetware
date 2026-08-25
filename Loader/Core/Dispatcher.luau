local baseUrl = "https://raw.githubusercontent.com/VoltSec3/leetware/main/"

local Config = loadstring(game:HttpGet(
	baseUrl .. "Loader/Core/Config.luau"
))()

local Registry = loadstring(game:HttpGet(
	baseUrl .. "Loader/Games/registry.luau"
))()

local Guard = loadstring(game:HttpGet(baseUrl .. "Loader/Core/Guard.luau"))()

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

	local catalog = Dispatcher.fetchCatalog(auth)

	if catalog then
		print("[leetware] API catalog entry:", catalog[gameId])
		if catalog[gameId] then
			return catalog[gameId]
		end
	end

	local entry = Registry[gameId]

	if entry then
		print("[leetware] Using built-in registry fallback:", entry.name)
		return entry
	end

	print("[leetware] No catalog or registry entry available")

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
	-- Always pull the shared, API-delivered modules first so the resolved
	-- game script can consume them from _G.__leet_modules.
	Dispatcher.loadModules(auth, hwid)

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
			return compileSource(Guard.wrap(entry.moduleKey, source), tostring(entry.name)), entry
		end

		-- Entry existed but had no usable source; fall through to boilerplate.
		warn("[leetware] No usable source for " .. tostring(entry.name) .. ", using boilerplate")
	end

	-- Boilerplate is API-delivered (gated). Only fall back to the raw file if
	-- the authenticated fetch fails (e.g. the API is unreachable).
	local source = Dispatcher.fetchBoilerplate(auth, hwid)

	return compileSource(Guard.wrap("boilerplate", source), "boilerplate"), {
		name = "Universal Boilerplate",
		moduleKey = "boilerplate",
		gameId = gameId,
	}
end

-- Pulls the enabled module catalog and fetches each module's source through
-- the authenticated payload endpoint, exposing the loaded modules on
-- _G.__leet_modules keyed by moduleKey.
function Dispatcher.loadModules(auth, hwid)
	local modules = _G.__leet_modules or {}
	_G.__leet_modules = modules

	local list = {}

	local ok, data = auth.get("/modules")

	if ok and data and type(data.modules) == "table" then
		list = data.modules
	end

	for _, entry in ipairs(list) do
		local key = entry.moduleKey

		if key and not modules[key] then
			local pOk, source = auth.payload(key, hwid)

		if pOk and type(source) == "string" and #source > 0 then
			local okRun, result = pcall(compileSource, Guard.wrap(key, source), "module:" .. tostring(key))

				if okRun and result then
					modules[key] = result
					print("[leetware] Loaded module:", key)
				else
					warn("[leetware] Failed to load module " .. tostring(key) .. ": " .. tostring(result))
				end
			end
		end
	end

	return modules
end

-- Boilerplate is served via the gated payload endpoint. Falls back to the raw
-- repository copy only when the authenticated fetch fails.
function Dispatcher.fetchBoilerplate(auth, hwid)
	local ok, source = pcall(function()
		return auth.payload("boilerplate", hwid)
	end)

	if ok and type(source) == "string" and #source > 0 then
		return source
	end

	return game:HttpGet(Config.BOILERPLATE_URL)
end

return Dispatcher
