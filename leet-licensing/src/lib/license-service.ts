import { LicenseStatus } from "@prisma/client";

import { hashHwid, hashLicense, hashToken, safeEqual } from "@/lib/crypto";
import { env } from "@/lib/env";
import { prisma } from "@/lib/prisma";

export function isLicenseExpired(expiresAt: Date | null | undefined): boolean {
  if (!expiresAt) {
    return false;
  }

  return expiresAt.getTime() <= Date.now();
}

export async function resolveLicenseStatus(license: {
  status: LicenseStatus;
  expiresAt: Date | null;
}) {
  if (
    license.status !== LicenseStatus.EXPIRED &&
    isLicenseExpired(license.expiresAt)
  ) {
    return LicenseStatus.EXPIRED;
  }

  return license.status;
}

export async function markExpiredLicenses(licenseId?: string) {
  const now = new Date();

  await prisma.license.updateMany({
    where: {
      ...(licenseId ? { id: licenseId } : {}),
      status: {
        in: [LicenseStatus.UNUSED, LicenseStatus.ACTIVATED],
      },
      expiresAt: {
        lte: now,
      },
    },
    data: {
      status: LicenseStatus.EXPIRED,
    },
  });
}

export async function findLicenseByKey(licenseKey: string) {
  const licenseHash = hashLicense(licenseKey);

  return prisma.license.findUnique({
    where: { licenseHash },
    include: {
      activation: true,
      sessions: {
        where: {
          revoked: false,
          expiresAt: { gt: new Date() },
        },
      },
    },
  });
}

export async function verifyHwidForLicense(
  licenseId: string,
  hwid: string,
): Promise<boolean> {
  const activation = await prisma.activation.findUnique({
    where: { licenseId },
  });

  if (!activation) {
    return false;
  }

  const hwidHash = hashHwid(hwid);
  return safeEqual(activation.hwidHash, hwidHash);
}

export async function createLoaderSession(licenseId: string) {
  const { generateSessionToken, hashToken: hashSessionToken } = await import(
    "@/lib/crypto"
  );

  const token = generateSessionToken();
  const tokenHash = hashSessionToken(token);
  const expiresAt = new Date(
    Date.now() + env.loaderSessionTtlMinutes * 60 * 1000,
  );

  const session = await prisma.loaderSession.create({
    data: {
      licenseId,
      tokenHash,
      expiresAt,
    },
  });

  return {
    session,
    token,
    expiresAt,
  };
}

export async function findValidLoaderSession(sessionToken: string) {
  const tokenHash = hashToken(sessionToken);

  return prisma.loaderSession.findFirst({
    where: {
      tokenHash,
      revoked: false,
      expiresAt: { gt: new Date() },
    },
    include: {
      license: {
        include: {
          activation: true,
        },
      },
    },
  });
}

export async function revokeLicenseSessions(licenseId: string) {
  await prisma.loaderSession.updateMany({
    where: {
      licenseId,
      revoked: false,
    },
    data: {
      revoked: true,
    },
  });
}

export async function touchActivation(
  licenseId: string,
  ip: string | null,
  clientVersion?: string,
) {
  await prisma.activation.update({
    where: { licenseId },
    data: {
      lastSeen: new Date(),
      lastIp: ip ?? undefined,
      clientVersion: clientVersion ?? undefined,
    },
  });
}

export async function touchLoaderSession(sessionId: string, ip: string | null) {
  await prisma.loaderSession.update({
    where: { id: sessionId },
    data: {
      lastSeen: new Date(),
    },
  });

  const session = await prisma.loaderSession.findUnique({
    where: { id: sessionId },
    select: { licenseId: true },
  });

  if (session) {
    await touchActivation(session.licenseId, ip);
  }
}
