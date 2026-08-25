local RUNTIME_SECRET = "d29e104fa9474fb4a7dfbb39200dbbf6ece106c0b37e04b1"

local TWO32 = 4294967296

local function bxor(a, b)
  local result = 0
  local bit = 1

  for _ = 1, 32 do
    local abit = a % 2
    local bbit = b % 2

    if abit ~= bbit then
      result = result + bit
    end

    a = math.floor(a / 2)
    b = math.floor(b / 2)
    bit = bit * 2
  end

  return result
end

local function mul32(a, b)
  local a0 = a % 65536
  local a1 = math.floor(a / 65536)
  local b0 = b % 65536
  local b1 = math.floor(b / 65536)
  local p0 = a0 * b0
  local p1 = a0 * b1 + a1 * b0

  return (p0 + p1 * 65536) % TWO32
end

local function fnv1a(str)
  local h = 0x811c9dc5

  for i = 1, #str do
    h = bxor(h, string.byte(str, i))
    h = mul32(h, 0x01000193)
    h = h % TWO32
  end

  return h
end

local function deriveRuntimeToken(key)
  local session = _G.__leet_session_token or ""
  local hwid = _G.__leet_hwid or ""
  local basis = RUNTIME_SECRET .. "|" .. key .. "|" .. session .. "|" .. hwid
  local state = fnv1a(basis)
  local out = {}

  for i = 1, 8 do
    state = (mul32(state, 1103515245) + 12345) % TWO32
    out[i] = string.format("%02x", state % 256)
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
