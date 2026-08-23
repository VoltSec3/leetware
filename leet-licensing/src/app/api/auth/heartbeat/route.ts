import { LicenseStatus } from "@prisma/client";

import { writeAuditLog } from "@/lib/audit";
import { env } from "@/lib/env";
import { errorResponse, getClientIp, jsonResponse } from "@/lib/http";
import { resolveSupportedGame } from "@/lib/game-service";
import {
  enforceRobloxAllowlist,
  findValidLoaderSession,
  markExpiredLicenses,
  resolveLicenseStatus,
  touchLoaderSession,
  verifyHwidForLicense,
} from "@/lib/license-service";
import { prisma } from "@/lib/prisma";
import { checkRateLimit } from "@/lib/rate-limit";
import { heartbeatSchema } from "@/lib/validation";

export async function POST(request: Request) {
  const ip = await getClientIp();

  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const parsed = heartbeatSchema.safeParse(body);

  if (!parsed.success) {
    return errorResponse(parsed.error.issues[0]?.message ?? "Invalid request", 400);
  }

  const { sessionToken, hwid } = parsed.data;

  const game = await resolveSupportedGame(parsed.data.gameId);

  const rateLimit = await checkRateLimit(
    `heartbeat:${sessionToken.slice(0, 16)}`,
    60,
    60 * 1000,
  );

  if (!rateLimit.allowed) {
    return errorResponse("Rate limit exceeded", 429);
  }

  await markExpiredLicenses();

  const session = await findValidLoaderSession(sessionToken);

  if (!session) {
    return errorResponse("Invalid or expired session", 401);
  }

  const status = await resolveLicenseStatus(session.license);

  if (status !== LicenseStatus.ACTIVATED) {
    await writeAuditLog({
      licenseId: session.licenseId,
      event: "heartbeat.inactive_license",
      ip,
      metadata: { status },
    });

    return jsonResponse({
      valid: false,
      licenseStatus: status,
    });
  }

  const hwidMatches = await verifyHwidForLicense(session.licenseId, hwid);

  if (!hwidMatches) {
    await writeAuditLog({
      licenseId: session.licenseId,
      event: "heartbeat.hwid_mismatch",
      ip,
    });

    return jsonResponse({
      valid: false,
      licenseStatus: status,
      reason: "hwid_mismatch",
    });
  }

  const allowlist = await enforceRobloxAllowlist(
    session.licenseId,
    session.robloxUserId,
  );

  if (!allowlist.allowed) {
    await writeAuditLog({
      licenseId: session.licenseId,
      event: "heartbeat.roblox_blocked",
      ip,
      metadata: { robloxUserId: session.robloxUserId, reason: allowlist.reason },
    });

    return jsonResponse({
      valid: false,
      licenseStatus: status,
      reason: "roblox_blocked",
      message: allowlist.reason ?? "Roblox account not allowed",
    });
  }

  await touchLoaderSession(session.id, ip);

  const extendedExpiresAt = new Date(
    Date.now() + env.loaderSessionTtlMinutes * 60 * 1000,
  );

  await prisma.loaderSession.update({
    where: { id: session.id },
    data: {
      expiresAt: extendedExpiresAt,
    },
  });

  return jsonResponse({
    valid: true,
    licenseStatus: status,
    expiresAt: extendedExpiresAt.toISOString(),
    sessionId: session.id,
    game,
  });
}
