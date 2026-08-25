local baseUrl = "https://raw.githubusercontent.com/VoltSec3/leetware/main/"
local subloaderUrl = baseUrl .. "Loader/Subloader.luau"

local function loadModule(path, name)
	local source = game:HttpGet(baseUrl .. path)
	local chunk, compileError = loadstring(source)

	assert(
		chunk,
		string.format("Failed to compile %s: %s", name, tostring(compileError))
	)

	return chunk()
end

-- Install the runtime guard before anything else. This publishes the loader
-- handle that every game and module script verifies before executing, so the
-- scripts cannot be run outside the loader.
local Guard = loadModule("Loader/Core/Guard.luau", "Guard")
Guard.install()

local Config = loadModule("Loader/Core/Config.luau", "Config")
local HWID = loadModule("Loader/Core/HWID.luau", "HWID")
local Auth = loadModule("Loader/Core/Auth.luau", "Auth")
local Heartbeat = loadModule("Loader/Core/Heartbeat.luau", "Heartbeat")
local UI = loadModule("Loader/UI/Login.luau", "UI")

local hwid = HWID.generate()
_G.__leet_hwid = hwid
local stopHeartbeat = nil

local function startHeartbeat()
	if stopHeartbeat then
		stopHeartbeat()
	end

	stopHeartbeat = Heartbeat.start(Auth, hwid, Config.HEARTBEAT_INTERVAL, function()
		warn("[leetware] Session invalidated. Reload the loader.")
	end)
end

local function runSubloader()
	local source = game:HttpGet(subloaderUrl)
	local chunk, compileError = loadstring(source)

	assert(
		chunk,
		string.format("Failed to compile subloader: %s", tostring(compileError))
	)

	return chunk()(Auth, hwid)
end

local function runLoader(setStatus, closeUi)
	setStatus("Validating session...", Color3.fromRGB(180, 180, 190))

	local valid = Auth.validate(hwid)
	if not valid then
		return false, "Session validation failed"
	end

	setStatus("Loading game module...", Color3.fromRGB(180, 180, 190))

	local ok, err = pcall(function()
		runSubloader()
	end)

	if not ok then
		return false, err
	end

	startHeartbeat()
	closeUi()
	return true
end

local function createLoaderUi()
	return UI.create(function(license, setStatus, closeUi)
		setStatus("Authenticating license...", Color3.fromRGB(180, 180, 190))

		local ok, result = Auth.authenticate(license, hwid)
		if not ok then
			local message = type(result) == "string"
				and result
				or (result and result.error)
				or "Authentication failed"

			return false, message
		end

		return runLoader(setStatus, closeUi)
	end)
end

task.defer(function()
	local savedLicense = Auth.loadLicense()
	local resumed = false

	if savedLicense then
		local authenticated = Auth.authenticate(savedLicense, hwid)

		if authenticated then
			local completed, loaded = pcall(function()
				return runLoader(function() end, function() end)
			end)

			resumed = completed and loaded == true
		end
	end

	if not resumed then
		createLoaderUi()
	end
end)
