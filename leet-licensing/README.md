# leetware licensing (`leet.voltsec.xyz`)

Complete server-side licensing platform for the leetware Roblox loader: authentication API, admin dashboard, autonomous game catalog, and gated payload delivery.

- **API + dashboard**: Next.js 16 (App Router) on Vercel
- **Database**: PostgreSQL — [Neon](https://neon.tech) serverless recommended
- **ORM**: Prisma 7 with the Neon serverless adapter
- **Loader**: Roblox Luau client (`Loader/` at the repo root)

Every licensing decision is enforced **server-side**. The loader holds no secrets beyond a short-lived session token.

---

## Table of contents

1. [How it works](#how-it-works)
2. [Quick setup (local)](#quick-setup-local)
3. [Environment variables](#environment-variables)
4. [Vercel deployment](#vercel-deployment)
5. [Architecture](#architecture)
6. [Database schema](#database-schema)
7. [API reference](#api-reference)
8. [Admin dashboard](#admin-dashboard)
9. [Loader usage](#loader-usage)
10. [Adding new games](#adding-new-games)
11. [Security model](#security-model)
12. [Rate limits](#rate-limits)
13. [Troubleshooting](#troubleshooting)

---

## How it works

```
User runs loader → enters license once
        │
        ▼
POST /api/auth/activate ──► license bound to HWID, session token issued
        │
        ▼
Dispatcher detects game.GameId
        ├─ known game ──► loads its module (direct URL or gated /api/payload/<key>)
        └─ unknown ────► loads universal Boilerplate.luau
        │
        ▼
Heartbeat every 60s keeps the session alive; kill switch if revoked/expired
```

Key properties:

- **One license = one machine.** First activation binds the license to an HWID fingerprint; other devices are rejected.
- **Short-lived sessions.** Session tokens expire in 15 minutes by default and are extended by heartbeats. Tokens are stored hashed.
- **Autonomous game catalog.** The loader reports its `gameId` on every auth call; unknown games self-register in the database. No seeding required to support a new game.
- **Two delivery modes per game.** `direct` fetches the module from a public URL; `api` serves it from `/api/payload/<moduleKey>` only to authenticated sessions (optionally from source stored in the dashboard).

---

## Quick setup (local)

### 1. Prerequisites

- Node.js 20+
- A PostgreSQL database (Neon free tier works, local Postgres also fine)

### 2. Install and configure

```powershell
cd leet-licensing
copy .env.example .env
```

Edit `.env`:

1. Set `DATABASE_URL` to your Postgres connection string.
2. Generate four secrets (run four times, one per variable):

```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

3. Set `INITIAL_ADMIN_EMAIL` and `INITIAL_ADMIN_PASSWORD`.

See [Environment variables](#environment-variables) for what every variable does.

### 3. Bootstrap database + admin

```powershell
npm install
npm run setup
```

This runs:

| Script | What it does |
|--------|--------------|
| `prisma db push` | Creates all tables |
| `seed:games` | *(Optional)* registers Prison Life (`155615604`) |
| `setup:admin` | Creates the first admin user from `INITIAL_ADMIN_*` |

Seeding games is **optional** — games self-register when loaders use them (see [Adding new games](#adding-new-games)).

### 4. Start the dev server

```powershell
npm run dev
```

Open [http://localhost:3000/dashboard](http://localhost:3000/dashboard), sign in, and generate licenses.

### Useful commands

| Command | Purpose |
|---------|---------|
| `npm run dev` | Dev server with Turbopack |
| `npm run build` | Production build |
| `npm run lint` | ESLint |
| `npm run db:push` | Push schema changes to the database |
| `npm run db:studio` | Open Prisma Studio (DB GUI) |
| `npm run seed:games` | Seed the built-in game list |
| `npm run setup:admin` | Create/reset the initial admin |

---

## Environment variables

All variables live in `.env` (local) and Vercel project settings (production). `.env` is gitignored — never commit it.

### Required

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string. Neon example: `postgresql://user:pass@ep-x.eu-central-1.aws.neon.tech/neondb?sslmode=require`. Prisma 7 reads the URL from here, **not** from `schema.prisma`. |
| `LICENSE_HMAC_SECRET` | 32-byte hex. Key used to HMAC-hash license keys before storage. **Rotating it invalidates every existing license.** |
| `HWID_HMAC_SECRET` | 32-byte hex. Key used to HMAC-hash HWID fingerprints. Rotating it unbinds all activations. |
| `ADMIN_SESSION_SECRET` | 32-byte hex. Reserved for admin session cryptography helpers. |
| `CSRF_SECRET` | 32-byte hex. HMAC key that signs dashboard CSRF tokens. |

Generate each with:

```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `LOADER_SESSION_TTL_MINUTES` | `15` | Loader session lifetime. Extended on every heartbeat. |
| `ADMIN_SESSION_TTL_HOURS` | `24` | Dashboard login lifetime. |
| `APP_URL` | — | Canonical origin (`https://leet.voltsec.xyz`). Used for absolute URLs in responses/tooling. |
| `INITIAL_ADMIN_EMAIL` | — | Only used by `scripts/setup-admin.ts`. |
| `INITIAL_ADMIN_PASSWORD` | — | Only used by `scripts/setup-admin.ts`. Minimum 8 chars; use something long. |

### Secret rotation notes

- Rotating `LICENSE_HMAC_SECRET`: all licenses stop matching → re-issue licenses.
- Rotating `HWID_HMAC_SECRET`: all activations unbind → users must reactivate (licenses return to bound state only after HWID re-match fails; plan a maintenance window).
- Rotating `CSRF_SECRET` / admin sessions: dashboard users just log in again.

---

## Vercel deployment

1. Push this repository to GitHub.
2. In Vercel, create a project with **Root Directory** = `leet-licensing`.
3. Add every environment variable from the table above (Production + Preview).
4. Attach a Neon database (Vercel Marketplace integration sets `DATABASE_URL` for you), or paste your own connection string.
5. Deploy.
6. Add the domain: Vercel → Settings → Domains → `leet.voltsec.xyz`, then create the DNS record your registrar asks for (usually `CNAME` → `cname.vercel-dns.com`). Ensure `leet.voltsec.xyz` points at the apex of your DNS so the API base in `Loader/Core/Config.luau` resolves.
7. Bootstrap the production database once (locally, with the production `DATABASE_URL` in `.env`):

```powershell
npm run db:push
npm run seed:games   # optional
npm run setup:admin
```

8. Update `API_BASE` in `Loader/Core/Config.luau` if it is not already `https://leet.voltsec.xyz/api`.

### Deployment checklist

- [ ] All env vars set in Vercel (5 required + optional tuning)
- [ ] `db:push` ran against production DB
- [ ] Admin account created (`setup:admin`)
- [ ] Domain serving HTTPS (proxy enforces HTTPS redirects)
- [ ] Generated a test license and activated it from a real executor
- [ ] Heartbeat visible in Dashboard → Licenses → detail (last seen updates)

---

## Architecture

```
leet.voltsec.xyz (Vercel)
├── /dashboard          Admin UI (HttpOnly cookie sessions + CSRF)
├── /api/auth/*         Loader auth (public, rate-limited, auto-registers games)
├── /api/games          Public game catalog (drives loader dispatch)
├── /api/admin/*        Admin API (cookie session; CSRF on mutations)
└── /api/payload/*      Gated module delivery (Bearer session + X-HWID)
```

Code layout:

```
leet-licensing/
├── prisma/schema.prisma        Database models
├── prisma.config.ts            Prisma 7 config (loads DATABASE_URL)
├── scripts/
│   ├── setup.ps1               One-shot bootstrap (db push + seeds + admin)
│   ├── seed-games.ts           Optional game seed
│   └── setup-admin.ts          Initial admin creation
└── src/
    ├── proxy.ts                HTTPS enforcement (Next 16 middleware replacement)
    ├── lib/
    │   ├── env.ts              Env parsing/validation
    │   ├── prisma.ts           PrismaClient + Neon adapter singleton
    │   ├── crypto.ts           License/HWID hashing, token generation
    │   ├── http.ts             JSON/error responses, client IP
    │   ├── rate-limit.ts       DB-backed rate limiter
    │   ├── audit.ts            Audit log writer
    │   ├── validation.ts       Zod schemas for every endpoint
    │   ├── license-service.ts  License/session/HWID business logic
    │   ├── admin-auth.ts       Admin sessions, CSRF, cookies
    │   └── game-service.ts     Autonomous game registration + catalog
    ├── app/api/...             Route handlers
    ├── app/dashboard/...       Admin pages (server components)
    └── components/dashboard/   Client components (tables, forms)

Loader/                         Roblox client (repo root)
├── main.luau                   Entry point + flow
├── Core/
│   ├── Config.luau             API base, TTLs, feature flags
│   ├── HWID.luau               Stable hardware fingerprint
│   ├── Auth.luau               HTTP, activate/session/validate/heartbeat, payload fetch
│   ├── Dispatcher.luau         GameId → module resolution (registry + server catalog)
│   └── Heartbeat.luau          Background keep-alive loop
├── Games/registry.luau         Built-in GameId → module table
└── UI/Login.luau               Minimal license prompt GUI
```

---

## Database schema

| Model | Purpose |
|-------|---------|
| `AdminUser` | Dashboard accounts. bcrypt password hashes. |
| `AdminSession` | Dashboard sessions. Token stored as hash, expiry-tracked. |
| `License` | A license key. Stores **HMAC-SHA256 hash only**, status enum, optional expiry/note. |
| `Activation` | The single HWID binding per license + IPs, client version, last seen. |
| `LoaderSession` | Active loader sessions. Random 32-byte tokens stored as hashes, revocable. |
| `AuditLog` | Security-relevant events (activation, revocation, mismatches…) with IP. |
| `SupportedGame` | Game catalog: `gameId` (unique), `name`, `moduleKey` (unique), `delivery` (`direct`\|`api`), `scriptUrl`, `payloadSource` (gated Lua served by the API), `enabled`, `autoRegistered`, `lastSeenAt`. |
| `RateLimitEntry` | Fixed-window rate limit counters keyed by IP/token prefix. |

License statuses: `UNUSED` → `ACTIVATED` → `REVOKED` (manual) / `EXPIRED` (past `expiresAt`, applied lazily on access).

License keys are stored two ways: an **HMAC-SHA256 hash** (used for login lookups — the plaintext is never compared or logged) and an **AES-256-GCM encrypted copy** (`keyCipher`) so you can always retrieve the full key from the dashboard to share it. The encryption key is derived from `LICENSE_HMAC_SECRET`; rotating that secret makes existing stored keys unrecoverable *and* invalidates all licenses. Licenses created before this column existed show `—` instead of a key.

---

## API reference

All endpoints accept/return JSON unless noted. Errors use `{ "error": "message" }` with proper status codes.

### Loader endpoints (public)

#### `POST /api/auth/activate`

First activation, or re-session for an already-activated license on the same HWID.

```json
{
  "license": "XXXX-XXXX-XXXX-XXXX",
  "hwid": "fingerprint-string",
  "clientVersion": "1.0.0",
  "gameId": "155615604",
  "gameName": "Prison Life"
}
```

Response `200`:

```json
{
  "alreadyActivated": false,
  "sessionToken": "...",
  "expiresAt": "2026-08-21T12:34:56.000Z",
  "sessionId": "..."
}
```

Errors: `401` invalid license · `403` revoked / expired / HWID mismatch · `429` rate limited.

Side effects: binds HWID on first use, creates a session, **auto-registers `gameId` in the catalog**, writes audit logs.

#### `POST /api/auth/session`

Create or refresh a session. Two forms:

```json
{ "license": "XXXX-...", "hwid": "...", "clientVersion": "1.0.0", "gameId": "..." }
```

or refresh with an existing token:

```json
{ "sessionToken": "...", "hwid": "..." }
```

Response: `{ "sessionToken": "...", "expiresAt": "...", "sessionId": "..." }`

#### `POST /api/auth/validate`

```json
{ "sessionToken": "...", "hwid": "...", "gameId": "..." }
```

Response: `{ "valid": true, "licenseStatus": "ACTIVATED", "expiresAt": "...", "sessionId": "..." }`
or `{ "valid": false, "licenseStatus": "REVOKED" }` / `{ "valid": false, "reason": "hwid_mismatch" }`.

#### `POST /api/auth/heartbeat`

Same body as validate. Extends the session TTL and updates last-seen.

#### `GET /api/games`

Public catalog used by the loader to resolve GameId → module without a loader update:

```json
{
  "games": [
    {
      "gameId": "155615604",
      "name": "Prison Life",
      "moduleKey": "prison-life",
      "delivery": "direct",
      "scriptUrl": "https://raw.githubusercontent.com/.../PrisonLife.luau"
    }
  ],
  "fallback": {
    "moduleKey": "boilerplate",
    "delivery": "direct",
    "scriptUrl": "https://raw.githubusercontent.com/.../Boilerplate.luau"
  }
}
```

`scriptUrl` is `null` for `delivery: "api"` games (their code comes from the gated endpoint). `payloadSource` is never exposed here.

#### `GET /api/payload/{moduleKey}`

Gated module delivery. Headers:

```
Authorization: Bearer <sessionToken>
X-HWID: <hwid>
```

- `200` → `text/plain` Lua source (from `SupportedGame.payloadSource`)
- `401/403` → bad session / inactive license / HWID mismatch
- `404` → unknown moduleKey
- `200` JSON with `payload.available: false` → registered but no source uploaded yet

### Admin endpoints (cookie session)

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/api/admin/auth/login` | public | Login, sets session + CSRF cookies |
| POST | `/api/admin/auth/logout` | cookie | Invalidate session |
| GET | `/api/admin/auth/me` | cookie | Current admin |
| GET | `/api/admin/stats/overview` | cookie | Totals for overview cards |
| GET | `/api/admin/licenses?q=&status=&page=&limit=` | cookie | Paged license list (includes recoverable `key` per row) |
| POST | `/api/admin/licenses/generate` | cookie+CSRF | Generate 1–100 keys |
| GET | `/api/admin/licenses/:id` | cookie | Full detail incl. key, sessions + audit |
| POST | `/api/admin/licenses/:id/revoke` | cookie+CSRF | Revoke + kill sessions |
| POST | `/api/admin/licenses/:id/reenable` | cookie+CSRF | Un-revoke |
| GET | `/api/admin/games` | cookie | List catalog incl. flags |
| POST | `/api/admin/games` | cookie+CSRF | Register/upsert a game |
| PATCH | `/api/admin/games/:id` | cookie+CSRF | Update name/moduleKey/delivery/scriptUrl/payloadSource/enabled |
| DELETE | `/api/admin/games/:id` | cookie+CSRF | Remove a game |

Mutating requests require header `x-csrf-token: <value of leet_csrf cookie>`.

Example — register a game via API:

```powershell
curl -X POST https://leet.voltsec.xyz/api/admin/games `
  -H "Content-Type: application/json" `
  -H "x-csrf-token: $env:LEET_CSRF" `
  -b "leet_admin_session=..." `
  -d '{ "gameId": "123456789", "name": "Da Hood", "delivery": "direct", "scriptUrl": "https://raw.githubusercontent.com/.../DaHood.luau" }'
```

---

## Admin dashboard

| Page | What you can do |
|------|-----------------|
| `/dashboard` | Totals: licenses, activations, active sessions, recent events |
| `/dashboard/licenses` | Generate keys (shown once), search/filter, revoke, open details |
| `/dashboard/licenses/[id]` | Status, binding, IPs, sessions, per-license audit trail |
| `/dashboard/games` | Catalog management: register games, toggle delivery mode, enable/disable, upload/remove gated payload source, delete |

Games marked `auto` were self-registered by loaders. Rename them and set proper delivery modes whenever you like — loader-reported data never overwrites admin-set fields.

---

## Loader usage

Execute the GitHub-hosted `Loader/main.luau` through your executor's `loadstring(game:HttpGet(...))` chain. The loader and its dependencies fetch their modules from GitHub, so injecting the local folder structure is not required. Flow:

1. GUI prompts for a license (skipped when a saved session is still valid).
2. `Auth.authenticate` tries saved session → activate → session, sending `gameId`/`gameName` for auto-registration.
3. `Dispatcher.resolve` checks the built-in registry, then the live server catalog from `/api/games`.
4. Module source is fetched (direct URL or gated payload) and compiled with `loadstring`.
5. Unknown games get `Boilerplate.luau`.
6. Heartbeat loop validates every 60 s; on invalidation the user is told to reload.

Local testing: set `API_BASE = "http://localhost:3000/api"` in `Loader/Core/Config.luau`. Note most executors block plain-HTTP requests — prefer testing against the deployed HTTPS URL.

---

## Adding new games

Full guide: [`docs/ADDING_GAMES.md`](../docs/ADDING_GAMES.md) (repo root). Summary of the three paths:

| Path | When | Effort |
|------|------|--------|
| **A. Zero-touch** | Any new game | None — loader reports GameId, catalog self-registers, boilerplate runs until you add a module |
| **B. Direct module** | You have a public script URL | Add registry entry *and/or* register in dashboard with `delivery: direct` |
| **C. Gated payload** | You want the source private/obfuscated | Set `delivery: api` and paste source into Dashboard → Games |

---

## Security model

- **Hashed at rest**: license keys (HMAC, for lookups), HWIDs, loader session tokens, admin passwords (bcrypt).
- **Recoverable keys**: an AES-256-GCM encrypted copy of each license key is stored so admins can re-display/copy it later; the decryption key is derived from `LICENSE_HMAC_SECRET`.
- **Session tokens**: 32 random bytes, base64url; DB stores SHA-256-style HMAC hash; TTL 15 min sliding via heartbeat; revocable per license.
- **Admin sessions**: HttpOnly + SameSite=Strict cookies; double-submit CSRF with HMAC-signed tokens; mutations rejected without valid header.
- **Rate limiting** (DB-backed fixed window): see table below.
- **HTTPS enforced** in `src/proxy.ts` (Next 16 proxy convention).
- **No secrets in the loader**: it only ever holds its own short-lived session token.
- **Audit trail**: activation, revocation, HWID mismatch, expiry, session creation — all logged with IP.

### Rate limits

| Endpoint | Window | Max |
|----------|--------|-----|
| `/api/auth/activate` | 15 min / IP | 5 |
| `/api/auth/session` | 15 min / IP | 10 |
| `/api/auth/validate` | 60 s / token | 120 |
| `/api/auth/heartbeat` | 60 s / token | 60 |

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---------|--------------------|
| `P1001: Can't reach database` | Wrong `DATABASE_URL`, or Neon DB suspended — check connection string and `sslmode=require`. |
| `prisma db push` complains about `url` | Prisma 7 reads the URL from `prisma.config.ts`/env, not `schema.prisma`. Ensure `.env` exists. |
| Build error: client not generated | Run `npx prisma generate` (happens automatically on `npm install` via postinstall if configured). |
| Activation returns `403 already activated on another device` | Expected — HWID differs. Revoke + reissue, or verify the HWID fingerprint source in `HWID.luau`. |
| Loader says `Payload denied (HTTP 404)` | `delivery: api` but no `payloadSource` uploaded yet, or wrong `moduleKey`. Check Dashboard → Games. |
| New game loads boilerplate | No module registered yet — that is the designed fallback. Add a registry/dashboard entry. |
| Dashboard logout loops back | Cookies blocked or CSRF secret changed mid-session — clear site cookies and log in again. |
| `429 Too many activation attempts` | Rate limit hit — wait out the window or test from another IP during development. |

---

## Environment variables reference file

See [.env.example](./.env.example) for a copy-paste template with inline comments.
