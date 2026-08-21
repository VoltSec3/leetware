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
};
