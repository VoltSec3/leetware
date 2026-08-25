--[[
    leetware runtime guard
    -----------------------
    Installed by the loader before any game or module source is executed. It
    publishes a private runtime handle in _G.__leet_rt and a shared module
    table in _G.__leet_modules. Game and module scripts refuse to run unless
    this handle is present and verifies, so pasting a .luau file directly into
    an executor fails immediately instead of leaking source / functionality.

    This is obfuscation, not a root of trust: a determined client can read this
    file. It raises the effort required to reuse leetware code outside the
    loader to "really hard" without changing the product's threat model.
]]

local function leetToken()
    -- XOR-scrambled magic so the expected value is never a plaintext string.
    local seed = {
        0x6C, 0x65, 0x65, 0x74, 0x77, 0x61, 0x72, 0x65,
        0x2D, 0x72, 0x74, 0x2D, 0x76, 0x31,
    }
    local key = {
        0x1F, 0x3A, 0x9C, 0x55, 0x7B, 0x02, 0xC4, 0xED,
        0x36, 0x88, 0x4D, 0x0B, 0x91, 0x5E,
    }
    local out = {}

    for i = 1, #seed do
        out[i] = string.char(bit32.bxor(seed[i], key[((i - 1) % #key) + 1]))
    end

    return table.concat(out)
end

local Runtime = {}
Runtime._token = leetToken()

-- Called once by the loader. Publishes the runtime handle and resets the
-- shared module table. Re-installing is safe (e.g. hot reloads).
function Runtime.install()
    _G.__leet_rt = {
        active = true,
        verify = function()
            return Runtime._token
        end,
    }

    _G.__leet_modules = _G.__leet_modules or {}
    return Runtime
end

-- Verifies the current runtime is the loader. Game/module scripts call this
-- through the published handle; standalone execution has no handle.
function Runtime.verify()
    local rt = _G.__leet_rt
    if type(rt) ~= "table" or rt.active ~= true or type(rt.verify) ~= "function" then
        return false
    end

    local ok, provided = pcall(rt.verify)
    return ok and provided == Runtime._token
end

function Runtime.token()
    return Runtime._token
end

return Runtime
