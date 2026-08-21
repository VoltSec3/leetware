import { LicenseStatus, Prisma } from "@prisma/client";

import { writeAuditLog } from "@/lib/audit";
import { hashHwid, normalizeLicenseKey } from "@/lib/crypto";
import { errorResponse, getClientIp, jsonResponse } from "@/lib/http";
import { registerGameFromRequest } from "@/lib/game-service";
import {
  createLoaderSession,
  findLicenseByKey,
  markExpiredLicenses,
  resolveLicenseStatus,
  verifyHwidForLicense,
} from "@/lib/license-service";
import { prisma } from "@/lib/prisma";
import { checkRateLimit } from "@/lib/rate-limit";
import { activateSchema } from "@/lib/validation";

export async function POST(request: Request) {
  const ip = await getClientIp();
  const rateLimit = await checkRateLimit(
    `activate:${ip ?? "unknown"}`,
    5,
    15 * 60 * 1000,
  );

  if (!rateLimit.allowed) {
    return errorResponse("Too many activation attempts. Try again later.", 429);
  }

  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const parsed = activateSchema.safeParse(body);

  if (!parsed.success) {
    return errorResponse(parsed.error.issues[0]?.message ?? "Invalid request", 400);
  }

  const { license, hwid, clientVersion, metadata } = parsed.data;
  const normalizedLicense = normalizeLicenseKey(license);

  await registerGameFromRequest(parsed.data);

  await markExpiredLicenses();

  const existing = await findLicenseByKey(normalizedLicense);

  if (!existing) {
    await writeAuditLog({
      event: "activate.not_found",
      ip,
      metadata: { licensePrefix: normalizedLicense.slice(0, 4) },
    });

    return errorResponse("Invalid license", 401);
  }

  const status = await resolveLicenseStatus(existing);

  if (status === LicenseStatus.REVOKED) {
    await writeAuditLog({
      licenseId: existing.id,
      event: "activate.revoked",
      ip,
    });

    return errorResponse("License revoked", 403);
  }

  if (status === LicenseStatus.EXPIRED) {
    await writeAuditLog({
      licenseId: existing.id,
      event: "activate.expired",
      ip,
    });

    return errorResponse("License expired", 403);
  }

  if (status === LicenseStatus.ACTIVATED) {
    const hwidMatches = await verifyHwidForLicense(existing.id, hwid);

    if (!hwidMatches) {
      await writeAuditLog({
        licenseId: existing.id,
        event: "activate.hwid_mismatch",
        ip,
      });

      return errorResponse("License already activated on another device", 403);
    }

    const sessionResult = await createLoaderSession(existing.id);

    await prisma.activation.update({
      where: { licenseId: existing.id },
      data: {
        lastSeen: new Date(),
        lastIp: ip ?? undefined,
        clientVersion: clientVersion ?? undefined,
      },
    });

    await writeAuditLog({
      licenseId: existing.id,
      event: "session.created_from_activate",
      ip,
      metadata: { sessionId: sessionResult.session.id },
    });

    return jsonResponse({
      alreadyActivated: true,
      sessionToken: sessionResult.token,
      expiresAt: sessionResult.expiresAt.toISOString(),
      sessionId: sessionResult.session.id,
    });
  }

  const hwidHash = hashHwid(hwid);

  await prisma.$transaction(async (tx) => {
    await tx.license.update({
      where: { id: existing.id },
      data: {
        status: LicenseStatus.ACTIVATED,
        activatedAt: new Date(),
      },
    });

    await tx.activation.create({
      data: {
        licenseId: existing.id,
        hwidHash,
        firstIp: ip ?? undefined,
        lastIp: ip ?? undefined,
        clientVersion: clientVersion ?? undefined,
        metadata: metadata
          ? (metadata as Prisma.InputJsonValue)
          : undefined,
      },
    });
  });

  const sessionResult = await createLoaderSession(existing.id);

  await writeAuditLog({
    licenseId: existing.id,
    event: "activate.success",
    ip,
    metadata: {
      sessionId: sessionResult.session.id,
      clientVersion,
    },
  });

  return jsonResponse({
    alreadyActivated: false,
    sessionToken: sessionResult.token,
    expiresAt: sessionResult.expiresAt.toISOString(),
    sessionId: sessionResult.session.id,
  });
}
