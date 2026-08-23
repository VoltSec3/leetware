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

export async function createLoaderSession(
  licenseId: string,
  options?: {
    robloxUserId?: string | null;
    clientVersion?: string | null;
  },
) {
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
      robloxUserId: options?.robloxUserId ?? undefined,
      clientVersion: options?.clientVersion ?? undefined,
      expiresAt,
    },
  });

  return {
    session,
    token,
    expiresAt,
  };
}

export async function getLicenseUserWithAllowlist(licenseId: string) {
  const license = await prisma.license.findUnique({
    where: { id: licenseId },
    select: {
      userId: true,
      user: {
        include: {
          robloxAccounts: {
            orderBy: { addedAt: "desc" },
          },
        },
      },
    },
  });

  return license?.user ?? null;
}

export async function touchRobloxAccount(
  userId: string,
  robloxUserId: string | null,
) {
  if (!robloxUserId) {
    return;
  }

  const account = await prisma.robloxAccount.findUnique({
    where: { robloxUserId },
    select: { id: true, userId: true },
  });

  if (!account || account.userId !== userId) {
    return;
  }

  await prisma.robloxAccount.update({
    where: { id: account.id },
    data: {
      lastSeen: new Date(),
      verification: "VERIFIED",
    },
  });
}

export async function enforceUserAccountStatus(
  userId: string,
): Promise<{ allowed: boolean; reason?: string }> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { bannedAt: true, banReason: true, isSuspended: true, suspendedUntil: true },
  });

  if (!user) {
    return { allowed: true };
  }

  if (user.bannedAt) {
    return {
      allowed: false,
      reason: `You have been banned from the site for ${user.banReason ?? "no reason provided"}`,
    };
  }

  if (user.isSuspended) {
    if (!user.suspendedUntil || user.suspendedUntil.getTime() > Date.now()) {
      return {
        allowed: false,
        reason: user.suspendedUntil
          ? `Your account is suspended until ${user.suspendedUntil.toLocaleString()}`
          : "Your account is suspended indefinitely",
      };
    }
  }

  return { allowed: true };
}

export async function enforceRobloxAllowlist(
  licenseId: string,
  robloxUserId: string | null,
): Promise<{ allowed: boolean; reason?: string }> {
  const license = await prisma.license.findUnique({
    where: { id: licenseId },
    select: { userId: true },
  });

  if (!license?.userId) {
    return {
      allowed: false,
      reason:
        "License is not linked to a site account. Register on the website first.",
    };
  }

  const status = await enforceUserAccountStatus(license.userId);

  if (!status.allowed) {
    return status;
  }

  const user = await getLicenseUserWithAllowlist(licenseId);

  if (!user) {
    return {
      allowed: false,
      reason: "Site account not found for this license",
    };
  }

  if (user.robloxAccounts.length === 0) {
    return {
      allowed: false,
      reason:
        "No Roblox accounts are linked to your license yet. Add your Roblox account on the website dashboard before using the loader.",
    };
  }

  await touchRobloxAccount(user.id, robloxUserId);

  if (!robloxUserId) {
    return {
      allowed: false,
      reason: "This license is restricted to specific Roblox accounts",
    };
  }

  const allowed = user.robloxAccounts.some(
    (account) => account.robloxUserId === robloxUserId,
  );

  return allowed
    ? { allowed: true }
    : { allowed: false, reason: "Roblox account is not on this license's allowlist" };
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
  return prisma.loaderSession.updateMany({
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
