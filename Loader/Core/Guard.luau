-- Installs the leetware runtime context that guarded scripts verify against.
--
-- The runtime token is derived per (module key, session, HWID) from a
-- loader-held secret. The server wraps every delivered payload with the SAME
-- token at delivery time, bound to the caller's session + HWID. A delivered
-- script is therefore useless to anyone without that exact session/HWID and
-- expires when the session does. The shared secret lives only in the loader
-- and the server, never inside delivered payloads.

local RUNTIME_SECRET = "d29e104fa9474fb4a7dfbb39200dbbf6ece106c0b37e04b1"

local function fnv1a(str)
  local h = 0x811c9dc5

  for i = 1, #str do
    h = bit32.band(bit32.bxor(h, string.byte(str, i)), 0xFFFFFFFF)
    h = bit32.band(bit32.mul(h, 0x01000193), 0xFFFFFFFF)
  end

  return h
end

-- Must match src/lib/runtime-guard.ts:deriveRuntimeTokenForSession exactly.
local function deriveRuntimeToken(key)
  local session = _G.__leet_session_token or ""
  local hwid = _G.__leet_hwid or ""
  local basis = RUNTIME_SECRET .. "|" .. key .. "|" .. session .. "|" .. hwid
  local state = fnv1a(basis)
  local out = {}

  for i = 1, 8 do
    state = bit32.band((bit32.mul(state, 1103515245) + 12345) % 4294967296, 0xFFFFFFFF)
    out[i] = string.format("%02x", bit32.band(state, 0xFF))
  end

  return table.concat(out)
end

local function removeBlock(src, startPlain, endPlain)
  local startPos, _ = string.find(src, startPlain, 1, true)

  while startPos do
    local _, endPos = string.find(src, endPlain, startPos, true)

    if not endPos then
      break
    end

    local after = endPos + 1

    if string.sub(src, after, after) == "\n" then
      after = after + 1
    end

    src = string.sub(src, 1, startPos - 1) .. string.sub(src, after)
    startPos, _ = string.find(src, startPlain, 1, true)
  end

  return src
end

-- Strips any previously injected guard block (old --[[ ... ]] or new -- ... form)
-- so a fresh per-session guard can be prepended.
local function stripGuard(src)
  local out = removeBlock(src, "-- leetware runtime guard", "-- leetware runtime guard end")
  out = removeBlock(out, "--[[ leetware runtime guard", "--[[ end leetware runtime guard ]]")

  return out:gsub("^\n+", "")
end

local function buildGuard(key, token)
  return table.concat({
    "-- leetware runtime guard: do not remove. this file only executes inside the official loader.",
    "do",
    "  local function __leet_expected()",
    '    return "' .. token .. '"',
    "  end",
    "  local function __leet_key()",
    '    return "' .. key .. '"',
    "  end",
    "  local rt = _G.__leet_rt",
    '  if type(rt) ~= "table" or rt.active ~= true or type(rt.verify) ~= "function" then',
    '    error("leetware: this script must be executed through the leetware loader.", 0)',
    "  end",
    "  local ok, provided = pcall(rt.verify, __leet_key())",
    '  if not ok or provided ~= __leet_expected() then',
    '    error("leetware: runtime verification failed.", 0)',
    "  end",
    "end",
    "-- leetware runtime guard end",
    "",
  }, "\n")
end

-- Wrap a loaded script with a per-session, per-HWID runtime guard. The server
-- delivers scripts already wrapped; wrapping here is idempotent and also covers
-- the raw fallback path (boilerplate) where the server did not wrap.
local function wrap(key, source)
  local token = deriveRuntimeToken(key)

  return buildGuard(key, token) .. "\n" .. stripGuard(source)
end

local function installRuntime()
  _G.__leet_rt = {
    active = true,
    verify = function(key)
      return deriveRuntimeToken(key)
    end,
  }

  if not _G.__leet_modules then
    _G.__leet_modules = {}
  end
end

return {
  install = installRuntime,
  wrap = wrap,
}
