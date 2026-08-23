function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const env = {
  get databaseUrl() {
    return requireEnv("DATABASE_URL");
  },
  get licenseHmacSecret() {
    return requireEnv("LICENSE_HMAC_SECRET");
  },
  get hwidHmacSecret() {
    return requireEnv("HWID_HMAC_SECRET");
  },
  get adminSessionSecret() {
    return requireEnv("ADMIN_SESSION_SECRET");
  },
  get csrfSecret() {
    return requireEnv("CSRF_SECRET");
  },
  get loaderSessionTtlMinutes() {
    return Number(process.env.LOADER_SESSION_TTL_MINUTES ?? "15");
  },
  get adminSessionTtlHours() {
    return Number(process.env.ADMIN_SESSION_TTL_HOURS ?? "24");
  },
  get appUrl() {
    return process.env.APP_URL ?? "https://leet.voltsec.xyz";
  },
  get discordClientId() {
    return process.env.DISCORD_CLIENT_ID ?? "";
  },
  get discordClientSecret() {
    return process.env.DISCORD_CLIENT_SECRET ?? "";
  },
  get discordBotToken() {
    return process.env.DISCORD_BOT_TOKEN ?? "";
  },
  get discordGuildId() {
    return process.env.DISCORD_GUILD_ID ?? "";
  },
  get discordRoleId() {
    return process.env.DISCORD_ROLE_ID ?? "1540272873351159888";
  },
  get internalApiKey() {
    return process.env.INTERNAL_API_KEY ?? "";
  },
  get currentBuild() {
    return process.env.CURRENT_BUILD ?? "v3.4.2";
  },
};
