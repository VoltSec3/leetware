import "dotenv/config";

function required(name) {
  const value = process.env[name];

  if (!value) {
    throw new Error(`missing required env var: ${name}`);
  }

  return value;
}

export const config = {
  botToken: required("DISCORD_BOT_TOKEN"),
  clientId: required("DISCORD_CLIENT_ID"),
  guildId: process.env.DISCORD_GUILD_ID ?? null,
  licensedRoleId: process.env.DISCORD_ROLE_ID ?? "1540272873351159888",
  roleIds: {
    standard: process.env.ROLE_STANDARD ?? "1540272873351159888",
    premium: process.env.ROLE_PREMIUM ?? "1540272887150411816",
    lifetime: process.env.ROLE_LIFETIME ?? "1541160182300803192",
    developer: process.env.ROLE_DEVELOPER ?? "1541160224579395715",
  },
  apiUrl: (process.env.INTERNAL_API_URL ?? "http://localhost:3000").replace(/\/$/, ""),
  apiKey: required("INTERNAL_API_KEY"),
};
