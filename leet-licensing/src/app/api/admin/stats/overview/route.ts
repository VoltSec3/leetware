import { LicenseStatus } from "@prisma/client";

import { requireAdmin } from "@/lib/admin-auth";
import { errorResponse, jsonResponse } from "@/lib/http";
import { markExpiredLicenses } from "@/lib/license-service";
import { env } from "@/lib/env";
import { prisma } from "@/lib/prisma";

const DAY_MS = 24 * 60 * 60 * 1000;
const EXPIRING_SOON_MS = 7 * DAY_MS;

const AUTH_EVENTS = ["activate.success"];
const FAILED_AUTH_EVENTS = [
  "activate.not_found",
  "activate.revoked",
  "activate.suspended",
  "activate.expired",
  "activate.hwid_mismatch",
  "session.hwid_mismatch",
  "session.roblox_blocked",
  "session.unlinked",
];
const HWID_RESET_EVENTS = ["account.hwid_reset", "admin.hwid_reset"];

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
    failedAuthsToday,
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
        event: { in: FAILED_AUTH_EVENTS },
        createdAt: { gte: startOfToday },
      },
    }),
  ]);

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
      failedAuthsToday,
      currentBuild: env.currentBuild,
      oldestSupportedBuild: env.oldestSupportedBuild,
    },
  });
}
