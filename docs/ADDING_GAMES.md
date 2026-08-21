# Adding new games to leetware

This guide covers every way to add a game, from zero-effort autonomous support to fully gated private payloads.

**TL;DR:** You do **not** need to seed anything. The loader already loads the right script for the game you are in. New games self-register in the API the first time any user runs the loader inside them. Your only real job is deciding *where the module code comes from*.

---

## How dispatch works

```
main.luau
  └─ Dispatcher.getGameId()          → tostring(game.GameId)
       └─ Dispatcher.resolve()
            ├─ 1. Loader/Games/registry.luau   (built-in, ships with loader)
            └─ 2. GET /api/games               (live server catalog, cached per session)
                 └─ 3. nothing found → Boilerplate.luau (universal fallback)
```

Resolution order matters: a built-in registry entry always wins over the server catalog, so you can hotfix behavior without touching the database.

At the same time, every auth call (`activate`, `session`, `validate`, `heartbeat`) sends `gameId` + `gameName`. The API upserts this into its `SupportedGame` table (`src/lib/game-service.ts`), so the dashboard always shows which games people actually use — automatically.

---

## Path A — Zero-touch (autonomous)

Do nothing. Concretely:

1. User runs the loader inside *Some Game* (`game.GameId = 987654321`).
2. No registry/catalog entry exists → **Boilerplate.luau loads** (universal features).
3. The API auto-registers `987654321` as `Game 987654321`, flagged `auto`.
4. It appears in **Dashboard → Games**, where you can rename it and pick a delivery mode later.

Use this when: you just want the loader to work everywhere and decide later.

---

## Path B — Direct module (public script URL)

The module source is fetched from a public URL (e.g. raw GitHub) and compiled with `loadstring`.

### Step 1 — Write the module

Create `Games/<GameName>/<GameName>.luau` in the repo. The file is executed as a chunk, not required — it runs top-level code immediately:

```lua
-- Games/DaHood/DaHood.luau
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local connection = RunService.RenderStepped:Connect(function()
    -- your features here
end)

-- Optional: stop cleanly if the loader unloads you
game:GetService("Workspace").ChildRemoved:Connect(function(child)
    if child == localPlayer.Character then
        connection:Disconnect()
    end
end)
```

Conventions used by existing modules (`Games/PrisonLife/PrisonLife.luau`):

- Self-contained; no `require` of other repo files.
- Guard against re-execution if needed (loader may be re-run without rejoin).
- Clean up connections on character removal / respawn.

### Step 2a — Register in the loader registry (ships with loader)

Edit `Loader/Games/registry.luau`:

```lua
return {
	["155615604"] = {
		name = "Prison Life",
		moduleKey = "prison-life",
		scriptUrl = "https://raw.githubusercontent.com/VoltSec3/leetware/main/Games/PrisonLife/PrisonLife.luau",
	},
	["987654321"] = {
		name = "Da Hood",
		moduleKey = "da-hood",
		scriptUrl = "https://raw.githubusercontent.com/VoltSec3/leetware/main/Games/DaHood/DaHood.luau",
	},
}
```

- Key = `tostring(game.GameId)` — **GameId, not PlaceId** (a GameId covers all places/universes of that experience).
- `moduleKey` = lowercase-dash identifier; must match what you seed in the API if you want payload routing later.
- `delivery` is optional and defaults to `"direct"`.

### Step 2b — Register in the dashboard (no loader update needed)

Because the loader also reads the live catalog from `/api/games`, you can add games **without shipping a new loader**:

1. Open **Dashboard → Games**.
2. Fill GameId, Name, Delivery = `direct`, Script URL → **Save game**.
3. Done. Loaders fetch the catalog once per session and will load the module next run.

Or via API:

```powershell
curl -X POST https://leet.voltsec.xyz/api/admin/games -H "Content-Type: application/json" -H "x-csrf-token: $env:LEET_CSRF" -b "leet_admin_session=..." -d '{
  "gameId": "987654321",
  "name": "Da Hood",
  "delivery": "direct",
  "scriptUrl": "https://raw.githubusercontent.com/VoltSec3/leetware/main/Games/DaHood/DaHood.luau"
}'
```

### Step 3 (optional) — Seed it for bookkeeping

```powershell
# leet-licensing/scripts/seed-games.ts
const games = [
  { gameId: "155615604", name: "Prison Life", moduleKey: "prison-life", delivery: "direct", scriptUrl: "..." },
  { gameId: "987654321", name: "Da Hood",     moduleKey: "da-hood",     delivery: "direct", scriptUrl: "..." },
];
```

```powershell
npm run seed:games
```

Purely optional — seeding only pre-fills names/modes; loaders self-register regardless.

---

## Path C — Gated payload (private/obfuscated source)

The module source lives **in your database** and is served by `/api/payload/<moduleKey>` only to requests carrying a valid session token + matching HWID. Nothing about the source is public.

### Step 1 — Set delivery mode to `api`

Dashboard → Games → register/edit the game with Delivery = `api`.

### Step 2 — Upload the source

Same page → **Payload** button on the game's row → paste Lua source (plain or obfuscated) → **Save payload**. The editor shows a `payload` badge on rows that have one; **Remove payload** clears it.

Max size: ~1 MB per module (validated server-side).

### Step 3 — Loader side

Nothing to do if the game came from the catalog. If you also put it in the built-in registry:

```lua
["987654321"] = {
    name = "Da Hood",
    moduleKey = "da-hood",
    delivery = "api",   -- fetch through the gated endpoint instead of scriptUrl
},
```

The dispatcher then calls `Auth.payload("da-hood", hwid)`, which sends:

```
GET /api/payload/da-hood
Authorization: Bearer <sessionToken>
X-HWID: <hwid>
```

Server checks: session valid → license `ACTIVATED` → HWID matches binding → returns `text/plain` source → compiled and run. Any failure returns 401/403/404 and the loader errors out visibly.

### Notes

- Keep `delivery: direct` while developing; switch to `api` when the module is ready for release.
- Obfuscate before pasting if you care about theft — the gate stops *unlicensed* access, not licensed users reading the response body.
- Rotating a payload = paste new source, save. Live on next execution, no deploy.

---

## Finding a game's GameId

In an executor console inside the target game:

```lua
print(game.GameId)
```

Use that number as the registry key / `gameId` field. (PlaceIds differ per sub-place; GameIds are stable across the whole experience.)

---

## Checklist for a polished release

- [ ] Module tested manually via `loadstring(game:HttpGet("<url>"))()` first
- [ ] Registered in dashboard with correct name (rename the auto entry if one exists)
- [ ] Correct delivery mode; payload uploaded if `api`
- [ ] Registry entry added (optional, but keeps loader working even if the API is down)
- [ ] Verified end-to-end: fresh executor session → correct status text ("Loading Da Hood...") → module features work → heartbeat updates last-seen in the dashboard
