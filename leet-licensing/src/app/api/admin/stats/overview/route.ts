import { LicenseStatus } from "@prisma/client";

import { requireAdmin } from "@/lib/admin-auth";
import { errorResponse, jsonResponse } from "@/lib/http";
import { markExpiredLicenses } from "@/lib/license-service";
import { prisma } from "@/lib/prisma";

export async function GET() {
  try {
    await requireAdmin();
  } catch {
    return errorResponse("Unauthorized", 401);
  }

  await markExpiredLicenses();

  const now = new Date();

  const [
    total,
    unused,
    activated,
    revoked,
    expired,
    activeSessions,
    recentActivations,
  ] = await Promise.all([
    prisma.license.count(),
    prisma.license.count({ where: { status: LicenseStatus.UNUSED } }),
    prisma.license.count({ where: { status: LicenseStatus.ACTIVATED } }),
    prisma.license.count({ where: { status: LicenseStatus.REVOKED } }),
    prisma.license.count({ where: { status: LicenseStatus.EXPIRED } }),
    prisma.loaderSession.count({
      where: {
        revoked: false,
        expiresAt: { gt: now },
      },
    }),
    prisma.activation.count({
      where: {
        lastSeen: {
          gte: new Date(Date.now() - 24 * 60 * 60 * 1000),
        },
      },
    }),
  ]);

  return jsonResponse({
    overview: {
      totalLicenses: total,
      unusedLicenses: unused,
      activatedLicenses: activated,
      revokedLicenses: revoked,
      expiredLicenses: expired,
      activeSessions,
      seenLast24h: recentActivations,
    },
  });
}
