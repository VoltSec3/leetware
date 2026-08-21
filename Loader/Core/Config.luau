return {
	API_BASE = "https://api.leet.voltsec.xyz/api",
	CLIENT_VERSION = "1.0.0",
	HEARTBEAT_INTERVAL = 60,
	SESSION_FILE = "leetware/session.json",
	LICENSE_FILE = "leetware/license.txt",

	-- Fallback module when the current game has no registered entry.
	BOILERPLATE_URL = "https://raw.githubusercontent.com/VoltSec3/leetware/main/Boilerplate.luau",

	-- Report GameId/game name during auth so the API auto-registers new games.
	REPORT_GAME_CONTEXT = true,
}
