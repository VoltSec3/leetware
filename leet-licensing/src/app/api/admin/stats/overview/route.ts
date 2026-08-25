import { LicenseStatus } from "@prisma/client";

import { requireAdmin } from "@/lib/admin-auth";
import { errorResponse, jsonResponse } from "@/lib/http";
import { markExpiredLicenses } from "@/lib/license-service";
import { env } from "@/lib/env";
import { prisma } from "@/lib/prisma";

const DAY_MS = 24 * 60 * 60 * 1000;
const EXPIRING_SOON_MS = 7 * DAY_MS;

const CONFIG_URL =
  "https://raw.githubusercontent.com/VoltSec3/leetware/main/Loader/Core/Config.luau";

const BUILD_CACHE_TTL = 60 * 1000;

let cachedBuild: string | null = null;
let cachedBuildAt = 0;

// Reflects the live loader version from the canonical Config.luau on GitHub.
async function getCurrentBuild(): Promise<string> {
  const now = Date.now();

  if (cachedBuild && now - cachedBuildAt < BUILD_CACHE_TTL) {
    return cachedBuild;
  }

  try {
    const response = await fetch(CONFIG_URL, { cache: "no-store" });

    if (response.ok) {
      const text = await response.text();
      const match = text.match(/CLIENT_VERSION\s*=\s*"([^"]+)"/);

      if (match) {
        cachedBuild = match[1];
        cachedBuildAt = now;
        return cachedBuild;
      }
    }
  } catch {
    // fall through to cached/last-known value
  }

  return cachedBuild ?? env.currentBuild;
}

const AUTH_EVENTS = ["activate.success"];
const HWID_RESET_EVENTS = ["account.hwid_reset", "admin.hwid_reset"];
const PAYLOAD_ACCESS_EVENTS = ["payload.accessed"];

export async function GET() {
  try {
    await requireAdmin();
  } catch {
    return errorResponse("Unauthorized", 401);
  }

  await markExpiredLicenses();

  const now = new Date();
  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);

  const [
    totalLicenses,
    unused,
    activated,
    revoked,
    expired,
    activeSessions,
    totalUsers,
    expiringSoon,
    hwidResetsToday,
    authsToday,
    payloadsAccessedToday,
    sessionsToday,
  ] = await Promise.all([
    prisma.license.count(),
    prisma.license.count({ where: { status: LicenseStatus.UNUSED } }),
    prisma.license.count({ where: { status: LicenseStatus.ACTIVATED } }),
    prisma.license.count({ where: { status: LicenseStatus.REVOKED } }),
    prisma.license.count({ where: { status: LicenseStatus.EXPIRED } }),
    prisma.loaderSession.count({
      where: { revoked: false, expiresAt: { gt: now } },
    }),
    prisma.user.count(),
    prisma.license.count({
      where: {
        status: LicenseStatus.ACTIVATED,
        expiresAt: {
          gt: now,
          lt: new Date(now.getTime() + EXPIRING_SOON_MS),
        },
      },
    }),
    prisma.auditLog.count({
      where: { event: { in: HWID_RESET_EVENTS }, createdAt: { gte: startOfToday } },
    }),
    prisma.auditLog.count({
      where: { event: { in: AUTH_EVENTS }, createdAt: { gte: startOfToday } },
    }),
    prisma.auditLog.count({
      where: {
        event: { in: PAYLOAD_ACCESS_EVENTS },
        createdAt: { gte: startOfToday },
      },
    }),
    prisma.loaderSession.count({
      where: { createdAt: { gte: startOfToday } },
    }),
  ]);

  const currentBuild = await getCurrentBuild();

  return jsonResponse({
    overview: {
      totalLicenses,
      unusedLicenses: unused,
      activatedLicenses: activated,
      revokedLicenses: revoked,
      expiredLicenses: expired,
      activeSessions,
      totalUsers,
      expiringSoon,
      hwidResetsToday,
      authsToday,
      payloadsAccessedToday,
      sessionsToday,
      currentBuild,
    },
  });
}
