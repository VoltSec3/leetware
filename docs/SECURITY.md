# Leetware — Runtime Guard & Leak Response

## Guards added (mechanisms)

- Runtime guard header injected into every delivered script (checks `_G.__leet_rt`).
- Server-side per-session, per-HWID token derivation: `deriveRuntimeTokenForSession(key, sessionToken, hwid)`.
- Loader-side per-session token derivation: `Guard.deriveRuntimeToken` bound to `_G.__leet_session_token` + `_G.__leet_hwid`.
- Payload delivery wrapping in `GET /api/payload/[gameKey]` (server wraps with the caller's session+HWID token).
- Loader re-wrap at load: `Guard.wrap(key, source)` for API modules, the game script, and the raw boilerplate fallback (idempotent: strips then re-adds).
- Shared secret `LOADER_RUNTIME_SECRET` (present only in server env + loader binary; never in delivered payloads).
- HWID global (`_G.__leet_hwid`) plumbed from `main.luau`.
- Session global (`_G.__leet_session_token`) plumbed from `Auth.saveSession` / `Auth.loadSession`.
- Auto-guard on admin save: `POST`/`PATCH /api/admin/games` wrap `payloadSource` via `ensureRuntimeGuard`.
- Seed wraps payloads on insert/update (`scripts/seed-games.ts`).
- Delivery is gated by a valid, HWID-bound, expiring loader session (Bearer + `X-HWID` + active license + Roblox allowlist).

## What a leaked delivered script can and cannot do

A delivered module/script embeds a token bound to `(moduleKey, session, HWID)`.
It is useless to anyone without that exact session+HWID and expires with the session.
Leaking one module reveals only that module's token — it cannot unlock other modules
or be replayed against a different session or machine.

The genuine access gate remains the server-issued session: without a valid licensed
session you cannot fetch any payload, token or not.

## Leak response runbook

### `LOADER_RUNTIME_SECRET` leaks
1. Rotate it in `.env` (`LOADER_RUNTIME_SECRET=...`) AND in the loader source
   `Loader/Core/Guard.luau` (`RUNTIME_SECRET = "..."`). The two MUST match.
2. Re-deploy the loader and restart the server.
3. Invalidate all loader sessions so no existing session can derive new runtime
   tokens: `prisma loaderSession.deleteMany({})` (or scope by `licenseId`).

### A single module / script leaks
- By design harmless: it only contains that module's per-session token, bound to a
  specific session+HWID and short-lived. Cannot unlock other modules or replay.
- Optional: rotate `LOADER_RUNTIME_SECRET` and revoke the involved license/session.

### A loader session token leaks
- Invalidate it: delete the loader session row
  (`prisma loaderSession.deleteMany({ where: { tokenHash } })`) or mass-invalidate
  for a license (`where: { licenseId }`).
- Rotate `LOADER_RUNTIME_SECRET` so any derived runtime tokens are invalidated.
- Payloads still require the session, so also revoke/reset the underlying license.

### Full loader source leaks
- The secret can be extracted from the loader, but payloads still require a valid
  licensed session (server-gated). Mitigate by:
  - invalidating all sessions,
  - rotating `LOADER_RUNTIME_SECRET`,
  - revoking compromised licenses,
  - enforcing/raising `CLIENT_VERSION` gates if you version-lock the loader.
- Add loader-binary anti-tamper / obfuscation (build-time concern, out of scope here).

### Database leaks
- Stored payloads are inert without a session. Rotate `LOADER_RUNTIME_SECRET`,
  force license/password resets, and invalidate all loader sessions.

## Operational notes
- Keep `LOADER_RUNTIME_SECRET` in env / secret manager, not committed. The value
  embedded in `Loader/Core/Guard.luau` is a deployed artifact; if you build the
  loader separately, inject it at build time rather than committing it.
- Monitor `/api/payload` access via the `payload.accessed` audit log for anomalies.
- Session TTL is controlled by `LOADER_SESSION_TTL_MINUTES` (default 15).
