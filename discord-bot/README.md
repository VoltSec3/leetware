# leetware discord bot

Modular discord bot for the leetware licensing platform. Keeps the
"Licensed" role in sync with site account status and offers a manual
`/updaterole` command as a fallback (discord sometimes silently drops the
role add right after an OAuth guild join).

## Setup

```bash
cd discord-bot
npm install
cp .env.example .env   # fill in values, then:
npm run deploy         # registers the /updaterole slash command
npm start
```

### Env vars

| Name | Required | Description |
| --- | --- | --- |
| `DISCORD_BOT_TOKEN` | yes | bot token (same bot the web app uses for guild joins) |
| `DISCORD_CLIENT_ID` | yes | application/client id |
| `DISCORD_GUILD_ID` | no | deploy commands to one guild (faster) instead of globally |
| `DISCORD_ROLE_ID` | no | licensed role id (default `1540272873351159888`) |
| `INTERNAL_API_URL` | no | base url of the licensing app (default `http://localhost:3000`) |
| `INTERNAL_API_KEY` | yes | must match `INTERNAL_API_KEY` in the web app env |

The web app must expose `INTERNAL_API_KEY`; the bot authenticates to
`GET /api/internal/discord-role?discordId=...` with it.

## Role policy

A member **should** have the Licensed role when they have a linked site
account that is not banned, not suspended, and holds a license. Everyone
else gets it removed by `/updaterole`.

## Commands

- `/updaterole` - checks the backend and adds/removes the role accordingly.
  Replies are ephemeral and include ban/suspend reasons where relevant.

## Structure

```
index.js            entry point: client, auto-sync listeners, dispatch
deploy-commands.js  registers slash commands
lib/config.js       env loading + validation
lib/api.js          internal API client
lib/roles.js        role add/remove helpers
commands/           one file per slash command (data + execute)
```
