import { LicenseStatus } from "@prisma/client";

import { writeAuditLog } from "@/lib/audit";
import { normalizeLicenseKey } from "@/lib/crypto";
import { errorResponse, getClientIp, jsonResponse } from "@/lib/http";
import { registerGameFromRequest } from "@/lib/game-service";
import {
  createLoaderSession,
  findLicenseByKey,
  findValidLoaderSession,
  markExpiredLicenses,
  resolveLicenseStatus,
  verifyHwidForLicense,
} from "@/lib/license-service";
import { prisma } from "@/lib/prisma";
import { checkRateLimit } from "@/lib/rate-limit";
import { sessionSchema } from "@/lib/validation";

export async function POST(request: Request) {
  const ip = await getClientIp();
  const rateLimit = await checkRateLimit(
    `session:${ip ?? "unknown"}`,
    10,
    15 * 60 * 1000,
  );

  if (!rateLimit.allowed) {
    return errorResponse("Too many session requests. Try again later.", 429);
  }

  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const parsed = sessionSchema.safeParse(body);

  if (!parsed.success) {
    return errorResponse(parsed.error.issues[0]?.message ?? "Invalid request", 400);
  }

  const { license, sessionToken, hwid, clientVersion } = parsed.data;

  await registerGameFromRequest(parsed.data);

  await markExpiredLicenses();

  if (sessionToken) {
    const existingSession = await findValidLoaderSession(sessionToken);

    if (!existingSession) {
      return errorResponse("Invalid or expired session", 401);
    }

    const status = await resolveLicenseStatus(existingSession.license);

    if (status !== LicenseStatus.ACTIVATED) {
      return errorResponse("License is not active", 403);
    }

    const hwidMatches = await verifyHwidForLicense(
      existingSession.licenseId,
      hwid,
    );

    if (!hwidMatches) {
      await writeAuditLog({
        licenseId: existingSession.licenseId,
        event: "session.hwid_mismatch",
        ip,
      });

      return errorResponse("HWID mismatch", 403);
    }

    const refreshed = await createLoaderSession(existingSession.licenseId);

    await prisma.activation.update({
      where: { licenseId: existingSession.licenseId },
      data: {
        lastSeen: new Date(),
        lastIp: ip ?? undefined,
        clientVersion: clientVersion ?? undefined,
      },
    });

    await writeAuditLog({
      licenseId: existingSession.licenseId,
      event: "session.refreshed",
      ip,
      metadata: { sessionId: refreshed.session.id },
    });

    return jsonResponse({
      sessionToken: refreshed.token,
      expiresAt: refreshed.expiresAt.toISOString(),
      sessionId: refreshed.session.id,
    });
  }

  if (!license) {
    return errorResponse("License is required", 400);
  }

  const normalizedLicense = normalizeLicenseKey(license);
  const existing = await findLicenseByKey(normalizedLicense);

  if (!existing) {
    return errorResponse("Invalid license", 401);
  }

  const status = await resolveLicenseStatus(existing);

  if (status !== LicenseStatus.ACTIVATED) {
    return errorResponse("License is not activated", 403);
  }

  const hwidMatches = await verifyHwidForLicense(existing.id, hwid);

  if (!hwidMatches) {
    await writeAuditLog({
      licenseId: existing.id,
      event: "session.hwid_mismatch",
      ip,
    });

    return errorResponse("HWID mismatch", 403);
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
    event: "session.created",
    ip,
    metadata: { sessionId: sessionResult.session.id },
  });

  return jsonResponse({
    sessionToken: sessionResult.token,
    expiresAt: sessionResult.expiresAt.toISOString(),
    sessionId: sessionResult.session.id,
  });
}
